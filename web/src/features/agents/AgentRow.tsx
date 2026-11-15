import type { Agent } from '@switchboard/shared'
import { cn } from '@/lib/utils'
import { relativeTime } from '@/lib/time.ts'
import { Avatar } from './Avatar.tsx'
import { statusLabels } from './status.ts'

type Props = {
  agent: Agent
  roleName: string
  selected: boolean
  unread: boolean
  now: number
  onSelect: () => void
}

function secondLine(agent: Agent, roleName: string): string {
  if (agent.status === 'waiting') return 'Needs your approval'
  if (agent.status === 'working') return agent.activity ?? statusLabels.working
  if (agent.status === 'error') return 'Ran into an error'
  return agent.preview ?? roleName
}

export function AgentRow({ agent, roleName, selected, unread, now, onSelect }: Props) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-current={selected ? 'true' : undefined}
      className={cn(
        'group flex w-full items-center gap-3 rounded-lg px-2.5 py-2 text-left transition-colors hover:bg-accent/70',
        selected && 'bg-accent',
        agent.status === 'waiting' && !selected && 'bg-waiting-surface',
      )}
    >
      <Avatar agent={agent} status={agent.status} />
      <span className="min-w-0 flex-1">
        <span className="flex items-baseline gap-2">
          <span className={cn('min-w-0 flex-1 truncate leading-tight', unread ? 'font-semibold' : 'font-medium')}>{agent.name}</span>
          <time className="flex-none text-xs text-muted-foreground">{relativeTime(agent.lastActivityAt, now)}</time>
        </span>
        <span className="flex items-center gap-2">
          <span className={cn('min-w-0 flex-1 truncate text-sm', agent.status === 'waiting' ? 'text-lamp-waiting' : unread ? 'text-foreground' : 'text-muted-foreground')}>
            {secondLine(agent, roleName)}
          </span>
          {unread && <span aria-label="Unread" className="size-2 flex-none rounded-full bg-primary" />}
        </span>
      </span>
    </button>
  )
}
