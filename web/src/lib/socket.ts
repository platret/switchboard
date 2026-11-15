import { isBusy, unauthorizedCloseCode, type ClientMessage, type ServerMessage } from '@switchboard/shared'
import { announce, refreshTitle } from './notify.ts'
import { useStore } from './store.ts'

const silenceLimitMs = 35_000
const checkEveryMs = 5_000

let socket: WebSocket | null = null
let retryDelay = 500
let lastSeen = 0
let pending: { agentId: string; text: string } | null = null

function onMessage(message: ServerMessage): void {
  lastSeen = Date.now()
  const store = useStore.getState()
  if (pending && ((message.type === 'agent.upserted' && message.agent.id === pending.agentId) || (message.type === 'chat.item' && message.item.agentId === pending.agentId) || message.type === 'error')) pending = null
  const before = message.type === 'agent.upserted' ? store.agents[message.agent.id] : undefined
  store.apply(message)
  announce(message, before !== undefined && isBusy(before.status))
  refreshTitle()
  if (message.type === 'agent.upserted' && message.agent.id === store.agentId && store.view === 'chat' && document.visibilityState === 'visible') store.markRead(message.agent.id)
  if (message.type !== 'auth.ok') return
  retryDelay = 500
  if (store.agentId) send({ type: 'history.get', agentId: store.agentId })
}

function onClose(closed: WebSocket, code: number): void {
  if (socket !== closed) return
  socket = null
  const store = useStore.getState()
  store.setConnection('closed')
  if (pending) {
    store.setUndelivered(pending)
    store.setNotice('Your last message was not delivered. It is back in the message field.')
    pending = null
  }
  if (code === unauthorizedCloseCode) return store.rejectToken()
  setTimeout(connect, retryDelay)
  retryDelay = Math.min(retryDelay * 2, 8000)
}

function dropIfSilent(): void {
  const current = socket
  if (!current || current.readyState !== WebSocket.OPEN || Date.now() - lastSeen < silenceLimitMs) return
  current.close()
  onClose(current, 0)
}

export function connect(): void {
  const { token, setConnection } = useStore.getState()
  if (socket || !token) return
  const scheme = location.protocol === 'https:' ? 'wss' : 'ws'
  const next = new WebSocket(`${scheme}://${location.host}/ws`)
  socket = next
  lastSeen = Date.now()
  setConnection('connecting')
  next.addEventListener('open', () => next.send(JSON.stringify({ type: 'auth', token } satisfies ClientMessage)))
  next.addEventListener('message', (event) => onMessage(JSON.parse(String(event.data)) as ServerMessage))
  next.addEventListener('close', (event) => onClose(next, event.code))
}

export function disconnect(): void {
  const current = socket
  socket = null
  pending = null
  current?.close()
}

export function send(message: ClientMessage): boolean {
  if (socket?.readyState !== WebSocket.OPEN || useStore.getState().connection !== 'open') return false
  socket.send(JSON.stringify(message))
  if (message.type === 'chat.send') pending = { agentId: message.agentId, text: message.text }
  return true
}

export function sendOrWarn(message: ClientMessage): boolean {
  const sent = send(message)
  if (!sent) useStore.getState().setNotice('Not connected to the host. Reconnecting.')
  return sent
}

setInterval(dropIfSilent, checkEveryMs)
document.addEventListener('visibilitychange', () => document.visibilityState === 'visible' && dropIfSilent())
