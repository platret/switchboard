import { isRecord } from '@switchboard/shared'

const actions: Record<string, string> = {
  Bash: 'run a command',
  Edit: 'edit a file',
  Write: 'write a file',
  NotebookEdit: 'edit a notebook',
  WebFetch: 'fetch a web page',
  WebSearch: 'search the web',
  Read: 'read a file outside the project',
  Glob: 'list files outside the project',
  Grep: 'search files outside the project',
}

export function describeAction(toolName: string): string {
  return actions[toolName] ?? `use ${toolName}`
}

export function textField(input: unknown, key: string): string | null {
  const value = isRecord(input) ? input[key] : null
  return typeof value === 'string' ? value : null
}

export function flag(input: unknown, key: string): boolean {
  return isRecord(input) && input[key] === true
}

export function countdown(remainingMs: number): string {
  const seconds = Math.max(0, Math.ceil(remainingMs / 1000))
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`
}
