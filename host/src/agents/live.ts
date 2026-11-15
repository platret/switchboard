import { randomUUID } from 'node:crypto'
import type { Agent, QueuedMessage, StoredAgent } from '@switchboard/shared'

function plain(markdown: string): string {
  return markdown
    .replace(/[*_`#>]+/g, '')
    .replace(/\s+/g, ' ')
    .trim()
}

const queuePreviewLength = 200
const maxQueued = 20

export class LiveState {
  private readonly activities = new Map<string, string>()
  private readonly queues = new Map<string, QueuedMessage[]>()
  private readonly trusted = new Map<string, Set<string>>()

  view(agent: StoredAgent): Agent {
    return {
      ...agent,
      preview: agent.preview === null ? null : plain(agent.preview),
      activity: this.activities.get(agent.id) ?? null,
      queue: (this.queues.get(agent.id) ?? []).map(({ id, text }) => ({ id, text: text.slice(0, queuePreviewLength) })),
      trustedTools: [...(this.trusted.get(agent.id) ?? [])],
    }
  }

  setActivity(agentId: string, activity: string | null): boolean {
    if ((this.activities.get(agentId) ?? null) === activity) return false
    if (activity === null) this.activities.delete(agentId)
    else this.activities.set(agentId, activity)
    return true
  }

  enqueue(agentId: string, text: string): void {
    const queue = this.queues.get(agentId) ?? []
    if (queue.length >= maxQueued) throw new Error(`The queue is full. Wait for the agent to catch up or remove a queued message.`)
    this.queues.set(agentId, [...queue, { id: randomUUID(), text }])
  }

  dequeue(agentId: string): QueuedMessage | undefined {
    const [next, ...rest] = this.queues.get(agentId) ?? []
    if (next) this.queues.set(agentId, rest)
    return next
  }

  unqueue(agentId: string, id: string): void {
    this.queues.set(agentId, (this.queues.get(agentId) ?? []).filter((entry) => entry.id !== id))
  }

  clearQueue(agentId: string): number {
    const dropped = this.queues.get(agentId)?.length ?? 0
    this.queues.delete(agentId)
    return dropped
  }

  trust(agentId: string, toolName: string): void {
    this.trusted.set(agentId, new Set([...(this.trusted.get(agentId) ?? []), toolName]))
  }

  trusts(agentId: string, toolName: string): boolean {
    return this.trusted.get(agentId)?.has(toolName) ?? false
  }

  endTurn(agentId: string): void {
    this.activities.delete(agentId)
    this.trusted.delete(agentId)
  }

  forget(agentId: string): void {
    this.endTurn(agentId)
    this.queues.delete(agentId)
  }
}
