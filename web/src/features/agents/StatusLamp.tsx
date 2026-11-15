import type { AgentStatus } from '@switchboard/shared'
import { cn } from '@/lib/utils'
import { statusLabels } from './status.ts'

type Props = {
  status: AgentStatus
  size?: 'sm' | 'md'
  className?: string
}

export function StatusLamp({ status, size = 'md', className }: Props) {
  return <span role="img" aria-label={statusLabels[status]} data-status={status} data-size={size} className={cn('lamp', className)} />
}
