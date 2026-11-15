import { Command } from 'cmdk'
import { FolderOpen, LayoutGrid, Plus, Search, Settings } from 'lucide-react'
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog'
import { Avatar } from '@/features/agents/Avatar.tsx'
import { StatusLamp } from '@/features/agents/StatusLamp.tsx'
import { byUrgency } from '@/features/agents/status.ts'
import { useStore } from '@/lib/store.ts'

const itemClass = 'flex cursor-pointer items-center gap-3 rounded-lg px-2.5 py-2 text-sm data-[selected=true]:bg-accent'
const headingClass = '[&_[cmdk-group-heading]]:px-2.5 [&_[cmdk-group-heading]]:py-1.5 [&_[cmdk-group-heading]]:text-xs [&_[cmdk-group-heading]]:text-muted-foreground'

export function CommandPalette() {
  const open = useStore((state) => state.paletteOpen)
  const agents = useStore((state) => state.agents)
  const projects = useStore((state) => state.projects)
  const roles = useStore((state) => state.roles)
  const { setPaletteOpen, openAgent, selectProject, setView, setSettingsOpen, setCreatingAgent, selectAgent } = useStore.getState()
  const roleName = (id: string) => roles.find((role) => role.id === id)?.name ?? id
  const projectName = (id: string) => projects.find((project) => project.id === id)?.name ?? id

  const run = (action: () => void) => () => {
    action()
    setPaletteOpen(false)
  }

  return (
    <Dialog open={open} onOpenChange={setPaletteOpen}>
      <DialogContent showCloseButton={false} className="gap-0 overflow-hidden p-0 sm:max-w-xl">
        <DialogTitle className="sr-only">Search</DialogTitle>
        <DialogDescription className="sr-only">Jump to an agent, a project or an action.</DialogDescription>
        <Command loop>
          <div className="flex items-center gap-2.5 border-b px-3.5">
            <Search className="size-4 flex-none text-muted-foreground" />
            <Command.Input autoFocus placeholder="Jump to an agent, project or action" className="h-12 w-full bg-transparent text-base outline-none placeholder:text-muted-foreground" />
          </div>
          <Command.List className="max-h-[min(24rem,60dvh)] overflow-y-auto p-1.5">
            <Command.Empty className="px-3 py-8 text-center text-sm text-muted-foreground">Nothing matches that.</Command.Empty>
            <Command.Group heading="Agents" className={headingClass}>
              {Object.values(agents)
                .sort(byUrgency)
                .map((agent) => (
                  <Command.Item key={agent.id} value={`${agent.name} ${roleName(agent.role)} ${projectName(agent.projectId)} ${agent.id}`} onSelect={run(() => openAgent(agent))} className={itemClass}>
                    <Avatar agent={agent} size="sm" />
                    <span className="min-w-0 flex-1 truncate font-medium">{agent.name}</span>
                    <span className="truncate text-muted-foreground">
                      {roleName(agent.role)} in {projectName(agent.projectId)}
                    </span>
                    {agent.status !== 'idle' && <StatusLamp status={agent.status} size="sm" />}
                  </Command.Item>
                ))}
            </Command.Group>
            <Command.Group heading="Projects" className={headingClass}>
              {projects.map((project) => (
                <Command.Item key={project.id} value={`project ${project.name}`} onSelect={run(() => selectProject(project.id))} className={itemClass}>
                  <FolderOpen className="size-4 text-muted-foreground" />
                  {project.name}
                </Command.Item>
              ))}
            </Command.Group>
            <Command.Group heading="Go to" className={headingClass}>
              <Command.Item
                value="new agent create"
                onSelect={run(() => {
                  selectAgent(null)
                  setCreatingAgent(true)
                })}
                className={itemClass}
              >
                <Plus className="size-4 text-muted-foreground" />
                New agent in this project
              </Command.Item>
              <Command.Item value="all agents overview" onSelect={run(() => setView('overview'))} className={itemClass}>
                <LayoutGrid className="size-4 text-muted-foreground" />
                All agents
              </Command.Item>
              <Command.Item value="settings theme voice phone" onSelect={run(() => setSettingsOpen(true))} className={itemClass}>
                <Settings className="size-4 text-muted-foreground" />
                Settings
              </Command.Item>
            </Command.Group>
          </Command.List>
        </Command>
      </DialogContent>
    </Dialog>
  )
}
