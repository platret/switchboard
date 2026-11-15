import { Check, ChevronsUpDown } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { StatusLamp } from '@/features/agents/StatusLamp.tsx'
import { byUrgency } from '@/features/agents/status.ts'
import { useStore } from '@/lib/store.ts'

export function ProjectSwitcher() {
  const projects = useStore((state) => state.projects)
  const agents = useStore((state) => state.agents)
  const projectId = useStore((state) => state.projectId)
  const selectProject = useStore((state) => state.selectProject)
  const current = projects.find((project) => project.id === projectId)

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button type="button" variant="outline" className="h-11 w-full justify-start gap-3 px-3 text-left">
          <span className="min-w-0 flex-1">
            <span className="block text-xs font-normal text-muted-foreground">Project</span>
            <span className="block truncate leading-tight">{current?.name ?? 'Pick a project'}</span>
          </span>
          <ChevronsUpDown className="text-muted-foreground" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start" className="w-(--radix-dropdown-menu-trigger-width) min-w-56">
        <DropdownMenuLabel>Switch project</DropdownMenuLabel>
        {projects.map((project) => {
          const members = Object.values(agents).filter((agent) => agent.projectId === project.id)
          const loudest = [...members].sort(byUrgency)[0]
          return (
            <DropdownMenuItem key={project.id} onSelect={() => selectProject(project.id)} className="gap-3 py-2">
              <span className="min-w-0 flex-1">
                <span className="block truncate font-medium">{project.name}</span>
                <span className="block truncate text-xs text-muted-foreground">{members.length === 1 ? '1 agent' : `${members.length} agents`}</span>
              </span>
              {loudest && loudest.status !== 'idle' && <StatusLamp status={loudest.status} />}
              {project.id === projectId && <Check className="text-primary" />}
            </DropdownMenuItem>
          )
        })}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
