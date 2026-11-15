import type { Agent } from '@switchboard/shared'
import { ChevronLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Avatar } from '@/features/agents/Avatar.tsx'
import { StatusLamp } from '@/features/agents/StatusLamp.tsx'
import { byUrgency, statusLabels, summarize } from '@/features/agents/status.ts'
import { isUnread, useStore } from '@/lib/store.ts'
import { relativeTime } from '@/lib/time.ts'
import { useNow } from '@/lib/useNow.ts'
import { cn } from '@/lib/utils'

function detail(agent: Agent): string {
  if (agent.status === 'working') return agent.activity ?? 'Working'
  if (agent.status === 'waiting') return 'Waiting for your approval'
  if (agent.status === 'error') return 'Ran into an error. Open to see why.'
  return agent.preview ?? 'No messages yet'
}

export function Overview() {
  const agents = useStore((state) => state.agents)
  const projects = useStore((state) => state.projects)
  const roles = useStore((state) => state.roles)
  const lastRead = useStore((state) => state.lastRead)
  const openAgent = useStore((state) => state.openAgent)
  const setView = useStore((state) => state.setView)
  const now = useNow(30_000)

  const all = Object.values(agents)
  const roleName = (id: string) => roles.find((role) => role.id === id)?.name ?? id
  const groups = projects.map((project) => ({ project, members: all.filter((agent) => agent.projectId === project.id).sort(byUrgency) })).filter((group) => group.members.length > 0)

  return (
    <section className="flex h-full min-w-0 flex-1 flex-col">
      <header className="flex items-center gap-2 border-b bg-card/80 px-2 pb-2.5 pt-[calc(var(--inset-top)+0.625rem)] backdrop-blur md:px-5">
        <Button type="button" variant="ghost" size="icon" className="md:hidden" onClick={() => setView('chat')} aria-label="Back to agents">
          <ChevronLeft />
        </Button>
        <div className="min-w-0 flex-1">
          <h2 className="truncate font-semibold leading-tight">All agents</h2>
          <p className="truncate text-sm text-muted-foreground">{all.length === 0 ? 'No agents yet' : summarize(all)}</p>
        </div>
      </header>
      <div className="flex-1 overflow-y-auto px-3 py-5 md:px-5">
        {groups.length === 0 && <p className="py-16 text-center text-muted-foreground">Create an agent in a project and it shows up here.</p>}
        <div className="mx-auto grid max-w-6xl gap-7">
          {groups.map(({ project, members }) => (
            <section key={project.id} aria-label={project.name}>
              <h3 className="flex items-baseline gap-2 px-1 pb-2.5 font-semibold">
                {project.name}
                <span className="text-sm font-normal text-muted-foreground">{summarize(members)}</span>
              </h3>
              <ul className="grid gap-2.5 sm:grid-cols-2 xl:grid-cols-3">
                {members.map((agent) => (
                  <li key={agent.id}>
                    <button
                      type="button"
                      onClick={() => openAgent(agent)}
                      className={cn(
                        'flex h-full w-full flex-col gap-3 rounded-xl border bg-card p-3.5 text-left transition-colors hover:border-primary/50',
                        agent.status === 'waiting' && 'border-lamp-waiting/60 bg-waiting-surface',
                        agent.status === 'error' && 'border-destructive/50',
                      )}
                    >
                      <span className="flex w-full items-center gap-3">
                        <Avatar agent={agent} />
                        <span className="min-w-0 flex-1">
                          <span className={cn('block truncate leading-tight', isUnread(agent, lastRead, null) ? 'font-semibold' : 'font-medium')}>{agent.name}</span>
                          <span className="block truncate text-sm text-muted-foreground">{roleName(agent.role)}</span>
                        </span>
                        <span className="flex flex-none items-center gap-1.5 text-sm text-muted-foreground">
                          <StatusLamp status={agent.status} size="sm" />
                          {agent.status === 'idle' ? relativeTime(agent.lastActivityAt, now) : statusLabels[agent.status]}
                        </span>
                      </span>
                      <span className={cn('line-clamp-2 min-h-10 text-sm', agent.status === 'working' ? 'shimmer' : agent.status === 'waiting' ? 'text-lamp-waiting' : 'text-muted-foreground')}>{detail(agent)}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </div>
    </section>
  )
}
