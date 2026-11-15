import type { ServerMessage } from '@switchboard/shared'
import { WebSocket } from 'ws'

const heartbeatMs = 15_000

export class Hub {
  private readonly clients = new Map<WebSocket, boolean>()
  private readonly heartbeat = setInterval(() => this.beat(), heartbeatMs)

  add(socket: WebSocket): void {
    this.clients.set(socket, true)
    socket.on('pong', () => this.clients.has(socket) && this.clients.set(socket, true))
    socket.on('close', () => this.clients.delete(socket))
  }

  send(socket: WebSocket, message: ServerMessage): void {
    if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message))
  }

  broadcast(message: ServerMessage): void {
    const payload = JSON.stringify(message)
    for (const socket of this.clients.keys()) {
      if (socket.readyState === WebSocket.OPEN) socket.send(payload)
    }
  }

  close(): void {
    clearInterval(this.heartbeat)
  }

  private beat(): void {
    for (const [socket, alive] of this.clients) {
      if (!alive) {
        socket.terminate()
        continue
      }
      this.clients.set(socket, false)
      socket.ping()
      this.send(socket, { type: 'ping' })
    }
  }
}
