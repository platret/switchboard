import type { Approval } from '@switchboard/shared'
import { ToolDetails } from '@/features/chat/ToolDetails.tsx'

export function ApprovalDetails({ approval }: { approval: Approval }) {
  return <ToolDetails toolName={approval.toolName} input={approval.input} />
}
