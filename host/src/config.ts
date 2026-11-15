import { randomBytes } from 'node:crypto'
import { appendFileSync, chmodSync, copyFileSync, existsSync, mkdirSync, readFileSync, realpathSync, statSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { projectSchema, roleSchema, type Project, type Role } from '@switchboard/shared'
import { z } from 'zod'
import { findTailscaleAddress, isTailscaleAddress } from './net/tailscale.ts'

export const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

const settingSourceSchema = z.enum(['user', 'project', 'local'])

const envSchema = z.object({
  SWITCHBOARD_TOKEN: z.string().min(24, 'SWITCHBOARD_TOKEN in .env must be at least 24 characters'),
  SWITCHBOARD_TAILSCALE_IP: z.ipv4().refine(isTailscaleAddress, 'SWITCHBOARD_TAILSCALE_IP must be a Tailscale address in 100.64.0.0/10').optional(),
  SWITCHBOARD_DATA_DIR: z.string().min(1).optional(),
  SWITCHBOARD_PORT: z.coerce.number().int().min(1).max(65535).default(4317),
  SWITCHBOARD_APPROVAL_TIMEOUT_SECONDS: z.coerce.number().int().min(1).max(600).default(600),
  SWITCHBOARD_SETTING_SOURCES: z
    .string()
    .default('user,project,local')
    .transform((value) => value.split(',').map((source) => source.trim()).filter(Boolean))
    .pipe(z.array(settingSourceSchema)),
})

function expandHome(path: string): string {
  return resolve(path === '~' || path.startsWith('~/') ? join(homedir(), path.slice(1)) : path)
}

function readJson(name: string): unknown {
  const file = join(rootDir, name)
  if (!existsSync(file)) throw new Error(`${name} is missing in ${rootDir}`)
  return JSON.parse(readFileSync(file, 'utf8'))
}

function isDirectory(path: string): boolean {
  return existsSync(path) && statSync(path).isDirectory()
}

function assertUniqueIds(file: string, entries: { id: string }[]): void {
  const repeated = entries.find((entry, index) => entries.findIndex((other) => other.id === entry.id) !== index)
  if (repeated) throw new Error(`${file}: id "${repeated.id}" is used more than once`)
}

function ensureProjectsFile(): void {
  const file = join(rootDir, 'projects.json')
  if (existsSync(file)) return
  copyFileSync(join(rootDir, 'projects.example.json'), file)
  console.log(`Created ${file} from projects.example.json. Edit it so it lists your own project folders.`)
}

function hasFolders(project: Project): boolean {
  const missing = [project.path, ...project.additionalDirectories].find((directory) => !isDirectory(directory))
  if (missing) console.warn(`projects.json: skipping project "${project.id}" because the folder ${missing} does not exist`)
  return !missing
}

function loadProjects(roles: Role[]): Project[] {
  ensureProjectsFile()
  const listed = z.array(projectSchema).parse(readJson('projects.json'))
  assertUniqueIds('projects.json', listed)
  for (const project of listed) {
    for (const role of project.agents) {
      if (!roles.some((candidate) => candidate.id === role)) throw new Error(`projects.json: project "${project.id}" lists unknown role "${role}"`)
    }
  }
  const projects = listed
    .map((project) => ({ ...project, path: expandHome(project.path), additionalDirectories: project.additionalDirectories.map(expandHome) }))
    .filter(hasFolders)
    .map((project) => ({
      ...project,
      path: realpathSync.native(project.path),
      additionalDirectories: project.additionalDirectories.map((directory) => realpathSync.native(directory)),
    }))
  if (projects.length === 0) console.warn('No project is available. Edit projects.json so it lists folders that exist on this Mac.')
  return projects
}

function ensureToken(envFile: string): void {
  if (process.env.SWITCHBOARD_TOKEN) return
  const token = randomBytes(32).toString('base64url')
  appendFileSync(envFile, `\nSWITCHBOARD_TOKEN=${token}\n`, { mode: 0o600 })
  chmodSync(envFile, 0o600)
  process.env.SWITCHBOARD_TOKEN = token
  console.log(`Created a new access token in ${envFile}`)
}

export type Config = {
  port: number
  token: string
  tailscaleAddress: string | null
  approvalTimeoutMs: number
  settingSources: z.infer<typeof settingSourceSchema>[]
  webDir: string
  databaseFile: string
  protectedPaths: string[]
  secretPaths: string[]
  trustExcluded: string[]
  projects: Project[]
  roles: Role[]
}

export function loadConfig(): Config {
  const envFile = join(rootDir, '.env')
  if (existsSync(envFile)) process.loadEnvFile(envFile)
  ensureToken(envFile)
  const env = envSchema.parse(process.env)
  const roles = z.array(roleSchema).parse(readJson('roles.json'))
  assertUniqueIds('roles.json', roles)
  const dataDir = env.SWITCHBOARD_DATA_DIR ? expandHome(env.SWITCHBOARD_DATA_DIR) : join(rootDir, 'data.nosync')
  mkdirSync(dataDir, { recursive: true })
  return {
    port: env.SWITCHBOARD_PORT,
    token: env.SWITCHBOARD_TOKEN,
    tailscaleAddress: env.SWITCHBOARD_TAILSCALE_IP ?? findTailscaleAddress(),
    approvalTimeoutMs: env.SWITCHBOARD_APPROVAL_TIMEOUT_SECONDS * 1000,
    settingSources: env.SWITCHBOARD_SETTING_SOURCES,
    webDir: join(rootDir, 'web/dist'),
    databaseFile: join(dataDir, 'switchboard.db'),
    protectedPaths: [envFile, `${envFile}.*`, `${dataDir}/**`],
    secretPaths: [envFile, dataDir],
    trustExcluded: [realpathSync.native(rootDir), realpathSync.native(dataDir)],
    projects: loadProjects(roles),
    roles,
  }
}
