import type { Agent, AgentStatus } from '@switchboard/shared'
import { avatarHue, initials } from '@/lib/avatar.ts'
import { cn } from '@/lib/utils'
import { StatusLamp } from './StatusLamp.tsx'

type Props = {
  agent: Pick<Agent, 'id' | 'name'>
  status?: AgentStatus
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const sizes = {
  sm: 'size-7 text-[0.6875rem]',
  md: 'size-9 text-sm',
  lg: 'size-14 text-xl',
}

export function Avatar({ agent, status, size = 'md', className }: Props) {
  const hue = avatarHue(agent.id)
  return (
    <span className={cn('relative inline-flex flex-none', className)}>
      <span
        aria-hidden="true"
        className={cn('inline-flex items-center justify-center rounded-full font-semibold text-white', sizes[size])}
        style={{ background: `linear-gradient(145deg, hsl(${hue} 72% 56%), hsl(${hue + 24} 68% 42%))` }}
      >
        {initials(agent.name)}
      </span>
      {status && status !== 'idle' && (
        <span className="absolute -bottom-0.5 -right-0.5 flex size-4 items-center justify-center rounded-full bg-card">
          <StatusLamp status={status} size="sm" />
        </span>
      )}
    </span>
  )
}
