import { LayoutGrid, Search, Settings } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ProjectSwitcher } from '@/features/projects/ProjectSwitcher.tsx'
import { isUnread, useStore } from '@/lib/store.ts'
import { useNow } from '@/lib/useNow.ts'
import { cn } from '@/lib/utils'
import { AgentRow } from './AgentRow.tsx'
import { CreateAgentDialog } from './CreateAgentDialog.tsx'
import { byUrgency } from './status.ts'

type Props = {
  className?: string
}

const connectionTexts = { connecting: 'Connecting', closed: 'Offline, retrying', open: '' }

export function Sidebar({ className }: Props) {
  const projects = useStore((state) => state.projects)
  const roles = useStore((state) => state.roles)
  const agents = useStore((state) => state.agents)
  const approvals = useStore((state) => state.approvals.length)
  const projectId = useStore((state) => state.projectId)
  const agentId = useStore((state) => state.agentId)
  const connection = useStore((state) => state.connection)
  const ready = useStore((state) => state.ready)
  const view = useStore((state) => state.view)
  const lastRead = useStore((state) => state.lastRead)
  const creating = useStore((state) => state.creatingAgent)
  const { selectAgent, setView, setPaletteOpen, setSettingsOpen, setCreatingAgent } = useStore.getState()
  const now = useNow(30_000)

  const project = projects.find((candidate) => candidate.id === projectId)
  const lines = Object.values(agents)
    .filter((agent) => agent.projectId === projectId)
    .sort(byUrgency)
  const roleName = (id: string) => roles.find((role) => role.id === id)?.name ?? id
  const openId = view === 'chat' ? agentId : null

  return (
    <aside className={cn('flex-col border-r bg-card', className)}>
      <header className="flex items-center gap-2 px-4 pb-3 pt-[calc(var(--inset-top)+0.875rem)]">
        <img src="/icon.svg" alt="" className="size-7 rounded-md" />
        <h1 className="min-w-0 flex-1 text-[1.0625rem] font-semibold tracking-tight">Switchboard</h1>
        {connection !== 'open' && <span className="text-xs text-muted-foreground">{connectionTexts[connection]}</span>}
        <Button type="button" variant="ghost" size="icon-sm" onClick={() => setSettingsOpen(true)} aria-label="Settings">
          <Settings className="text-muted-foreground" />
        </Button>
      </header>
      <div className="grid gap-2 px-3 pb-3">
        <ProjectSwitcher />
        <div className="grid grid-cols-2 gap-2">
          <Button type="button" variant="outline" aria-current={view === 'overview' ? 'true' : undefined} onClick={() => setView('overview')} className={cn('justify-start', view === 'overview' && 'border-primary/60 bg-accent')}>
            <LayoutGrid className="text-muted-foreground" />
            <span className="flex-1 text-left">All agents</span>
            {approvals > 0 && <span className="rounded-full bg-lamp-waiting px-1.5 text-xs font-semibold text-background">{approvals}</span>}
          </Button>
          <Button type="button" variant="outline" onClick={() => setPaletteOpen(true)} className="justify-start text-muted-foreground">
            <Search />
            <span className="flex-1 text-left">Search</span>
            <kbd className="hidden rounded border px-1 font-sans text-[0.6875rem] md:inline">⌘K</kbd>
          </Button>
        </div>
      </div>
      <nav aria-label={project ? `Agents in ${project.name}` : 'Agents'} className="min-h-0 flex-1 space-y-0.5 overflow-y-auto px-2 pb-3">
        {lines.map((agent) => (
          <AgentRow key={agent.id} agent={agent} roleName={roleName(agent.role)} selected={agent.id === openId} unread={isUnread(agent, lastRead, openId)} now={now} onSelect={() => selectAgent(agent.id)} />
        ))}
        {ready && lines.length === 0 && (
          <p className="px-3 py-6 text-center text-sm text-muted-foreground">
            {project ? 'No agents in this project yet. Create the first one below.' : 'No project yet. Edit projects.json in the Switchboard folder so it lists a folder that exists, then restart the host.'}
          </p>
        )}
      </nav>
      {project && (
        <div className="border-t p-3 pb-[calc(env(safe-area-inset-bottom)+0.75rem)]">
          <CreateAgentDialog project={project} roles={project.agents.flatMap((id) => roles.filter((role) => role.id === id))} open={creating} onOpenChange={setCreatingAgent} />
        </div>
      )}
    </aside>
  )
}
