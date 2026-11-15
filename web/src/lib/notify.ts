import type { ServerMessage } from '@switchboard/shared'
import { useStore } from './store.ts'

const baseTitle = 'Switchboard'

export const notificationsSupported = 'Notification' in window && window.isSecureContext

function show(title: string, body: string, agentId: string): void {
  const { notifications, agents, openAgent } = useStore.getState()
  if (!notificationsSupported || !notifications || Notification.permission !== 'granted' || document.visibilityState === 'visible') return
  const notification = new Notification(title, { body, tag: agentId, icon: '/icon-192.png' })
  notification.onclick = () => {
    window.focus()
    const agent = agents[agentId]
    if (agent) openAgent(agent)
    notification.close()
  }
}

export function refreshTitle(): void {
  const waiting = useStore.getState().approvals.length
  document.title = waiting > 0 ? `(${waiting}) ${baseTitle}` : baseTitle
}

export function announce(message: ServerMessage, wasBusy: boolean): void {
  const { agents } = useStore.getState()
  if (message.type === 'approval.requested') {
    const name = agents[message.approval.agentId]?.name ?? 'An agent'
    show(`${name} needs your approval`, message.approval.summary || message.approval.toolName, message.approval.agentId)
  }
  if (message.type === 'agent.upserted' && wasBusy && message.agent.status === 'idle') {
    show(`${message.agent.name} is done`, message.agent.preview ?? 'The turn finished.', message.agent.id)
  }
  if (message.type === 'agent.upserted' && wasBusy && message.agent.status === 'error') {
    show(`${message.agent.name} ran into an error`, 'Open Switchboard to see what happened.', message.agent.id)
  }
}

export async function enableNotifications(): Promise<boolean> {
  if (!notificationsSupported) return false
  const permission = Notification.permission === 'default' ? await Notification.requestPermission() : Notification.permission
  return permission === 'granted'
}
