import type { Approval, ApprovalDecision, ApprovalSource } from '@switchboard/shared'

export type ApprovalRequest = Omit<Approval, 'createdAt' | 'expiresAt'>


export type ApprovalEvents = {
  onRequested: (approval: Approval) => void
  onResolved: (approval: Approval, decision: ApprovalDecision, by: ApprovalSource) => void
}

type Pending = {
  approval: Approval
  promise: Promise<ApprovalDecision>
  resolve: (decision: ApprovalDecision) => void
  timer: NodeJS.Timeout
}

const rememberedDecisions = 500

export class ApprovalBroker {
  private readonly pending = new Map<string, Pending>()
  private readonly decided = new Map<string, ApprovalDecision>()

  constructor(
    private readonly events: ApprovalEvents,
    private readonly timeoutMs: number,
  ) {}

  list(): Approval[] {
    return [...this.pending.values()].map((entry) => entry.approval)
  }

  hasPending(agentId: string): boolean {
    return this.list().some((approval) => approval.agentId === agentId)
  }

  request(request: ApprovalRequest, signal: AbortSignal): Promise<ApprovalDecision> {
    const earlier = this.decided.get(request.id)
    if (earlier) return Promise.resolve(earlier)
    const existing = this.pending.get(request.id)
    if (existing) return existing.promise
    if (signal.aborted) return Promise.resolve('deny')

    const createdAt = Date.now()
    const approval: Approval = { ...request, createdAt, expiresAt: createdAt + this.timeoutMs }
    const { promise, resolve } = Promise.withResolvers<ApprovalDecision>()
    const timer = setTimeout(() => this.settle(request.id, 'deny', 'timeout'), this.timeoutMs)
    this.pending.set(request.id, { approval, promise, resolve, timer })
    signal.addEventListener('abort', () => this.settle(request.id, 'deny', 'stop'), { once: true })
    this.events.onRequested(approval)
    return promise
  }

  respond(id: string, decision: ApprovalDecision): void {
    if (!this.pending.has(id)) throw new Error('This approval was already answered.')
    this.settle(id, decision, 'user')
  }

  denyAgent(agentId: string): void {
    for (const approval of this.list()) {
      if (approval.agentId === agentId) this.settle(approval.id, 'deny', 'stop')
    }
  }

  private settle(id: string, decision: ApprovalDecision, by: ApprovalSource): void {
    const entry = this.pending.get(id)
    if (!entry) return
    clearTimeout(entry.timer)
    this.pending.delete(id)
    this.decided.set(id, decision)
    const oldest = this.decided.keys().next()
    if (this.decided.size > rememberedDecisions && !oldest.done) this.decided.delete(oldest.value)
    this.events.onResolved(entry.approval, decision, by)
    entry.resolve(decision)
  }
}
