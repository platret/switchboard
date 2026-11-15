import type { Agent } from '@switchboard/shared'
import { StatusLamp } from '@/features/agents/StatusLamp.tsx'

export function ActivityLine({ agent }: { agent: Agent }) {
  if (agent.status !== 'working') return null
  return (
    <p role="status" className="flex items-center gap-2.5 py-1 text-sm">
      <StatusLamp status="working" />
      <span className="shimmer min-w-0 truncate">{agent.activity ?? 'Working'}</span>
      {agent.trustedTools.length > 0 && <span className="flex-none rounded-full border px-2 py-0.5 text-xs text-muted-foreground">Edits allowed this turn</span>}
    </p>
  )
}
