import assert from 'node:assert/strict'
import { test } from 'node:test'
import type { SDKMessage } from '@anthropic-ai/claude-agent-sdk'
import { Translator } from '../src/agents/translate.ts'

const message = (value: unknown) => value as SDKMessage
const stream = (event: unknown) => message({ type: 'stream_event', parent_tool_use_id: null, event })
const assistant = (id: string, content: unknown[]) => message({ type: 'assistant', parent_tool_use_id: null, message: { id, content } })
const result = (extra: object = {}) => message({ type: 'result', subtype: 'success', is_error: false, result: 'done', queued_turn_count: 0, ...extra })

test('init reports the session and the start of a turn', () => {
  const events = new Translator().handle(message({ type: 'system', subtype: 'init', session_id: 's1' }))
  assert.deepEqual(events, [{ type: 'session', sessionId: 's1' }, { type: 'turn.start' }])
})

test('streamed text becomes deltas and then one final item with the same id', () => {
  const translator = new Translator()
  translator.handle(stream({ type: 'message_start', message: { id: 'm1' } }))
  translator.handle(stream({ type: 'content_block_start', index: 0, content_block: { type: 'text' } }))
  const first = translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: 'Hel' } }))
  const second = translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: 'lo' } }))
  assert.equal(first[0]?.type, 'delta')
  assert.equal(second[0]?.type === 'delta' && second[0].text, 'lo')
  assert.deepEqual(translator.drafts().map((draft) => draft.text), ['Hello'])
  const final = translator.handle(assistant('m1', [{ type: 'text', text: 'Hello' }]))
  assert.equal(final[0]?.type, 'text')
  assert.equal(final[0]?.type === 'text' && first[0]?.type === 'delta' && final[0].itemId === first[0].itemId, true)
  assert.deepEqual(translator.drafts(), [])
})

test('a blank block is never streamed and never saved', () => {
  const translator = new Translator()
  translator.handle(stream({ type: 'message_start', message: { id: 'm1' } }))
  translator.handle(stream({ type: 'content_block_start', index: 0, content_block: { type: 'text' } }))
  assert.deepEqual(translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: '\n\n' } })), [])
  assert.deepEqual(translator.drafts(), [])
  assert.deepEqual(translator.handle(assistant('m1', [{ type: 'text', text: '\n\n' }])), [])
})

test('the first visible delta carries the buffered blank prefix', () => {
  const translator = new Translator()
  translator.handle(stream({ type: 'message_start', message: { id: 'm1' } }))
  translator.handle(stream({ type: 'content_block_start', index: 0, content_block: { type: 'text' } }))
  translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: '\n' } }))
  const events = translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: 'Hi' } }))
  assert.equal(events[0]?.type === 'delta' && events[0].text, '\nHi')
})

test('tool calls and their results are reported, subagent traffic is ignored', () => {
  const translator = new Translator()
  const started = translator.handle(assistant('m1', [{ type: 'tool_use', id: 'tool1', name: 'Bash', input: { command: 'ls' } }]))
  assert.deepEqual(started, [{ type: 'tool.start', toolUseId: 'tool1', name: 'Bash', input: { command: 'ls' } }])
  const ended = translator.handle(message({ type: 'user', parent_tool_use_id: null, message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: 'tool1', is_error: true, content: [{ type: 'text', text: 'boom' }] }] } }))
  assert.deepEqual(ended, [{ type: 'tool.end', toolUseId: 'tool1', isError: true, result: 'boom' }])
  assert.deepEqual(translator.handle(message({ type: 'assistant', parent_tool_use_id: 'tool1', message: { id: 'm2', content: [{ type: 'text', text: 'inner' }] } })), [])
})

test('a result ends the turn and flushes an unfinished draft', () => {
  const translator = new Translator()
  translator.handle(stream({ type: 'message_start', message: { id: 'm1' } }))
  translator.handle(stream({ type: 'content_block_start', index: 0, content_block: { type: 'text' } }))
  translator.handle(stream({ type: 'content_block_delta', index: 0, delta: { type: 'text_delta', text: 'partial' } }))
  const events = translator.handle(result())
  assert.equal(events[0]?.type === 'text' && events[0].text, 'partial')
  assert.deepEqual(events[1], { type: 'turn.end', ok: true, error: null, more: false })
})

test('an error result carries its message', () => {
  const events = new Translator().handle(message({ type: 'result', subtype: 'error_during_execution', is_error: true, errors: ['it broke'], queued_turn_count: 0 }))
  assert.deepEqual(events, [{ type: 'turn.end', ok: false, error: 'it broke', more: false }])
})
