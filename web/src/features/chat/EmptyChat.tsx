import type { Agent, Role } from '@switchboard/shared'
import { Avatar } from '@/features/agents/Avatar.tsx'

type Props = {
  agent: Agent
  role: Role | undefined
  onPick: (text: string) => void
}

export function EmptyChat({ agent, role, onPick }: Props) {
  return (
    <div className="my-auto flex flex-col items-center gap-4 py-10 text-center">
      <Avatar agent={agent} size="lg" />
      <div>
        <h3 className="text-xl font-semibold tracking-tight">{agent.name}</h3>
        <p className="mx-auto max-w-sm text-muted-foreground">{role?.description || role?.name || agent.role}</p>
      </div>
      {role && role.starters.length > 0 && (
        <ul className="grid w-full max-w-md gap-2 pt-2">
          {role.starters.map((starter) => (
            <li key={starter}>
              <button type="button" onClick={() => onPick(starter)} className="w-full rounded-xl border bg-card px-4 py-3 text-left text-[0.9375rem] transition-colors hover:border-primary/50 hover:bg-accent">
                {starter}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
