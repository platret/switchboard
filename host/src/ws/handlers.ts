import { clientMessageSchema, unauthorizedCloseCode, type ParsedClientMessage } from '@switchboard/shared'
import type { WebSocket } from 'ws'
import type { AgentManager } from '../agents/manager.ts'
import type { Auth } from '../http/auth.ts'
import type { Hub } from './hub.ts'

export type HandlerDeps = {
  hub: Hub
  manager: AgentManager
  auth: Auth
}

const authTimeoutMs = 5000
const authTimeoutCode = 4408

function dispatch(socket: WebSocket, message: ParsedClientMessage, { hub, manager }: HandlerDeps): Promise<void> | void {
  switch (message.type) {
    case 'auth':
      return
    case 'history.get':
      return hub.send(socket, { type: 'history', agentId: message.agentId, history: manager.history(message.agentId) })
    case 'chat.send':
      return manager.send(message.agentId, message.text)
    case 'agent.stop':
      return manager.stop(message.agentId)
    case 'queue.remove':
      return manager.unqueue(message.agentId, message.id)
    case 'approval.respond':
      return manager.respond(message.approvalId, message.decision, message.scope)
  }
}

function parse(raw: string): ParsedClientMessage | null {
  try {
    const parsed = clientMessageSchema.safeParse(JSON.parse(raw))
    return parsed.success ? parsed.data : null
  } catch {
    return null
  }
}

export function attachClient(socket: WebSocket, deps: HandlerDeps): void {
  let authenticated = false
  const timer = setTimeout(() => socket.close(authTimeoutCode, 'Authentication timed out'), authTimeoutMs)

  const authenticate = (message: ParsedClientMessage | null): void => {
    if (message?.type !== 'auth' || !deps.auth.matches(message.token)) return socket.close(unauthorizedCloseCode, 'Wrong access token')
    authenticated = true
    clearTimeout(timer)
    deps.hub.add(socket)
    deps.hub.send(socket, { type: 'auth.ok' })
    deps.hub.send(socket, { type: 'bootstrap', bootstrap: deps.manager.bootstrap() })
  }

  const handle = async (message: ParsedClientMessage | null): Promise<void> => {
    try {
      if (!message) throw new Error('Invalid message')
      await dispatch(socket, message, deps)
    } catch (cause) {
      deps.hub.send(socket, { type: 'error', message: cause instanceof Error ? cause.message : 'Request failed' })
    }
  }

  socket.on('error', () => socket.terminate())
  socket.on('close', () => clearTimeout(timer))
  socket.on('message', (raw) => {
    const message = parse(raw.toString())
    if (authenticated) void handle(message)
    else authenticate(message)
  })
}
