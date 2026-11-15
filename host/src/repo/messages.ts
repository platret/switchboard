import { chatItemSchema, type ChatItem } from '@switchboard/shared'
import type { Db } from '../db.ts'

const historyLimit = 500

type Row = Omit<ChatItem, 'content'> & { content: string }

function toItem(row: unknown): ChatItem {
  const record = row as Row
  return chatItemSchema.parse({ ...record, content: JSON.parse(record.content) })
}

export function createMessageRepo(db: Db) {
  const recent = db.prepare('SELECT * FROM (SELECT rowid AS position, * FROM messages WHERE agentId = ? ORDER BY createdAt DESC, rowid DESC LIMIT ?) ORDER BY createdAt, position')
  const one = db.prepare('SELECT * FROM messages WHERE id = ?')
  const upsert = db.prepare(`
    INSERT INTO messages (id, agentId, role, content, createdAt) VALUES (@id, @agentId, @role, @content, @createdAt)
    ON CONFLICT (id) DO UPDATE SET content = excluded.content
  `)
  const running = db.prepare("SELECT * FROM messages WHERE agentId = ? AND json_extract(content, '$.kind') = 'tool' AND json_extract(content, '$.status') = 'running'")
  const failRunning = db.prepare(`
    UPDATE messages SET content = json_set(content, '$.status', 'error')
    WHERE json_extract(content, '$.kind') = 'tool' AND json_extract(content, '$.status') = 'running'
  `)

  return {
    list: (agentId: string): ChatItem[] => recent.all(agentId, historyLimit).map(toItem),
    get: (id: string): ChatItem | undefined => {
      const row = one.get(id)
      return row ? toItem(row) : undefined
    },
    upsert: (item: ChatItem): void => void upsert.run({ ...item, content: JSON.stringify(item.content) }),
    listRunningTools: (agentId: string): ChatItem[] => running.all(agentId).map(toItem),
    failRunningTools: (): void => void failRunning.run(),
  }
}

export type MessageRepo = ReturnType<typeof createMessageRepo>
