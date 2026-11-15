import type { Agent, CreateAgentInput } from '@switchboard/shared'
import { useStore } from './store.ts'

async function request<T>(path: string, init: RequestInit): Promise<T> {
  const { token, rejectToken } = useStore.getState()
  const response = await fetch(`/api${path}`, {
    ...init,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token ?? ''}`, ...init.headers },
  })
  if (response.status === 401) rejectToken()
  const body: unknown = await response.json().catch(() => null)
  if (!response.ok || body === null) {
    const message = typeof body === 'object' && body !== null && 'error' in body ? String(body.error) : `Request failed (${response.status})`
    throw new Error(message)
  }
  return body as T
}

export const api = {
  createAgent: (input: CreateAgentInput) => request<Agent>('/agents', { method: 'POST', body: JSON.stringify(input) }),
  renameAgent: (agentId: string, name: string) => request<Agent>(`/agents/${agentId}`, { method: 'PATCH', body: JSON.stringify({ name }) }),
  deleteAgent: (agentId: string) => request<{ ok: boolean }>(`/agents/${agentId}`, { method: 'DELETE' }),
}
