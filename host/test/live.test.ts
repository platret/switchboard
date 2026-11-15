import assert from 'node:assert/strict'
import { test } from 'node:test'
import type { StoredAgent } from '@switchboard/shared'
import { LiveState } from '../src/agents/live.ts'

const stored: StoredAgent = { id: 'a1', name: 'Bob', projectId: 'p', role: 'dev', sessionId: null, status: 'idle', createdAt: 1, lastActivityAt: 2, preview: "I'd start with **Switchboard**.\n\nIt is `new`." }

test('the view adds live fields and a plain text preview', () => {
  const live = new LiveState()
  const view = live.view(stored)
  assert.equal(view.preview, "I'd start with Switchboard. It is new.")
  assert.equal(view.activity, null)
  assert.deepEqual(view.queue, [])
  assert.deepEqual(view.trustedTools, [])
})

test('activity reports whether it changed', () => {
  const live = new LiveState()
  assert.equal(live.setActivity('a1', 'Thinking'), true)
  assert.equal(live.setActivity('a1', 'Thinking'), false)
  assert.equal(live.view(stored).activity, 'Thinking')
  assert.equal(live.setActivity('a1', null), true)
})

test('the queue keeps order, removes single entries and clears', () => {
  const live = new LiveState()
  live.enqueue('a1', 'one')
  live.enqueue('a1', 'two')
  live.enqueue('a1', 'three')
  const [, second] = live.view(stored).queue
  if (second) live.unqueue('a1', second.id)
  assert.equal(live.dequeue('a1')?.text, 'one')
  assert.equal(live.clearQueue('a1'), 1)
  assert.equal(live.dequeue('a1'), undefined)
})

test('turn trust ends with the turn', () => {
  const live = new LiveState()
  live.trust('a1', 'Edit')
  assert.equal(live.trusts('a1', 'Edit'), true)
  assert.equal(live.trusts('a1', 'Write'), false)
  assert.equal(live.trusts('a2', 'Edit'), false)
  live.endTurn('a1')
  assert.equal(live.trusts('a1', 'Edit'), false)
})
