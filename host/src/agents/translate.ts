import { randomUUID } from 'node:crypto'
import type { SDKMessage } from '@anthropic-ai/claude-agent-sdk'
import type { ChatDraft } from '@switchboard/shared'
import { clip, flattenResult } from './summary.ts'

export type TurnEvent =
  | { type: 'session'; sessionId: string }
  | { type: 'turn.start' }
  | { type: 'delta'; itemId: string; text: string }
  | { type: 'text'; itemId: string; text: string }
  | { type: 'tool.start'; toolUseId: string; name: string; input: unknown }
  | { type: 'tool.end'; toolUseId: string; isError: boolean; result: string }
  | { type: 'error'; text: string }
  | { type: 'turn.end'; ok: boolean; error: string | null; more: boolean }

const maxResultLength = 4000

export class Translator {
  private streamMessageId: string | null = null
  private readonly blockItems = new Map<number, string>()
  private readonly queues = new Map<string, string[]>()
  private readonly draftTexts = new Map<string, string>()

  drafts(): ChatDraft[] {
    return [...this.draftTexts].filter(([, text]) => text.trim().length > 0).map(([id, text]) => ({ id, text }))
  }

  reset(): TurnEvent[] {
    const events = this.flush()
    this.streamMessageId = null
    this.blockItems.clear()
    this.queues.clear()
    return events
  }

  handle(message: SDKMessage): TurnEvent[] {
    switch (message.type) {
      case 'system':
        return message.subtype === 'init' ? [{ type: 'session', sessionId: message.session_id }, { type: 'turn.start' }] : []
      case 'stream_event':
        return message.parent_tool_use_id === null ? this.stream(message.event) : []
      case 'assistant':
        return message.parent_tool_use_id === null ? this.assistant(message) : []
      case 'user':
        return message.parent_tool_use_id === null ? this.toolResults(message.message.content) : []
      case 'result':
        return [
          ...this.reset(),
          {
            type: 'turn.end',
            ok: !message.is_error,
            error: message.is_error ? (message.subtype === 'success' ? message.result : message.errors.join('\n') || message.subtype) : null,
            more: (message.queued_turn_count ?? 0) > 0,
          },
        ]
      default:
        return []
    }
  }

  private stream(event: Extract<SDKMessage, { type: 'stream_event' }>['event']): TurnEvent[] {
    if (event.type === 'message_start') {
      this.streamMessageId = event.message.id
      this.blockItems.clear()
      return []
    }
    if (event.type === 'content_block_start') {
      if (event.content_block.type !== 'text' || !this.streamMessageId) return []
      const itemId = randomUUID()
      this.blockItems.set(event.index, itemId)
      this.draftTexts.set(itemId, '')
      const queue = this.queues.get(this.streamMessageId) ?? []
      queue.push(itemId)
      this.queues.set(this.streamMessageId, queue)
      return []
    }
    if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
      const itemId = this.blockItems.get(event.index)
      if (!itemId) return []
      const before = this.draftTexts.get(itemId) ?? ''
      const text = before + event.delta.text
      this.draftTexts.set(itemId, text)
      if (text.trim().length === 0) return []
      return [{ type: 'delta', itemId, text: before.trim().length === 0 ? text : event.delta.text }]
    }
    return []
  }

  private assistant(message: Extract<SDKMessage, { type: 'assistant' }>): TurnEvent[] {
    const events: TurnEvent[] = []
    for (const block of message.message.content) {
      if (block.type === 'text') {
        const itemId = this.queues.get(message.message.id)?.shift() ?? randomUUID()
        this.draftTexts.delete(itemId)
        if (block.text.trim().length > 0) events.push({ type: 'text', itemId, text: block.text })
      } else if (block.type === 'tool_use') {
        events.push({ type: 'tool.start', toolUseId: block.id, name: block.name, input: block.input })
      }
    }
    if (message.error) events.push({ type: 'error', text: `Claude reported: ${message.error}` })
    return events
  }

  private toolResults(content: Extract<SDKMessage, { type: 'user' }>['message']['content']): TurnEvent[] {
    if (typeof content === 'string') return []
    const events: TurnEvent[] = []
    for (const block of content) {
      if (block.type !== 'tool_result') continue
      events.push({
        type: 'tool.end',
        toolUseId: block.tool_use_id,
        isError: block.is_error === true,
        result: clip(flattenResult(block.content), maxResultLength),
      })
    }
    return events
  }

  private flush(): TurnEvent[] {
    const events: TurnEvent[] = this.drafts().map((draft) => ({ type: 'text', itemId: draft.id, text: draft.text }))
    this.draftTexts.clear()
    return events
  }
}
