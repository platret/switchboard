import { randomBytes } from 'node:crypto'
import { accessSync, appendFileSync, chmodSync, constants, copyFileSync, existsSync, mkdirSync, readFileSync, realpathSync, statSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { parseEnv } from 'node:util'
import { projectSchema, roleSchema, type Project, type Role } from '@switchboard/shared'
import { z } from 'zod'
import { findTailscaleAddress, isTailscaleAddress } from './net/tailscale.ts'

export const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

type Env = Record<string, string | undefined>

const settingSourceSchema = z.enum(['user', 'project', 'local'])

export function expandHome(path: string): string {
  return resolve(path === '~' || path.startsWith('~/') ? join(homedir(), path.slice(1)) : path)
}

function isFile(path: string): boolean {
  return existsSync(path) && statSync(path).isFile()
}

function isDirectory(path: string): boolean {
  return existsSync(path) && statSync(path).isDirectory()
}

function isExecutableFile(path: string): boolean {
  try {
    accessSync(path, constants.X_OK)
    return statSync(path).isFile()
  } catch {
    return false
  }
}

/** `off` keeps the host on 127.0.0.1 only, for test runs and for Macs that should not be reachable over the tailnet. */
export const tailscaleOff = 'off'

const envSchema = z.object({
  SWITCHBOARD_TOKEN: z.string().min(24, 'SWITCHBOARD_TOKEN in .env must be at least 24 characters'),
  SWITCHBOARD_TAILSCALE_IP: z
    .union([
      z.literal(tailscaleOff),
      z.ipv4().refine(isTailscaleAddress, `SWITCHBOARD_TAILSCALE_IP must be "${tailscaleOff}" or a Tailscale address in 100.64.0.0/10`),
    ])
    .optional(),
  SWITCHBOARD_DATA_DIR: z.string().min(1).optional(),
  SWITCHBOARD_CLAUDE_PATH: z
    .string()
    .min(1)
    .transform(expandHome)
    .refine(isExecutableFile, 'SWITCHBOARD_CLAUDE_PATH must point to an existing claude executable file')
    .optional(),
  SWITCHBOARD_PORT: z.coerce.number().int().min(1).max(65535).default(4317),
  SWITCHBOARD_APPROVAL_TIMEOUT_SECONDS: z.coerce.number().int().min(1).max(600).default(600),
  SWITCHBOARD_SETTING_SOURCES: z
    .string()
    .default('user,project,local')
    .transform((value) => value.split(',').map((source) => source.trim()).filter(Boolean))
    .pipe(z.array(settingSourceSchema)),
})

/**
 * Where the host keeps its writable files. Without SWITCHBOARD_HOME everything lives in the repo
 * (rootDir), exactly as before. With it, the token, settings, projects, an optional roles override
 * and the database live in that folder, and only code-side files come from rootDir.
 */
export type HostPaths = {
  rootDir: string
  homeDir: string
  homeIsSet: boolean
  envFile: string
  projectsFile: string
  rolesFile: string
  defaultDataDir: string
}

export function resolveHostPaths(env: Env, root: string): HostPaths {
  const configured = env.SWITCHBOARD_HOME?.trim()
  const homeIsSet = Boolean(configured)
  const homeDir = configured ? expandHome(configured) : root
  const homeRoles = join(homeDir, 'roles.json')
  return {
    rootDir: root,
    homeDir,
    homeIsSet,
    envFile: join(homeDir, '.env'),
    projectsFile: join(homeDir, 'projects.json'),
    rolesFile: homeIsSet && isFile(homeRoles) ? homeRoles : join(root, 'roles.json'),
    defaultDataDir: homeIsSet ? join(homeDir, 'data') : join(root, 'data.nosync'),
  }
}

function readJson(file: string): unknown {
  if (!existsSync(file)) throw new Error(`${file} is missing`)
  return JSON.parse(readFileSync(file, 'utf8'))
}

function assertUniqueIds(file: string, entries: { id: string }[]): void {
  const repeated = entries.find((entry, index) => entries.findIndex((other) => other.id === entry.id) !== index)
  if (repeated) throw new Error(`${file}: id "${repeated.id}" is used more than once`)
}

function ensureHome(paths: HostPaths): void {
  if (!paths.homeIsSet || isDirectory(paths.homeDir)) return
  mkdirSync(paths.homeDir, { recursive: true, mode: 0o700 })
}

function ensureProjectsFile(paths: HostPaths): void {
  const file = paths.projectsFile
  if (existsSync(file)) return
  if (paths.homeIsSet) {
    writeFileSync(file, '[]\n')
    console.log(`Created an empty ${file}. Add your project folders to it.`)
    return
  }
  copyFileSync(join(paths.rootDir, 'projects.example.json'), file)
  console.log(`Created ${file} from projects.example.json. Edit it so it lists your own project folders.`)
}

function hasFolders(project: Project): boolean {
  const missing = [project.path, ...project.additionalDirectories].find((directory) => !isDirectory(directory))
  if (missing) console.warn(`projects.json: skipping project "${project.id}" because the folder ${missing} does not exist`)
  return !missing
}

function loadProjects(paths: HostPaths, roles: Role[]): Project[] {
  ensureProjectsFile(paths)
  const file = paths.projectsFile
  const listed = z.array(projectSchema).parse(readJson(file))
  assertUniqueIds(file, listed)
  for (const project of listed) {
    for (const role of project.agents) {
      if (!roles.some((candidate) => candidate.id === role)) throw new Error(`${file}: project "${project.id}" lists unknown role "${role}"`)
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
  if (projects.length === 0) console.warn(`No project is available. Edit ${file} so it lists folders that exist on this Mac.`)
  return projects
}

/** Same rules as process.loadEnvFile: values that are already set win over the file. */
function loadEnvFile(env: Env, file: string): void {
  if (!existsSync(file)) return
  for (const [key, value] of Object.entries(parseEnv(readFileSync(file, 'utf8')))) {
    if (env[key] === undefined) env[key] = value
  }
}

function ensureToken(env: Env, envFile: string): void {
  if (env.SWITCHBOARD_TOKEN) return
  const token = randomBytes(32).toString('base64url')
  appendFileSync(envFile, `\nSWITCHBOARD_TOKEN=${token}\n`, { mode: 0o600 })
  chmodSync(envFile, 0o600)
  env.SWITCHBOARD_TOKEN = token
  console.log(`Created a new access token in ${envFile}`)
}

function unique(paths: string[]): string[] {
  return [...new Set(paths)]
}

export type Config = {
  port: number
  token: string
  tailscaleAddress: string | null
  localOnly: boolean
  approvalTimeoutMs: number
  settingSources: z.infer<typeof settingSourceSchema>[]
  claudePath: string | null
  homeDir: string
  webDir: string
  dataDir: string
  databaseFile: string
  protectedPaths: string[]
  secretPaths: string[]
  trustExcluded: string[]
  projects: Project[]
  roles: Role[]
}

/**
 * Loads the configuration from `env` (mutated like process.env: values from the .env file and a
 * new token are added to it) with code-side files taken from `root`.
 */
export function loadConfigFrom(env: Env, root: string): Config {
  const paths = resolveHostPaths(env, root)
  ensureHome(paths)
  const { envFile, homeDir, homeIsSet } = paths
  loadEnvFile(env, envFile)
  ensureToken(env, envFile)
  const parsed = envSchema.parse(env)
  const roles = z.array(roleSchema).parse(readJson(paths.rolesFile))
  assertUniqueIds(paths.rolesFile, roles)
  const dataDir = parsed.SWITCHBOARD_DATA_DIR ? expandHome(parsed.SWITCHBOARD_DATA_DIR) : paths.defaultDataDir
  mkdirSync(dataDir, { recursive: true, ...(homeIsSet ? { mode: 0o700 } : {}) })
  const realHome = realpathSync.native(homeDir)
  const homePaths = homeIsSet ? unique([homeDir, realHome]) : []
  const localOnly = parsed.SWITCHBOARD_TAILSCALE_IP === tailscaleOff
  return {
    port: parsed.SWITCHBOARD_PORT,
    token: parsed.SWITCHBOARD_TOKEN,
    tailscaleAddress: localOnly ? null : (parsed.SWITCHBOARD_TAILSCALE_IP ?? findTailscaleAddress()),
    localOnly,
    approvalTimeoutMs: parsed.SWITCHBOARD_APPROVAL_TIMEOUT_SECONDS * 1000,
    settingSources: parsed.SWITCHBOARD_SETTING_SOURCES,
    claudePath: parsed.SWITCHBOARD_CLAUDE_PATH ?? null,
    homeDir,
    webDir: join(root, 'web/dist'),
    dataDir,
    databaseFile: join(dataDir, 'switchboard.db'),
    protectedPaths: unique([envFile, `${envFile}.*`, `${dataDir}/**`, ...homePaths.map((path) => `${path}/**`)]),
    secretPaths: unique([envFile, dataDir, ...homePaths]),
    trustExcluded: unique([realpathSync.native(root), realpathSync.native(dataDir), realHome]),
    projects: loadProjects(paths, roles),
    roles,
  }
}

export function loadConfig(): Config {
  return loadConfigFrom(process.env, rootDir)
}
