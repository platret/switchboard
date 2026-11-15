import Database from 'better-sqlite3'

export type Db = Database.Database

const schema = `
  CREATE TABLE IF NOT EXISTS agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    projectId TEXT NOT NULL,
    role TEXT NOT NULL,
    sessionId TEXT,
    status TEXT NOT NULL,
    createdAt INTEGER NOT NULL
  );
  CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    agentId TEXT NOT NULL REFERENCES agents(id),
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    createdAt INTEGER NOT NULL
  );
  CREATE INDEX IF NOT EXISTS messages_by_agent ON messages (agentId, createdAt);
`

export function openDb(file: string): Db {
  const db = new Database(file)
  db.pragma('journal_mode = WAL')
  db.pragma('foreign_keys = ON')
  db.exec(schema)
  return db
}
