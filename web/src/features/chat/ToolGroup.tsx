import { ChevronRight, ListChecks } from 'lucide-react'
import { useState } from 'react'
import { cn } from '@/lib/utils'
import { ToolRow, ToolStatusMark, type Tool } from './ToolRow.tsx'

function overall(tools: Tool[]) {
  if (tools.some((tool) => tool.status === 'running')) return 'running' as const
  if (tools.some((tool) => tool.status === 'denied')) return 'denied' as const
  if (tools.some((tool) => tool.status === 'error')) return 'error' as const
  return 'done' as const
}

export function ToolGroup({ tools }: { tools: Tool[] }) {
  const [open, setOpen] = useState(false)
  const single = tools.length === 1 ? tools[0] : undefined
  if (single) {
    return (
      <div className="rounded-lg border bg-card p-0.5">
        <ToolRow tool={single} />
      </div>
    )
  }
  const latest = tools.find((tool) => tool.status === 'running') ?? tools[tools.length - 1]
  const status = overall(tools)
  return (
    <div className="rounded-lg border bg-card p-0.5">
      <button type="button" onClick={() => setOpen(!open)} aria-expanded={open} className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left text-sm transition-colors hover:bg-accent/60">
        <ListChecks className="size-4 flex-none text-muted-foreground" />
        <span className="flex-none font-medium">{tools.length} steps</span>
        <span className="min-w-0 flex-1 truncate text-muted-foreground">
          {latest ? `${status === 'running' ? 'Now' : 'Last'}: ${latest.name} ${latest.summary}` : ''}
        </span>
        <ToolStatusMark status={status} />
        <ChevronRight className={cn('size-3.5 flex-none text-muted-foreground transition-transform', open && 'rotate-90')} />
      </button>
      {open && (
        <div className="border-t pt-0.5">
          {tools.map((tool) => (
            <ToolRow key={tool.toolUseId} tool={tool} />
          ))}
        </div>
      )}
    </div>
  )
}
