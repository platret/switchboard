import assert from 'node:assert/strict'
import { test } from 'node:test'
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { buildOptions } from '../src/agents/options.ts'
import { isProjectEdit, needsApproval } from '../src/agents/policy.ts'
import { loadConfigFrom, resolveHostPaths, rootDir as repoRoot } from '../src/config.ts'

type Env = Record<string, string | undefined>

const tailscale = '100.100.100.100'
const token = 'test-token-that-is-long-enough-for-the-schema'

function scratch(t: { after: (fn: () => void) => void }): string {
  const dir = realpathSync.native(mkdtempSync(join(tmpdir(), 'switchboard-config-')))
  t.after(() => rmSync(dir, { recursive: true, force: true }))
  return dir
}

function fakeRoot(base: string): string {
  const root = join(base, 'root')
  mkdirSync(root)
  copyFileSync(join(repoRoot, 'roles.json'), join(root, 'roles.json'))
  copyFileSync(join(repoRoot, 'projects.example.json'), join(root, 'projects.example.json'))
  return root
}

function mode(path: string): number {
  return statSync(path).mode & 0o777
}

test('without SWITCHBOARD_HOME every path stays in the repo', () => {
  const paths = resolveHostPaths({}, '/repo')
  assert.deepEqual(paths, {
    rootDir: '/repo',
    homeDir: '/repo',
    homeIsSet: false,
    envFile: '/repo/.env',
    projectsFile: '/repo/projects.json',
    rolesFile: '/repo/roles.json',
    defaultDataDir: '/repo/data.nosync',
  })
  assert.deepEqual(resolveHostPaths({ SWITCHBOARD_HOME: '  ' }, '/repo'), paths)
})

test('without SWITCHBOARD_HOME the loaded config matches the old layout', (t) => {
  const root = fakeRoot(scratch(t))
  const env: Env = { SWITCHBOARD_TAILSCALE_IP: tailscale }
  const config = loadConfigFrom(env, root)
  const envFile = join(root, '.env')
  const dataDir = join(root, 'data.nosync')
  assert.equal(config.homeDir, root)
  assert.equal(config.dataDir, dataDir)
  assert.equal(config.databaseFile, join(dataDir, 'switchboard.db'))
  assert.equal(config.webDir, join(root, 'web/dist'))
  assert.equal(config.claudePath, null)
  assert.deepEqual(config.protectedPaths, [envFile, `${envFile}.*`, `${dataDir}/**`])
  assert.deepEqual(config.secretPaths, [envFile, dataDir])
  assert.deepEqual(config.trustExcluded, [root, dataDir])
  assert.equal(readFileSync(join(root, 'projects.json'), 'utf8'), readFileSync(join(root, 'projects.example.json'), 'utf8'))
  assert.ok(env.SWITCHBOARD_TOKEN && env.SWITCHBOARD_TOKEN.length >= 24)
  assert.match(readFileSync(envFile, 'utf8'), /^SWITCHBOARD_TOKEN=/m)
  assert.equal(mode(envFile), 0o600)
})

test('with SWITCHBOARD_HOME the writable files live in that folder', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const home = join(base, 'nested', 'home')
  const env: Env = { SWITCHBOARD_HOME: home, SWITCHBOARD_TAILSCALE_IP: tailscale }
  const config = loadConfigFrom(env, root)
  const envFile = join(home, '.env')
  const dataDir = join(home, 'data')
  assert.equal(mode(home), 0o700)
  assert.equal(mode(envFile), 0o600)
  assert.match(readFileSync(envFile, 'utf8'), /^SWITCHBOARD_TOKEN=/m)
  assert.equal(readFileSync(join(home, 'projects.json'), 'utf8'), '[]\n')
  assert.equal(existsSync(join(root, 'projects.json')), false)
  assert.equal(existsSync(join(root, '.env')), false)
  assert.equal(existsSync(join(root, 'data.nosync')), false)
  assert.equal(config.homeDir, home)
  assert.equal(config.dataDir, dataDir)
  assert.equal(config.databaseFile, join(dataDir, 'switchboard.db'))
  assert.ok(existsSync(dataDir))
  assert.equal(config.webDir, join(root, 'web/dist'))
  assert.deepEqual(config.projects, [])
  assert.deepEqual(
    config.roles.map((role) => role.id),
    JSON.parse(readFileSync(join(root, 'roles.json'), 'utf8')).map((role: { id: string }) => role.id),
  )
  for (const path of [envFile, `${envFile}.*`, `${dataDir}/**`, `${home}/**`]) assert.ok(config.protectedPaths.includes(path), path)
  for (const path of [envFile, dataDir, home]) assert.ok(config.secretPaths.includes(path), path)
  for (const path of [root, dataDir, home]) assert.ok(config.trustExcluded.includes(path), path)
})

test('with SWITCHBOARD_HOME settings come from its .env and an existing projects.json is kept', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const home = join(base, 'home')
  const project = join(base, 'project')
  mkdirSync(home)
  mkdirSync(project)
  writeFileSync(join(home, '.env'), `SWITCHBOARD_TOKEN=${token}\nSWITCHBOARD_PORT=4391\n`, { mode: 0o600 })
  writeFileSync(join(home, 'projects.json'), JSON.stringify([{ id: 'p', name: 'P', path: project, agents: ['dev'] }]))
  const config = loadConfigFrom({ SWITCHBOARD_HOME: home, SWITCHBOARD_TAILSCALE_IP: tailscale, SWITCHBOARD_PORT: undefined }, root)
  assert.equal(config.port, 4391)
  assert.equal(config.token, token)
  assert.deepEqual(config.projects.map((entry) => entry.path), [project])
  assert.equal(readFileSync(join(home, '.env'), 'utf8'), `SWITCHBOARD_TOKEN=${token}\nSWITCHBOARD_PORT=4391\n`)
})

test('values already in the environment win over the .env file', (t) => {
  const base = scratch(t)
  const home = join(base, 'home')
  mkdirSync(home)
  writeFileSync(join(home, '.env'), `SWITCHBOARD_TOKEN=${token}\nSWITCHBOARD_PORT=4391\n`)
  const config = loadConfigFrom({ SWITCHBOARD_HOME: home, SWITCHBOARD_TAILSCALE_IP: tailscale, SWITCHBOARD_PORT: '4392' }, fakeRoot(base))
  assert.equal(config.port, 4392)
})

test('a roles.json in SWITCHBOARD_HOME overrides the bundled one', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const home = join(base, 'home')
  mkdirSync(home)
  const roles = [{ id: 'solo', name: 'Solo', description: 'Only role', systemPrompt: 'Be brief.', tools: ['Read'], model: 'sonnet' }]
  writeFileSync(join(home, 'roles.json'), JSON.stringify(roles))
  assert.equal(resolveHostPaths({ SWITCHBOARD_HOME: home }, root).rolesFile, join(home, 'roles.json'))
  const config = loadConfigFrom({ SWITCHBOARD_HOME: home, SWITCHBOARD_TOKEN: token, SWITCHBOARD_TAILSCALE_IP: tailscale }, root)
  assert.deepEqual(config.roles.map((role) => role.id), ['solo'])
})

test('SWITCHBOARD_DATA_DIR still overrides the data folder', (t) => {
  const base = scratch(t)
  const home = join(base, 'home')
  const data = join(base, 'elsewhere')
  const config = loadConfigFrom({ SWITCHBOARD_HOME: home, SWITCHBOARD_DATA_DIR: data, SWITCHBOARD_TOKEN: token, SWITCHBOARD_TAILSCALE_IP: tailscale }, fakeRoot(base))
  assert.equal(config.dataDir, data)
  assert.ok(existsSync(data))
  assert.equal(existsSync(join(home, 'data')), false)
})

test('SWITCHBOARD_CLAUDE_PATH must name an existing executable file', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const claude = join(base, 'claude')
  const plain = join(base, 'claude-not-executable')
  writeFileSync(claude, '#!/bin/sh\n', { mode: 0o755 })
  writeFileSync(plain, '#!/bin/sh\n', { mode: 0o644 })
  const load = (value: string) =>
    loadConfigFrom({ SWITCHBOARD_HOME: join(base, 'home'), SWITCHBOARD_TOKEN: token, SWITCHBOARD_TAILSCALE_IP: tailscale, SWITCHBOARD_CLAUDE_PATH: value }, root)
  assert.equal(load(claude).claudePath, claude)
  assert.throws(() => load(join(base, 'missing')), /SWITCHBOARD_CLAUDE_PATH/)
  assert.throws(() => load(base), /SWITCHBOARD_CLAUDE_PATH/)
  assert.throws(() => load(plain), /SWITCHBOARD_CLAUDE_PATH/)
})

test('SWITCHBOARD_TAILSCALE_IP=off keeps the host on this Mac only', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const load = (value: string) =>
    loadConfigFrom({ SWITCHBOARD_HOME: join(base, 'home'), SWITCHBOARD_TOKEN: token, SWITCHBOARD_TAILSCALE_IP: value }, root)
  const off = load('off')
  assert.equal(off.tailscaleAddress, null)
  assert.equal(off.localOnly, true)
  const on = load(tailscale)
  assert.equal(on.tailscaleAddress, tailscale)
  assert.equal(on.localOnly, false)
  assert.throws(() => load('192.168.1.2'), /SWITCHBOARD_TAILSCALE_IP/)
  assert.throws(() => load('local'), /SWITCHBOARD_TAILSCALE_IP/)
})

test('a home reached through a symlinked folder with a space is protected under both paths', (t) => {
  const base = scratch(t)
  const root = fakeRoot(base)
  const real = join(base, 'real')
  const linked = join(base, 'Library link')
  const project = join(base, 'project')
  mkdirSync(join(real, 'Application Support'), { recursive: true })
  mkdirSync(project)
  symlinkSync(real, linked)
  const home = join(linked, 'Application Support', 'Switchboard')
  const realHome = join(real, 'Application Support', 'Switchboard')
  const config = loadConfigFrom({ SWITCHBOARD_HOME: home, SWITCHBOARD_TOKEN: token, SWITCHBOARD_TAILSCALE_IP: tailscale }, root)
  assert.equal(config.homeDir, home)
  for (const path of [`${home}/**`, `${realHome}/**`]) assert.ok(config.protectedPaths.includes(path), path)
  for (const path of [home, realHome]) assert.ok(config.secretPaths.includes(path), path)
  assert.ok(config.trustExcluded.includes(realHome))
  writeFileSync(join(home, 'roles.json'), readFileSync(join(root, 'roles.json')))
  for (const folder of [home, realHome]) {
    const roots = [project, folder]
    for (const file of ['.env', 'projects.json', 'roles.json', 'data/switchboard.db']) {
      assert.equal(needsApproval('Read', { file_path: join(folder, file) }, roots, config.secretPaths), true, `${folder}/${file}`)
    }
    for (const file of ['.env', 'projects.json']) {
      assert.equal(isProjectEdit('Write', { file_path: join(folder, file) }, roots, config.trustExcluded), false, `${folder}/${file}`)
    }
  }
  const options = buildOptions({
    agent: { id: 'a', name: 'A', projectId: 'p', role: 'dev', sessionId: null } as never,
    project: { id: 'p', name: 'P', path: project, additionalDirectories: [], agents: ['dev'] } as never,
    role: config.roles[0]!,
    settingSources: [],
    protectedPaths: config.protectedPaths,
    authorize: async () => ({ decision: 'allow' as const, asked: false, reason: '' }),
    onStderr: () => {},
  })
  const deny = options.settings && typeof options.settings === 'object' ? options.settings.permissions?.deny : undefined
  for (const path of [home, realHome]) assert.ok(deny?.includes(`Read(/${path}/**)`), path)
})

test('buildOptions passes the claude path to the Agent SDK only when it is set', () => {
  const input = {
    agent: { id: 'a', name: 'A', projectId: 'p', role: 'dev', sessionId: null } as never,
    project: { id: 'p', name: 'P', path: '/work/p', additionalDirectories: [], agents: ['dev'] } as never,
    role: { id: 'dev', name: 'Dev', description: '', systemPrompt: '', tools: ['Read'], model: 'sonnet' } as never,
    settingSources: [],
    protectedPaths: [],
    authorize: async () => ({ decision: 'allow' as const, asked: false, reason: '' }),
    onStderr: () => {},
  }
  assert.equal(buildOptions({ ...input, claudePath: '/bundle/Host/claude' }).pathToClaudeCodeExecutable, '/bundle/Host/claude')
  assert.equal(buildOptions({ ...input, claudePath: null }).pathToClaudeCodeExecutable, undefined)
  assert.equal('pathToClaudeCodeExecutable' in buildOptions(input), false)
})
