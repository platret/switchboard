import { createAgentSchema, renameAgentSchema } from '@switchboard/shared'
import express, { Router, type Request, type Response } from 'express'
import type { AgentManager } from '../agents/manager.ts'

export type RouteDeps = {
  manager: AgentManager
}

type AgentParams = { id: string }

export function createRoutes({ manager }: RouteDeps): Router {
  const router = Router()
  router.use(express.json({ limit: '1mb' }))

  router.post('/agents', (request: Request, response: Response) => {
    response.status(201).json(manager.create(createAgentSchema.parse(request.body)))
  })

  router.delete('/agents/:id', (request: Request<AgentParams>, response: Response) => {
    manager.remove(request.params.id)
    response.json({ ok: true })
  })

  router.patch('/agents/:id', (request: Request<AgentParams>, response: Response) => {
    response.json(manager.rename(request.params.id, renameAgentSchema.parse(request.body).name))
  })

  return router
}
