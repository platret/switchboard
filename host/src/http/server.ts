import { existsSync } from 'node:fs'
import { createServer, type Server } from 'node:http'
import { join } from 'node:path'
import express, { type ErrorRequestHandler, type Router } from 'express'
import { WebSocketServer, type WebSocket } from 'ws'
import { ZodError } from 'zod'
import { NotFoundError } from '../agents/manager.ts'
import type { Auth } from './auth.ts'

export type ServerDeps = {
  api: Router
  auth: Auth
  webDir: string
  onSocket: (socket: WebSocket) => void
}

const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
  if (error instanceof ZodError) return void response.status(400).json({ error: error.issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`).join('. ') })
  const message = error instanceof Error ? error.message : 'Request failed'
  response.status(error instanceof NotFoundError ? 404 : 400).json({ error: message })
}

export function createServers({ api, auth, webDir, onSocket }: ServerDeps, hosts: string[], port: number): Server[] {
  const app = express()
  app.disable('x-powered-by')
  app.use('/api', auth.middleware, api)
  app.use(express.static(webDir))
  app.get('/{*path}', (_request, response) => {
    const index = join(webDir, 'index.html')
    if (existsSync(index)) response.sendFile(index)
    else response.status(503).type('text').send('The web app is still building. Reload in a moment.')
  })
  app.use(errorHandler)

  const sockets = new WebSocketServer({ noServer: true, maxPayload: 1024 * 1024 })
  sockets.on('connection', onSocket)

  return hosts.map((host) => {
    const server = createServer(app)
    server.on('upgrade', (request, socket, head) => {
      if (request.url !== '/ws') return socket.destroy()
      sockets.handleUpgrade(request, socket, head, (client) => sockets.emit('connection', client, request))
    })
    server.on('error', (error) => console.error(`Could not listen on ${host}:${port}. ${error.message}`))
    server.listen(port, host, () => console.log(`Switchboard listening on http://${host}:${port}`))
    return server
  })
}
