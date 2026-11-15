import { createHash, timingSafeEqual } from 'node:crypto'
import type { RequestHandler } from 'express'

function digest(value: string): Buffer {
  return createHash('sha256').update(value).digest()
}

export type Auth = {
  matches: (candidate: string) => boolean
  middleware: RequestHandler
}

export function createAuth(token: string): Auth {
  const expected = digest(token)
  const matches = (candidate: string) => timingSafeEqual(digest(candidate), expected)
  const middleware: RequestHandler = (request, response, next) => {
    const [scheme, value] = (request.get('authorization') ?? '').split(' ')
    if (scheme === 'Bearer' && value && matches(value)) return next()
    response.status(401).json({ error: 'Missing or wrong access token' })
  }
  return { matches, middleware }
}
