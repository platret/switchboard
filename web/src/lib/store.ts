import type { Agent, Approval, ChatDraft, ChatItem, Project, Role, ServerMessage } from '@switchboard/shared'
import { create } from 'zustand'
import { load, save } from './persist.ts'
import { applyTheme, type Theme } from './theme.ts'
import { forgetToken, initialToken, saveToken } from './token.ts'

export type Connection = 'connecting' | 'open' | 'closed'
export type View = 'chat' | 'overview'

type State = {
  token: string | null
  tokenRejected: boolean
  connection: Connection
  ready: boolean
  projects: Project[]
  roles: Role[]
  agents: Record<string, Agent>
  items: Record<string, ChatItem[]>
  drafts: Record<string, ChatDraft[]>
  approvals: Approval[]
  approvalsChangedAt: number
  tailscaleUrl: string | null
  projectId: string | null
  agentId: string | null
  view: View
  notice: string | null
  undelivered: { agentId: string; text: string } | null
  lastRead: Record<string, number>
  theme: Theme
  voiceLanguage: string
  notifications: boolean
  paletteOpen: boolean
  settingsOpen: boolean
  creatingAgent: boolean
  setToken: (token: string) => void
  rejectToken: () => void
  signOut: () => void
  setConnection: (connection: Connection) => void
  apply: (message: ServerMessage) => void
  selectProject: (projectId: string) => void
  selectAgent: (agentId: string | null) => void
  openAgent: (agent: Agent) => void
  markRead: (agentId: string) => void
  setView: (view: View) => void
  setNotice: (notice: string | null) => void
  setUndelivered: (undelivered: { agentId: string; text: string } | null) => void
  setTheme: (theme: Theme) => void
  setVoiceLanguage: (language: string) => void
  setNotifications: (enabled: boolean) => void
  setPaletteOpen: (open: boolean) => void
  setSettingsOpen: (open: boolean) => void
  setCreatingAgent: (open: boolean) => void
}

const keys = {
  project: 'switchboard.project',
  agent: 'switchboard.agent',
  lastRead: 'switchboard.lastRead',
  theme: 'switchboard.theme',
  voiceLanguage: 'switchboard.voiceLanguage',
  notifications: 'switchboard.notifications',
}

function upsert<T extends { id: string }>(list: T[], next: T): T[] {
  const index = list.findIndex((entry) => entry.id === next.id)
  if (index === -1) return [...list, next]
  return list.map((entry, position) => (position === index ? next : entry))
}

function seedRead(state: State, agents: Agent[]): Record<string, number> {
  if (Object.keys(state.lastRead).length > 0) return state.lastRead
  const seeded = Object.fromEntries(agents.map((agent) => [agent.id, agent.lastActivityAt]))
  save(keys.lastRead, seeded)
  return seeded
}

function restoreSelection(state: State, agents: Agent[], projectId: string | null): Pick<State, 'agentId' | 'projectId'> {
  const wanted = state.agentId ?? load<string | null>(keys.agent, null)
  const agent = agents.find((candidate) => candidate.id === wanted)
  if (!agent) return { agentId: null, projectId }
  return { agentId: agent.id, projectId: state.ready ? projectId : agent.projectId }
}

function reduce(state: State, message: ServerMessage): Partial<State> {
  switch (message.type) {
    case 'auth.ok':
      return { connection: 'open' }
    case 'ping':
      return {}
    case 'bootstrap': {
      const { projects, roles, agents, approvals, host } = message.bootstrap
      const known = projects.some((project) => project.id === state.projectId)
      return {
        ready: true,
        approvalsChangedAt: Date.now(),
        projects,
        roles,
        approvals,
        tailscaleUrl: host.tailscaleUrl,
        agents: Object.fromEntries(agents.map((agent) => [agent.id, agent])),
        ...restoreSelection(state, agents, known ? state.projectId : (projects[0]?.id ?? null)),
        lastRead: seedRead(state, agents),
      }
    }
    case 'history':
      return {
        items: { ...state.items, [message.agentId]: message.history.items },
        drafts: { ...state.drafts, [message.agentId]: message.history.drafts },
      }
    case 'agent.upserted':
      return { agents: { ...state.agents, [message.agent.id]: message.agent } }
    case 'agent.removed': {
      const { [message.agentId]: _removed, ...agents } = state.agents
      return { agents, agentId: state.agentId === message.agentId ? null : state.agentId }
    }
    case 'chat.delta': {
      const drafts = state.drafts[message.agentId] ?? []
      const current = drafts.find((draft) => draft.id === message.itemId)
      const next = { id: message.itemId, text: (current?.text ?? '') + message.text }
      return { drafts: { ...state.drafts, [message.agentId]: upsert(drafts, next) } }
    }
    case 'chat.item': {
      const { agentId, id } = message.item
      return {
        items: { ...state.items, [agentId]: upsert(state.items[agentId] ?? [], message.item) },
        drafts: { ...state.drafts, [agentId]: (state.drafts[agentId] ?? []).filter((draft) => draft.id !== id) },
      }
    }
    case 'approval.requested':
      return { approvals: upsert(state.approvals, message.approval), approvalsChangedAt: Date.now() }
    case 'approval.resolved':
      return { approvals: state.approvals.filter((approval) => approval.id !== message.approvalId), approvalsChangedAt: Date.now() }
    case 'error':
      return { notice: message.message }
  }
}

function leaveChat(state: State): void {
  if (state.agentId && state.view === 'chat') state.markRead(state.agentId)
}

const initialTheme = load<Theme>(keys.theme, 'system')
applyTheme(initialTheme)

export const useStore = create<State>((set, get) => ({
  token: initialToken(),
  tokenRejected: false,
  connection: 'connecting',
  ready: false,
  projects: [],
  roles: [],
  agents: {},
  items: {},
  drafts: {},
  approvals: [],
  approvalsChangedAt: 0,
  tailscaleUrl: null,
  projectId: load<string | null>(keys.project, null),
  agentId: null,
  view: 'chat',
  notice: null,
  undelivered: null,
  lastRead: load<Record<string, number>>(keys.lastRead, {}),
  theme: initialTheme,
  voiceLanguage: load<string>(keys.voiceLanguage, ''),
  notifications: load<boolean>(keys.notifications, false),
  paletteOpen: false,
  settingsOpen: false,
  creatingAgent: false,
  setToken: (token) => {
    saveToken(token)
    set({ token, tokenRejected: false })
  },
  rejectToken: () => {
    forgetToken()
    set({ token: null, tokenRejected: true, ready: false })
  },
  signOut: () => {
    forgetToken()
    set({ token: null, tokenRejected: false, ready: false, settingsOpen: false })
  },
  setConnection: (connection) => set({ connection }),
  apply: (message) => set((state) => reduce(state, message)),
  selectProject: (projectId) => {
    leaveChat(get())
    save(keys.project, projectId)
    save(keys.agent, null)
    set({ projectId, agentId: null, view: 'chat' })
  },
  selectAgent: (agentId) => {
    leaveChat(get())
    save(keys.agent, agentId)
    set({ agentId, view: 'chat' })
    if (agentId) get().markRead(agentId)
  },
  openAgent: (agent) => {
    leaveChat(get())
    save(keys.project, agent.projectId)
    save(keys.agent, agent.id)
    set({ projectId: agent.projectId, agentId: agent.id, view: 'chat', paletteOpen: false })
    get().markRead(agent.id)
  },
  markRead: (agentId) => {
    const seen = Math.max(Date.now(), get().agents[agentId]?.lastActivityAt ?? 0)
    const lastRead = { ...get().lastRead, [agentId]: seen }
    save(keys.lastRead, lastRead)
    set({ lastRead })
  },
  setView: (view) => {
    leaveChat(get())
    set({ view })
  },
  setNotice: (notice) => set({ notice }),
  setUndelivered: (undelivered) => set({ undelivered }),
  setTheme: (theme) => {
    save(keys.theme, theme)
    applyTheme(theme)
    set({ theme })
  },
  setVoiceLanguage: (voiceLanguage) => {
    save(keys.voiceLanguage, voiceLanguage)
    set({ voiceLanguage })
  },
  setNotifications: (notifications) => {
    save(keys.notifications, notifications)
    set({ notifications })
  },
  setPaletteOpen: (paletteOpen) => set({ paletteOpen }),
  setSettingsOpen: (settingsOpen) => set({ settingsOpen }),
  setCreatingAgent: (creatingAgent) => set({ creatingAgent }),
}))

export function isUnread(agent: Agent, lastRead: Record<string, number>, openAgentId: string | null): boolean {
  if (agent.id === openAgentId || agent.preview === null) return false
  return agent.lastActivityAt > (lastRead[agent.id] ?? 0)
}
