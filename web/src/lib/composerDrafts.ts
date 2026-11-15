const drafts = new Map<string, string>()

export function readDraft(agentId: string): string {
  return drafts.get(agentId) ?? ''
}

export function writeDraft(agentId: string, text: string): void {
  if (text.length > 0) drafts.set(agentId, text)
  else drafts.delete(agentId)
}
