import { isRecord } from '@switchboard/shared'

const summaryKeys = ['command', 'file_path', 'notebook_path', 'pattern', 'url', 'query', 'description', 'prompt', 'skill', 'path']

function relativeTo(roots: string[], value: string): string {
  const root = roots.find((candidate) => value.startsWith(`${candidate}/`))
  return root ? value.slice(root.length + 1) : value
}

export function summarizeTool(input: unknown, roots: string[] = []): string {
  if (!isRecord(input)) return ''
  for (const key of summaryKeys) {
    const value = input[key]
    if (typeof value === 'string' && value.length > 0) return clip(relativeTo(roots, value).replace(/\s+/g, ' '), 160)
  }
  return ''
}

export function clip(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max - 1)}…` : text
}

export function flattenResult(content: unknown): string {
  if (typeof content === 'string') return content
  if (!Array.isArray(content)) return ''
  return content
    .map((part) => (isRecord(part) && typeof part.text === 'string' ? part.text : ''))
    .filter((text) => text.length > 0)
    .join('\n')
}
