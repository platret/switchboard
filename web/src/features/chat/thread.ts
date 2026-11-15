import type { ChatItem } from '@switchboard/shared'
import type { Tool } from './ToolRow.tsx'

export type ThreadEntry = { type: 'item'; id: string; item: ChatItem; closesTurn: boolean } | { type: 'tools'; id: string; tools: Tool[] }

export function buildThread(items: ChatItem[]): ThreadEntry[] {
  const entries: ThreadEntry[] = []
  for (const item of items) {
    const last = entries[entries.length - 1]
    if (item.content.kind !== 'tool') entries.push({ type: 'item', id: item.id, item, closesTurn: false })
    else if (last?.type === 'tools') last.tools.push(item.content)
    else entries.push({ type: 'tools', id: item.id, tools: [item.content] })
  }
  entries.forEach((entry, index) => {
    const next = entries[index + 1]
    if (entry.type === 'item' && entry.item.role === 'assistant') entry.closesTurn = next === undefined || (next.type === 'item' && next.item.role !== 'assistant')
  })
  return entries
}
