import type { ChatContent, ToolStatus } from '@switchboard/shared'
import { Ban, Check, ChevronRight, CircleAlert, FilePen, FileText, Globe, Search, Terminal, Users, Wrench, type LucideIcon } from 'lucide-react'
import { useState } from 'react'
import { cn } from '@/lib/utils'
import { DetailBlock, ToolDetails } from './ToolDetails.tsx'

export type Tool = Extract<ChatContent, { kind: 'tool' }>

const icons: Record<string, LucideIcon> = {
  Bash: Terminal,
  Read: FileText,
  Edit: FilePen,
  Write: FilePen,
  NotebookEdit: FilePen,
  Glob: Search,
  Grep: Search,
  WebFetch: Globe,
  WebSearch: Globe,
  Agent: Users,
  Task: Users,
}

const statusText: Record<ToolStatus, string> = {
  running: 'Running',
  done: 'Done',
  error: 'Failed',
  denied: 'Denied',
}

export function toolIcon(name: string): LucideIcon {
  return icons[name] ?? Wrench
}

export function ToolStatusMark({ status }: { status: ToolStatus }) {
  if (status === 'running') return <span className="lamp" data-status="working" data-size="sm" role="img" aria-label={statusText.running} />
  const Icon = status === 'done' ? Check : status === 'denied' ? Ban : CircleAlert
  return <Icon aria-label={statusText[status]} className={cn('size-3.5 flex-none', status === 'done' ? 'text-muted-foreground' : 'text-destructive')} />
}

export function ToolRow({ tool }: { tool: Tool }) {
  const [open, setOpen] = useState(false)
  const Icon = toolIcon(tool.name)
  return (
    <div className="text-sm">
      <button type="button" onClick={() => setOpen(!open)} aria-expanded={open} className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left transition-colors hover:bg-accent/60">
        <Icon className="size-4 flex-none text-muted-foreground" />
        <span className="min-w-0 max-w-[45%] flex-none truncate font-medium">{tool.name}</span>
        <span className="min-w-0 flex-1 truncate font-mono text-xs text-muted-foreground">{tool.summary}</span>
        <ToolStatusMark status={tool.status} />
        <ChevronRight className={cn('size-3.5 flex-none text-muted-foreground transition-transform', open && 'rotate-90')} />
      </button>
      {open && (
        <div className="mx-2 mb-2 mt-1 grid gap-2">
          <ToolDetails toolName={tool.name} input={tool.input} />
          {tool.result && <DetailBlock label="Result" text={tool.result} tone="muted" />}
        </div>
      )}
    </div>
  )
}
