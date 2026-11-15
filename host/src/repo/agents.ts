import { storedAgentSchema, type AgentStatus, type StoredAgent } from '@switchboard/shared'
import type { Db } from '../db.ts'

export type AgentRecord = Omit<StoredAgent, 'lastActivityAt' | 'preview'>
export type AgentPatch = Partial<Pick<AgentRecord, 'name' | 'sessionId' | 'status'>>

const select = `
  SELECT a.*,
    COALESCE((SELECT MAX(m.createdAt) FROM messages m WHERE m.agentId = a.id), a.createdAt) AS lastActivityAt,
    (SELECT substr(json_extract(m.content, '$.text'), 1, 160) FROM messages m
      WHERE m.agentId = a.id AND json_extract(m.content, '$.kind') = 'text'
      ORDER BY m.createdAt DESC, m.rowid DESC LIMIT 1) AS preview
  FROM agents a
`

export function createAgentRepo(db: Db) {
  const all = db.prepare(`${select} ORDER BY a.createdAt`)
  const one = db.prepare(`${select} WHERE a.id = ?`)
  const insert = db.prepare('INSERT INTO agents (id, name, projectId, role, sessionId, status, createdAt) VALUES (@id, @name, @projectId, @role, @sessionId, @status, @createdAt)')
  const update = db.prepare('UPDATE agents SET name = @name, sessionId = @sessionId, status = @status WHERE id = @id')
  const reset = db.prepare('UPDATE agents SET status = ? WHERE status = ?')
  const removeMessages = db.prepare('DELETE FROM messages WHERE agentId = ?')
  const removeAgent = db.prepare('DELETE FROM agents WHERE id = ?')
  const remove = db.transaction((id: string) => {
    removeMessages.run(id)
    removeAgent.run(id)
  })

  const get = (id: string): StoredAgent | undefined => {
    const row = one.get(id)
    return row ? storedAgentSchema.parse(row) : undefined
  }

  return {
    list: (): StoredAgent[] => all.all().map((row) => storedAgentSchema.parse(row)),
    get,
    insert: (agent: AgentRecord): void => void insert.run(agent),
    update: (id: string, patch: AgentPatch): void => {
      const current = get(id)
      if (current) update.run({ id, name: current.name, sessionId: current.sessionId, status: current.status, ...patch })
    },
    remove: (id: string): void => void remove(id),
    resetStatus: (from: AgentStatus, to: AgentStatus): void => void reset.run(to, from),
  }
}

export type AgentRepo = ReturnType<typeof createAgentRepo>
