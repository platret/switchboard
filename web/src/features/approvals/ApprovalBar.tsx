import { useStore } from '@/lib/store.ts'
import { ApprovalCard } from './ApprovalCard.tsx'

export function ApprovalBar() {
  const approvals = useStore((state) => state.approvals)
  const openAgentId = useStore((state) => (state.view === 'chat' ? state.agentId : null))
  const elsewhere = approvals.filter((approval) => approval.agentId !== openAgentId)
  if (elsewhere.length === 0) return null
  return (
    <section aria-label="Pending approvals" className="max-h-[calc(var(--app-height,100dvh)*0.7)] flex-none overflow-y-auto border-b bg-waiting-surface px-3 pb-3 pt-[calc(env(safe-area-inset-top)+0.75rem)]">
      <div className="mx-auto grid max-w-3xl gap-2.5">
        {elsewhere.length > 1 && <p className="text-sm font-medium">{elsewhere.length} approvals waiting</p>}
        {elsewhere.map((approval) => (
          <ApprovalCard key={approval.id} approval={approval} />
        ))}
      </div>
    </section>
  )
}
