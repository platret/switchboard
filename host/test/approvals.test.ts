import assert from 'node:assert/strict'
import { test } from 'node:test'
import type { Approval, ApprovalDecision, ApprovalSource } from '@switchboard/shared'
import { ApprovalBroker } from '../src/agents/approvals.ts'

type Resolved = { id: string; decision: ApprovalDecision; by: ApprovalSource }

function setup(timeoutMs = 60_000) {
  const requested: Approval[] = []
  const resolved: Resolved[] = []
  const broker = new ApprovalBroker(
    { onRequested: (approval) => requested.push(approval), onResolved: (approval, decision, by) => resolved.push({ id: approval.id, decision, by }) },
    timeoutMs,
  )
  const request = (id: string, agentId = 'a1', signal = new AbortController().signal) => broker.request({ id, agentId, toolName: 'Bash', summary: 'ls', input: { command: 'ls' }, turnTrust: false }, signal)
  return { broker, requested, resolved, request }
}

test('a request waits until the user allows it', async () => {
  const { broker, requested, resolved, request } = setup()
  const pending = request('t1')
  assert.equal(requested.length, 1)
  assert.equal(broker.list().length, 1)
  broker.respond('t1', 'allow')
  assert.equal(await pending, 'allow')
  assert.deepEqual(resolved, [{ id: 't1', decision: 'allow', by: 'user' }])
  assert.equal(broker.list().length, 0)
})

test('the same tool call is only asked once and keeps its answer', async () => {
  const { broker, requested, request } = setup()
  const first = request('t1')
  const second = request('t1')
  assert.equal(requested.length, 1)
  broker.respond('t1', 'deny')
  assert.equal(await first, 'deny')
  assert.equal(await second, 'deny')
  assert.equal(await request('t1'), 'deny')
  assert.equal(requested.length, 1)
})

test('an unanswered request is denied after the timeout', async () => {
  const { resolved, request } = setup(15)
  assert.equal(await request('t1'), 'deny')
  assert.equal(resolved[0]?.by, 'timeout')
})

test('stopping an agent denies only its own requests', async () => {
  const { broker, resolved, request } = setup()
  const mine = request('t1', 'a1')
  const other = request('t2', 'a2')
  broker.denyAgent('a1')
  assert.equal(await mine, 'deny')
  assert.deepEqual(resolved, [{ id: 't1', decision: 'deny', by: 'stop' }])
  assert.equal(broker.hasPending('a2'), true)
  broker.respond('t2', 'allow')
  assert.equal(await other, 'allow')
})

test('an aborted call is denied', async () => {
  const { resolved, request } = setup()
  const controller = new AbortController()
  const pending = request('t1', 'a1', controller.signal)
  controller.abort()
  assert.equal(await pending, 'deny')
  assert.equal(resolved[0]?.by, 'stop')
  const already = new AbortController()
  already.abort()
  assert.equal(await request('t2', 'a1', already.signal), 'deny')
})

test('answering twice is rejected', () => {
  const { broker, request } = setup()
  void request('t1')
  broker.respond('t1', 'allow')
  assert.throws(() => broker.respond('t1', 'deny'), /already answered/)
  assert.throws(() => broker.respond('missing', 'allow'), /already answered/)
})
