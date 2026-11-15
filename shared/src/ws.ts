import { z } from 'zod'
import { bootstrapSchema, historySchema } from './api.ts'
import { agentSchema, approvalDecisionSchema, approvalSchema, approvalScopeSchema, approvalSourceSchema, chatItemSchema } from './domain.ts'

export const unauthorizedCloseCode = 4401
export const chatTextMaxLength = 100_000

export const clientMessageSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('auth'), token: z.string() }),
  z.object({ type: z.literal('chat.send'), agentId: z.string(), text: z.string().trim().min(1).max(chatTextMaxLength) }),
  z.object({ type: z.literal('history.get'), agentId: z.string() }),
  z.object({ type: z.literal('agent.stop'), agentId: z.string() }),
  z.object({ type: z.literal('queue.remove'), agentId: z.string(), id: z.string() }),
  z.object({ type: z.literal('approval.respond'), approvalId: z.string(), decision: approvalDecisionSchema, scope: approvalScopeSchema.default('once') }),
])
export type ClientMessage = z.input<typeof clientMessageSchema>
export type ParsedClientMessage = z.infer<typeof clientMessageSchema>

export const serverMessageSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('auth.ok') }),
  z.object({ type: z.literal('ping') }),
  z.object({ type: z.literal('bootstrap'), bootstrap: bootstrapSchema }),
  z.object({ type: z.literal('history'), agentId: z.string(), history: historySchema }),
  z.object({ type: z.literal('agent.upserted'), agent: agentSchema }),
  z.object({ type: z.literal('agent.removed'), agentId: z.string() }),
  z.object({ type: z.literal('chat.delta'), agentId: z.string(), itemId: z.string(), text: z.string() }),
  z.object({ type: z.literal('chat.item'), item: chatItemSchema }),
  z.object({ type: z.literal('approval.requested'), approval: approvalSchema }),
  z.object({
    type: z.literal('approval.resolved'),
    approvalId: z.string(),
    agentId: z.string(),
    decision: approvalDecisionSchema,
    by: approvalSourceSchema,
  }),
  z.object({ type: z.literal('error'), message: z.string() }),
])
export type ServerMessage = z.infer<typeof serverMessageSchema>
