import { z } from 'zod'
import { agentNameSchema, agentSchema, approvalSchema, chatDraftSchema, chatItemSchema, projectSchema, roleSchema } from './domain.ts'

export const bootstrapSchema = z.object({
  projects: z.array(projectSchema),
  roles: z.array(roleSchema),
  agents: z.array(agentSchema),
  approvals: z.array(approvalSchema),
  host: z.object({ tailscaleUrl: z.string().nullable() }),
})
export type Bootstrap = z.infer<typeof bootstrapSchema>

export const historySchema = z.object({
  items: z.array(chatItemSchema),
  drafts: z.array(chatDraftSchema),
})
export type History = z.infer<typeof historySchema>

export const createAgentSchema = z.object({
  projectId: z.string().min(1),
  role: z.string().min(1),
  name: agentNameSchema,
})
export type CreateAgentInput = z.infer<typeof createAgentSchema>

export const renameAgentSchema = z.object({ name: agentNameSchema })
export type RenameAgentInput = z.infer<typeof renameAgentSchema>
