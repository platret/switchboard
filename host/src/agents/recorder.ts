import { randomUUID } from 'node:crypto'
import type { Agent, AgentStatus, ChatContent, ChatItem, ChatRole, Project } from '@switchboard/shared'
import type { AgentRepo } from '../repo/agents.ts'
import type { MessageRepo } from '../repo/messages.ts'
import type { Hub } from '../ws/hub.ts'
import type { LiveState } from './live.ts'
import { summarizeTool } from './summary.ts'

export type RecorderDeps = {
  agents: AgentRepo
  messages: MessageRepo
  hub: Hub
  live: LiveState
}

export class Recorder {
  constructor(private readonly deps: RecorderDeps) {}

  view(agentId: string): Agent | undefined {
    const agent = this.deps.agents.get(agentId)
    return agent ? this.deps.live.view(agent) : undefined
  }

  list(): Agent[] {
    return this.deps.agents.list().map((agent) => this.deps.live.view(agent))
  }

  publish(agentId: string): void {
    const agent = this.view(agentId)
    if (agent) this.deps.hub.broadcast({ type: 'agent.upserted', agent })
  }

  setStatus(agentId: string, status: AgentStatus): void {
    this.deps.agents.update(agentId, { status })
    this.publish(agentId)
  }

  setActivity(agentId: string, activity: string | null): void {
    if (this.deps.live.setActivity(agentId, activity)) this.publish(agentId)
  }

  save(agentId: string, role: ChatRole, content: ChatContent, id: string = randomUUID()): void {
    this.put({ id, agentId, role, content, createdAt: Date.now() })
  }

  notice(agentId: string, text: string): void {
    this.save(agentId, 'system', { kind: 'notice', text })
  }

  error(agentId: string, text: string): void {
    this.save(agentId, 'system', { kind: 'error', text })
  }

  toolStarted(agentId: string, project: Project, toolUseId: string, name: string, input: unknown, denied: boolean): void {
    const summary = summarizeTool(input, [project.path, ...project.additionalDirectories])
    this.deps.live.setActivity(agentId, summary ? `${name}: ${summary}` : name)
    this.save(agentId, 'assistant', { kind: 'tool', toolUseId, name, summary, input, status: denied ? 'denied' : 'running' }, toolUseId)
  }

  toolFinished(toolUseId: string, isError: boolean, result: string, denied: boolean): void {
    const item = this.deps.messages.get(toolUseId)
    if (item?.content.kind !== 'tool') return
    const status = denied || item.content.status === 'denied' ? 'denied' : isError ? 'error' : 'done'
    this.deps.live.setActivity(item.agentId, 'Thinking')
    this.put({ ...item, content: { ...item.content, status, result } })
  }

  toolDenied(toolUseId: string): void {
    const item = this.deps.messages.get(toolUseId)
    if (item?.content.kind === 'tool') this.put({ ...item, content: { ...item.content, status: 'denied' } })
  }

  failRunningTools(agentId: string): void {
    for (const item of this.deps.messages.listRunningTools(agentId)) {
      if (item.content.kind === 'tool') this.put({ ...item, content: { ...item.content, status: 'error', result: 'Interrupted' } })
    }
  }

  private put(item: ChatItem): void {
    this.deps.messages.upsert(item)
    this.deps.hub.broadcast({ type: 'chat.item', item })
    this.publish(item.agentId)
  }
}
