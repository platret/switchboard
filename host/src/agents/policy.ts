import { existsSync, realpathSync } from 'node:fs'
import { homedir } from 'node:os'
import { basename, dirname, isAbsolute, join, resolve, sep } from 'node:path'
import { isRecord, turnTrustTools } from '@switchboard/shared'

const readOnlyTools = new Set(['Read', 'Glob', 'Grep'])
const bookkeepingTools = new Set(['TodoWrite', 'ToolSearch', 'Skill', 'Agent', 'Task', 'TaskCreate', 'TaskGet', 'TaskList', 'TaskUpdate'])

function text(input: Record<string, unknown>, key: string): string | null {
  const value = input[key]
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null
}

function leavesProject(value: string): boolean {
  return isAbsolute(value) || value.startsWith('~')
}

function absolute(cwd: string, value: string): string {
  if (value === '~') return homedir()
  if (value.startsWith('~/')) return join(homedir(), value.slice(2))
  return isAbsolute(value) ? resolve(value) : resolve(cwd, value)
}

function isInside(roots: string[], path: string): boolean {
  return roots.some((root) => path === root || path.startsWith(root + sep))
}

function readsOutside(input: Record<string, unknown>, roots: string[]): boolean {
  const [cwd] = roots
  if (cwd === undefined) return true
  const pattern = text(input, 'pattern')
  const targets = [text(input, 'file_path'), text(input, 'path'), pattern !== null && leavesProject(pattern) ? pattern : null]
  return targets.some((target) => target !== null && !isInside(roots, absolute(cwd, target)))
}

function touchesSecret(input: Record<string, unknown>, roots: string[], secrets: string[]): boolean {
  const [cwd] = roots
  const target = text(input, 'file_path') ?? text(input, 'path')
  if (cwd === undefined || target === null) return false
  const path = absolute(cwd, target)
  return secrets.some((secret) => path === secret || path.startsWith(secret + sep))
}

const controlFolders = ['.claude', '.git']
const controlFiles = ['.mcp.json']

export function canonical(path: string): string {
  if (existsSync(path)) return realpathSync.native(path)
  const parent = dirname(path)
  return parent === path ? path : join(canonical(parent), basename(path))
}

function controlsExecution(path: string): boolean {
  return path.split(sep).some((segment) => controlFolders.includes(segment)) || controlFiles.includes(basename(path))
}

export function isProjectEdit(toolName: string, input: unknown, roots: string[], excluded: string[]): boolean {
  const [cwd] = roots
  if (!turnTrustTools.includes(toolName) || !isRecord(input) || cwd === undefined) return false
  const target = toolName === 'NotebookEdit' ? text(input, 'notebook_path') : text(input, 'file_path')
  if (target === null) return false
  const path = canonical(absolute(cwd, target))
  return isInside(roots, path) && !isInside(excluded, path) && !controlsExecution(path)
}

export function needsApproval(toolName: string, input: unknown, roots: string[], secrets: string[]): boolean {
  if (!isRecord(input)) return true
  if (toolName === 'Agent' || toolName === 'Task') return 'isolation' in input
  if (bookkeepingTools.has(toolName)) return false
  if (readOnlyTools.has(toolName)) return readsOutside(input, roots) || touchesSecret(input, roots, secrets)
  return true
}
