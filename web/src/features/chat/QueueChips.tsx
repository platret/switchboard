import type { Agent } from '@switchboard/shared'
import { Clock, X } from 'lucide-react'
import { sendOrWarn } from '@/lib/socket.ts'

export function QueueChips({ agent }: { agent: Agent }) {
  if (agent.queue.length === 0) return null
  return (
    <ul aria-label="Queued messages" className="grid gap-1 border-b px-2 pb-2 pt-1">
      {agent.queue.map((entry) => (
        <li key={entry.id} className="flex items-center gap-2 rounded-lg bg-muted px-2.5 py-1.5 text-sm">
          <Clock className="size-3.5 flex-none text-muted-foreground" />
          <span className="min-w-0 flex-1 truncate">{entry.text}</span>
          <span className="flex-none text-xs text-muted-foreground">Queued</span>
          <button type="button" onClick={() => sendOrWarn({ type: 'queue.remove', agentId: agent.id, id: entry.id })} aria-label="Remove queued message" className="flex-none rounded p-0.5 text-muted-foreground hover:text-foreground">
            <X className="size-3.5" />
          </button>
        </li>
      ))}
    </ul>
  )
}
