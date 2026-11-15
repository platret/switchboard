import { AgentManager } from './agents/manager.ts'
import { loadConfig } from './config.ts'
import { openDb } from './db.ts'
import { createAuth } from './http/auth.ts'
import { createRoutes } from './http/routes.ts'
import { createServers } from './http/server.ts'
import { createAgentRepo } from './repo/agents.ts'
import { createMessageRepo } from './repo/messages.ts'
import { attachClient } from './ws/handlers.ts'
import { Hub } from './ws/hub.ts'

const config = loadConfig()
const db = openDb(config.databaseFile)
const hub = new Hub()
const auth = createAuth(config.token)
const manager = new AgentManager({ agents: createAgentRepo(db), messages: createMessageRepo(db), hub, config })
const hosts = ['127.0.0.1', ...(config.tailscaleAddress ? [config.tailscaleAddress] : [])]
if (!config.tailscaleAddress) console.log('No Tailscale address found. Listening on this Mac only. Start Tailscale and restart to reach Switchboard from your phone.')

const servers = createServers(
  { api: createRoutes({ manager }), auth, webDir: config.webDir, onSocket: (socket) => attachClient(socket, { hub, manager, auth }) },
  hosts,
  config.port,
)

function shutdown(): void {
  manager.shutdown()
  hub.close()
  for (const server of servers) server.close()
  db.close()
  process.exit(0)
}

process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)
