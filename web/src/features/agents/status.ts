import type { Agent, AgentStatus } from '@switchboard/shared'

export const statusLabels: Record<AgentStatus, string> = {
  idle: 'Idle',
  working: 'Working',
  waiting: 'Needs approval',
  error: 'Error',
}

const urgency: Record<AgentStatus, number> = { waiting: 0, error: 1, working: 2, idle: 3 }

export function byUrgency(a: Agent, b: Agent): number {
  return urgency[a.status] - urgency[b.status] || b.lastActivityAt - a.lastActivityAt
}

export function summarize(agents: Agent[]): string {
  const count = (status: AgentStatus) => agents.filter((agent) => agent.status === status).length
  const parts = [
    count('waiting') > 0 && `${count('waiting')} need approval`,
    count('error') > 0 && `${count('error')} with errors`,
    count('working') > 0 && `${count('working')} working`,
    `${count('idle')} idle`,
  ]
  return parts.filter(Boolean).join(', ')
}
