import type { Approval, ApprovalDecision, ApprovalScope } from '@switchboard/shared'
import { useEffect, useState } from 'react'
import { Button } from '@/components/ui/button'
import { Avatar } from '@/features/agents/Avatar.tsx'
import { sendOrWarn } from '@/lib/socket.ts'
import { useStore } from '@/lib/store.ts'
import { useNow } from '@/lib/useNow.ts'
import { ApprovalDetails } from './ApprovalDetails.tsx'
import { countdown, describeAction } from './describe.ts'

const settleMs = 600

export function ApprovalCard({ approval }: { approval: Approval }) {
  const agent = useStore((state) => state.agents[approval.agentId])
  const projectName = useStore((state) => state.projects.find((project) => project.id === agent?.projectId)?.name)
  const openAgent = useStore((state) => state.openAgent)
  const now = useNow(1000)
  const [answered, setAnswered] = useState(false)
  const connection = useStore((state) => state.connection)

  useEffect(() => {
    if (connection !== 'open') setAnswered(false)
  }, [connection])

  const respond = (decision: ApprovalDecision, scope: ApprovalScope = 'once') => {
    if (Date.now() - useStore.getState().approvalsChangedAt < settleMs) return
    if (sendOrWarn({ type: 'approval.respond', approvalId: approval.id, decision, scope })) setAnswered(true)
  }
  const agentName = agent?.name ?? 'An agent'

  return (
    <article aria-label={`Approval request from ${agentName}`} className="grid gap-3 rounded-xl border border-lamp-waiting/50 bg-card p-3.5 shadow-float">
      <header className="flex items-start gap-3">
        {agent && <Avatar agent={agent} status="waiting" />}
        <div className="min-w-0 flex-1">
          <h3 className="font-medium leading-snug">
            {agent ? (
              <button type="button" onClick={() => openAgent(agent)} className="underline decoration-muted-foreground/40 underline-offset-2">
                {agent.name}
              </button>
            ) : (
              agentName
            )}{' '}
            wants to {describeAction(approval.toolName)}
          </h3>
          <p className="text-sm text-muted-foreground">
            {projectName ? `${projectName}. ` : ''}Denied automatically in <time className="tabular-nums">{countdown(approval.expiresAt - now)}</time>
          </p>
        </div>
      </header>
      <ApprovalDetails approval={approval} />
      <div className="grid grid-cols-2 gap-2">
        <Button type="button" variant="outline" size="lg" disabled={answered} onClick={() => respond('deny')}>
          Deny
        </Button>
        <Button type="button" size="lg" disabled={answered} onClick={() => respond('allow')}>
          Allow
        </Button>
        {approval.turnTrust && (
          <Button type="button" variant="ghost" disabled={answered} onClick={() => respond('allow', 'turn')} className="col-span-2 text-muted-foreground">
            Allow all edits inside the project for this turn
          </Button>
        )}
      </div>
    </article>
  )
}
