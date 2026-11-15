import { randomUUID } from 'node:crypto'
import { getSessionInfo, type Options, type SDKMessage } from '@anthropic-ai/claude-agent-sdk'
import { isBusy, type Agent, type Approval, type ApprovalDecision, type ApprovalScope, type ApprovalSource, type Bootstrap, type CreateAgentInput, type History, type Project, type Role } from '@switchboard/shared'
import type { Config } from '../config.ts'
import type { AgentRepo } from '../repo/agents.ts'
import type { MessageRepo } from '../repo/messages.ts'
import type { Hub } from '../ws/hub.ts'
import { ApprovalBroker } from './approvals.ts'
import { LiveState } from './live.ts'
import { buildOptions, type ToolCall, type Verdict } from './options.ts'
import { isProjectEdit, needsApproval } from './policy.ts'
import { Recorder } from './recorder.ts'
import { AgentRunner } from './runner.ts'
import { summarizeTool } from './summary.ts'
import { Translator, type TurnEvent } from './translate.ts'

export type ManagerDeps = {
  agents: AgentRepo
  messages: MessageRepo
  hub: Hub
  config: Config
}

export class NotFoundError extends Error {}

const denialReasons: Record<ApprovalSource, string> = {
  user: 'The user denied this action in Switchboard.',
  timeout: 'Nobody answered the approval request in time, so it was denied.',
  stop: 'The user stopped the agent before approving this action.',
}

export class AgentManager {
  private readonly runners = new Map<string, AgentRunner>()
  private readonly translators = new Map<string, Translator>()
  private readonly stopping = new Set<string>()
  private readonly live = new Set<string>()
  private readonly denied = new Map<string, ApprovalSource>()
  private readonly state = new LiveState()
  private readonly recorder: Recorder
  private readonly approvals: ApprovalBroker

  constructor(private readonly deps: ManagerDeps) {
    this.recorder = new Recorder({ ...deps, live: this.state })
    this.approvals = new ApprovalBroker(
      {
        onRequested: (approval) => this.onApprovalRequested(approval),
        onResolved: (approval, decision, by) => this.onApprovalResolved(approval, decision, by),
      },
      deps.config.approvalTimeoutMs,
    )
    deps.agents.resetStatus('working', 'idle')
    deps.agents.resetStatus('waiting', 'idle')
    deps.messages.failRunningTools()
  }

  bootstrap(): Bootstrap {
    const { projects, roles, tailscaleAddress, port } = this.deps.config
    const host = { tailscaleUrl: tailscaleAddress ? `http://${tailscaleAddress}:${port}` : null }
    return { projects, roles, agents: this.recorder.list(), approvals: this.approvals.list(), host }
  }

  history(agentId: string): History {
    this.require(agentId)
    return { items: this.deps.messages.list(agentId), drafts: this.translators.get(agentId)?.drafts() ?? [] }
  }

  create(input: CreateAgentInput): Agent {
    const project = this.project(input.projectId)
    if (!project.agents.includes(input.role)) throw new Error(`Role ${input.role} is not available in ${project.name}`)
    const id = randomUUID()
    this.deps.agents.insert({ id, name: input.name, projectId: project.id, role: input.role, sessionId: null, status: 'idle', createdAt: Date.now() })
    this.recorder.publish(id)
    return this.view(id)
  }

  rename(agentId: string, name: string): Agent {
    this.require(agentId)
    this.deps.agents.update(agentId, { name })
    this.recorder.publish(agentId)
    return this.view(agentId)
  }

  remove(agentId: string): void {
    this.require(agentId)
    this.approvals.denyAgent(agentId)
    this.runners.get(agentId)?.close()
    this.runners.delete(agentId)
    this.translators.delete(agentId)
    this.stopping.delete(agentId)
    this.live.delete(agentId)
    this.state.forget(agentId)
    this.deps.agents.remove(agentId)
    this.deps.hub.broadcast({ type: 'agent.removed', agentId })
  }

  send(agentId: string, text: string): void {
    const agent = this.require(agentId)
    this.project(agent.projectId)
    this.role(agent.role)
    if (!isBusy(agent.status)) return this.dispatch(agentId, text)
    this.state.enqueue(agentId, text)
    this.recorder.publish(agentId)
  }

  unqueue(agentId: string, id: string): void {
    this.require(agentId)
    this.state.unqueue(agentId, id)
    this.recorder.publish(agentId)
  }

  async stop(agentId: string): Promise<void> {
    if (!isBusy(this.require(agentId).status)) return
    this.approvals.denyAgent(agentId)
    this.dropQueue(agentId)
    const runner = this.runners.get(agentId)
    if (!runner?.active) return this.settle(agentId, 'idle')
    this.stopping.add(agentId)
    try {
      await runner.interrupt()
    } catch (cause) {
      this.stopping.delete(agentId)
      throw cause
    }
  }

  respond(approvalId: string, decision: ApprovalDecision, scope: ApprovalScope): void {
    const approval = this.approvals.list().find((candidate) => candidate.id === approvalId)
    if (approval?.turnTrust && decision === 'allow' && scope === 'turn') this.state.trust(approval.agentId, approval.toolName)
    this.approvals.respond(approvalId, decision)
  }

  shutdown(): void {
    for (const runner of this.runners.values()) runner.close()
  }

  private require(agentId: string): Agent {
    return this.view(agentId)
  }

  private view(agentId: string): Agent {
    const agent = this.recorder.view(agentId)
    if (!agent) throw new NotFoundError('Agent not found')
    return agent
  }

  private dispatch(agentId: string, text: string): void {
    this.deps.agents.update(agentId, { status: 'working' })
    this.state.setActivity(agentId, 'Starting')
    this.recorder.save(agentId, 'user', { kind: 'text', text })
    this.runner(agentId).send(text)
  }

  private settle(agentId: string, status: 'idle' | 'error'): void {
    this.state.endTurn(agentId)
    this.recorder.setStatus(agentId, status)
  }

  private dropQueue(agentId: string): void {
    const dropped = this.state.clearQueue(agentId)
    if (dropped > 0) this.recorder.notice(agentId, dropped === 1 ? 'One queued message was dropped' : `${dropped} queued messages were dropped`)
  }

  private project(id: string): Project {
    const project = this.deps.config.projects.find((candidate) => candidate.id === id)
    if (!project) throw new Error(`Project ${id} is missing from projects.json`)
    return project
  }

  private role(id: string): Role {
    const role = this.deps.config.roles.find((candidate) => candidate.id === id)
    if (!role) throw new Error(`Role ${id} is missing from roles.json`)
    return role
  }

  private runner(agentId: string): AgentRunner {
    const existing = this.runners.get(agentId)
    if (existing) return existing
    const runner = new AgentRunner(() => this.options(agentId), {
      onMessage: (message) => this.onMessage(agentId, message),
      onExit: (error) => this.onExit(agentId, error),
    })
    this.runners.set(agentId, runner)
    return runner
  }

  private options(agentId: string): Options {
    const agent = this.require(agentId)
    return buildOptions({
      agent,
      project: this.project(agent.projectId),
      role: this.role(agent.role),
      settingSources: this.deps.config.settingSources,
      protectedPaths: this.deps.config.protectedPaths,
      authorize: (call) => this.authorize(agentId, call),
      onStderr: (data) => process.stderr.write(`[${agent.name}] ${data}`),
    })
  }

  private translator(agentId: string): Translator {
    const existing = this.translators.get(agentId)
    if (existing) return existing
    const translator = new Translator()
    this.translators.set(agentId, translator)
    return translator
  }

  private async authorize(agentId: string, call: ToolCall): Promise<Verdict> {
    const project = this.project(this.require(agentId).projectId)
    const roots = [project.path, ...project.additionalDirectories]
    const { secretPaths, trustExcluded } = this.deps.config
    if (!call.prompted && !needsApproval(call.toolName, call.input, roots, secretPaths)) return { decision: 'allow', asked: false, reason: '' }
    const turnTrust = !call.prompted && isProjectEdit(call.toolName, call.input, roots, trustExcluded)
    if (turnTrust && this.state.trusts(agentId, call.toolName)) {
      return { decision: 'allow', asked: true, reason: 'The user allowed edits inside the project for this turn.' }
    }
    const request = { id: call.toolUseId, agentId, toolName: call.toolName, summary: summarizeTool(call.input, roots), input: call.input, turnTrust }
    const decision = await this.approvals.request(request, call.signal)
    return { decision, asked: true, reason: decision === 'allow' ? 'Approved by the user in Switchboard.' : denialReasons[this.denied.get(call.toolUseId) ?? 'user'] }
  }

  private onApprovalRequested(approval: Approval): void {
    this.deps.hub.broadcast({ type: 'approval.requested', approval })
    this.state.setActivity(approval.agentId, 'Waiting for your approval')
    this.recorder.setStatus(approval.agentId, 'waiting')
  }

  private onApprovalResolved(approval: Approval, decision: ApprovalDecision, by: ApprovalSource): void {
    this.deps.hub.broadcast({ type: 'approval.resolved', approvalId: approval.id, agentId: approval.agentId, decision, by })
    if (decision === 'deny') {
      this.denied.set(approval.id, by)
      this.recorder.toolDenied(approval.id)
    }
    const waiting = this.deps.agents.get(approval.agentId)?.status === 'waiting'
    if (!waiting || this.approvals.hasPending(approval.agentId)) return
    this.state.setActivity(approval.agentId, 'Thinking')
    this.recorder.setStatus(approval.agentId, 'working')
  }

  private onMessage(agentId: string, message: SDKMessage): void {
    if (!this.deps.agents.get(agentId)) return
    for (const event of this.translator(agentId).handle(message)) this.apply(agentId, event)
  }

  private onExit(agentId: string, error: Error | null): void {
    if (!this.deps.agents.get(agentId)) return
    for (const event of this.translator(agentId).reset()) this.apply(agentId, event)
    this.approvals.denyAgent(agentId)
    this.recorder.failRunningTools(agentId)
    const started = this.live.delete(agentId)
    this.stopping.delete(agentId)
    if (error) this.fail(agentId, error.message, started)
  }

  private fail(agentId: string, detail: string, started: boolean): void {
    const sessionId = this.deps.agents.get(agentId)?.sessionId
    if (started || !sessionId) {
      this.recorder.error(agentId, detail)
      this.dropQueue(agentId)
      this.settle(agentId, 'error')
      return
    }
    this.runners.get(agentId)?.close()
    void this.transcriptGone(sessionId).then((gone) => {
      if (!this.deps.agents.get(agentId)) return
      this.dropQueue(agentId)
      if (gone) this.deps.agents.update(agentId, { sessionId: null })
      this.recorder.error(agentId, gone ? `The earlier session could not be resumed, so the next message starts a new one. ${detail}` : detail)
      this.settle(agentId, 'error')
    })
  }

  private async transcriptGone(sessionId: string): Promise<boolean> {
    try {
      return (await getSessionInfo(sessionId)) === undefined
    } catch {
      return false
    }
  }

  private apply(agentId: string, event: TurnEvent): void {
    switch (event.type) {
      case 'session':
        this.live.add(agentId)
        if (this.deps.agents.get(agentId)?.sessionId === event.sessionId) return
        this.deps.agents.update(agentId, { sessionId: event.sessionId })
        this.recorder.publish(agentId)
        return
      case 'turn.start': {
        const status = this.deps.agents.get(agentId)?.status
        this.state.setActivity(agentId, 'Thinking')
        if (status === 'idle' || status === 'error') this.recorder.setStatus(agentId, 'working')
        else this.recorder.publish(agentId)
        return
      }
      case 'delta':
        this.recorder.setActivity(agentId, 'Writing')
        this.deps.hub.broadcast({ type: 'chat.delta', agentId, itemId: event.itemId, text: event.text })
        return
      case 'text':
        this.recorder.save(agentId, 'assistant', { kind: 'text', text: event.text }, event.itemId)
        return
      case 'tool.start':
        this.recorder.toolStarted(agentId, this.project(this.require(agentId).projectId), event.toolUseId, event.name, event.input, this.denied.has(event.toolUseId))
        return
      case 'tool.end':
        this.recorder.toolFinished(event.toolUseId, event.isError, event.result, this.denied.delete(event.toolUseId))
        return
      case 'error':
        this.recorder.error(agentId, event.text)
        return
      case 'turn.end':
        this.endTurn(agentId, event)
        return
    }
  }

  private endTurn(agentId: string, event: Extract<TurnEvent, { type: 'turn.end' }>): void {
    if (this.stopping.delete(agentId)) {
      this.recorder.notice(agentId, 'Stopped')
      return this.advance(agentId)
    }
    if (event.more) return
    if (!event.ok) return this.fail(agentId, event.error ?? 'The turn failed.', this.live.has(agentId))
    this.advance(agentId)
  }

  private advance(agentId: string): void {
    const next = this.state.dequeue(agentId)
    this.state.endTurn(agentId)
    if (next) this.dispatch(agentId, next.text)
    else this.recorder.setStatus(agentId, 'idle')
  }
}
