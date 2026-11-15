import type { Agent } from '@switchboard/shared'
import { ChevronLeft, Ellipsis, Pencil, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Avatar } from '@/features/agents/Avatar.tsx'
import { DeleteAgentDialog } from '@/features/agents/DeleteAgentDialog.tsx'
import { RenameAgentDialog } from '@/features/agents/RenameAgentDialog.tsx'
import { StatusLamp } from '@/features/agents/StatusLamp.tsx'
import { statusLabels } from '@/features/agents/status.ts'
import { useStore } from '@/lib/store.ts'

export function ChatHeader({ agent }: { agent: Agent }) {
  const roleName = useStore((state) => state.roles.find((role) => role.id === agent.role)?.name ?? agent.role)
  const projectName = useStore((state) => state.projects.find((project) => project.id === agent.projectId)?.name ?? agent.projectId)
  const selectAgent = useStore((state) => state.selectAgent)
  const [renaming, setRenaming] = useState(false)
  const [deleting, setDeleting] = useState(false)

  return (
    <header className="flex items-center gap-2.5 border-b bg-card/80 px-2 pb-2.5 pt-[calc(var(--inset-top)+0.625rem)] backdrop-blur md:px-4">
      <Button type="button" variant="ghost" size="icon" className="md:hidden" onClick={() => selectAgent(null)} aria-label="Back to agents">
        <ChevronLeft />
      </Button>
      <Avatar agent={agent} />
      <div className="min-w-0 flex-1">
        <h2 className="truncate font-semibold leading-tight">{agent.name}</h2>
        <p className="truncate text-sm text-muted-foreground">
          {roleName} in {projectName}
        </p>
      </div>
      <span className="flex items-center gap-2 rounded-full border bg-background px-2.5 py-1 text-sm">
        <StatusLamp status={agent.status} size="sm" />
        {statusLabels[agent.status]}
      </span>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button type="button" variant="ghost" size="icon" aria-label={`More actions for ${agent.name}`}>
            <Ellipsis />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem onSelect={() => setRenaming(true)}>
            <Pencil />
            Rename
          </DropdownMenuItem>
          <DropdownMenuItem variant="destructive" onSelect={() => setDeleting(true)}>
            <Trash2 />
            Delete agent
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <RenameAgentDialog agent={agent} open={renaming} onOpenChange={setRenaming} />
      <DeleteAgentDialog agent={agent} open={deleting} onOpenChange={setDeleting} />
    </header>
  )
}
