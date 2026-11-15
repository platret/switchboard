import { z } from 'zod'

export const agentStatusSchema = z.enum(['idle', 'working', 'waiting', 'error'])
export type AgentStatus = z.infer<typeof agentStatusSchema>

export function isBusy(status: AgentStatus): boolean {
  return status === 'working' || status === 'waiting'
}

export const agentNameMaxLength = 40
export const agentNameSchema = z.string().trim().min(1).max(agentNameMaxLength)

export const projectSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  path: z.string().min(1),
  additionalDirectories: z.array(z.string()).default([]),
  agents: z.array(z.string()),
})
export type Project = z.infer<typeof projectSchema>

export const roleSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  description: z.string().default(''),
  systemPrompt: z.string(),
  tools: z.array(z.string()),
  model: z.string().min(1).optional(),
  starters: z.array(z.string()).default([]),
})
export type Role = z.infer<typeof roleSchema>

export const storedAgentSchema = z.object({
  id: z.string(),
  name: z.string(),
  projectId: z.string(),
  role: z.string(),
  sessionId: z.string().nullable(),
  status: agentStatusSchema,
  createdAt: z.number(),
  lastActivityAt: z.number(),
  preview: z.string().nullable(),
})
export type StoredAgent = z.infer<typeof storedAgentSchema>

export const queuedMessageSchema = z.object({ id: z.string(), text: z.string() })
export type QueuedMessage = z.infer<typeof queuedMessageSchema>

export const agentSchema = storedAgentSchema.extend({
  activity: z.string().nullable(),
  queue: z.array(queuedMessageSchema),
  trustedTools: z.array(z.string()),
})
export type Agent = z.infer<typeof agentSchema>

export const toolStatusSchema = z.enum(['running', 'done', 'error', 'denied'])
export type ToolStatus = z.infer<typeof toolStatusSchema>

export const chatContentSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('text'), text: z.string() }),
  z.object({
    kind: z.literal('tool'),
    toolUseId: z.string(),
    name: z.string(),
    summary: z.string(),
    input: z.unknown(),
    status: toolStatusSchema,
    result: z.string().optional(),
  }),
  z.object({ kind: z.literal('error'), text: z.string() }),
  z.object({ kind: z.literal('notice'), text: z.string() }),
])
export type ChatContent = z.infer<typeof chatContentSchema>

export const chatRoleSchema = z.enum(['user', 'assistant', 'system'])
export type ChatRole = z.infer<typeof chatRoleSchema>

export const chatItemSchema = z.object({
  id: z.string(),
  agentId: z.string(),
  role: chatRoleSchema,
  content: chatContentSchema,
  createdAt: z.number(),
})
export type ChatItem = z.infer<typeof chatItemSchema>

export const chatDraftSchema = z.object({ id: z.string(), text: z.string() })
export type ChatDraft = z.infer<typeof chatDraftSchema>

export const approvalSchema = z.object({
  id: z.string(),
  agentId: z.string(),
  toolName: z.string(),
  summary: z.string(),
  input: z.unknown(),
  turnTrust: z.boolean().default(false),
  createdAt: z.number(),
  expiresAt: z.number(),
})
export type Approval = z.infer<typeof approvalSchema>

export const approvalDecisionSchema = z.enum(['allow', 'deny'])
export type ApprovalDecision = z.infer<typeof approvalDecisionSchema>

export const approvalScopeSchema = z.enum(['once', 'turn'])
export type ApprovalScope = z.infer<typeof approvalScopeSchema>

export const turnTrustTools = ['Edit', 'Write', 'NotebookEdit']

export const approvalSourceSchema = z.enum(['user', 'timeout', 'stop'])
export type ApprovalSource = z.infer<typeof approvalSourceSchema>
