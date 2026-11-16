import assert from 'node:assert/strict'
import { test } from 'node:test'
import { mkdirSync, mkdtempSync, realpathSync, rmSync, symlinkSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { isProjectEdit, needsApproval } from '../src/agents/policy.ts'

const roots = ['/work/projects', '/work/extra']
const secrets = ['/work/projects/switchboard/.env', '/work/projects/switchboard/data.nosync']

const cases: [string, unknown, boolean][] = [
  ['Read', { file_path: '/work/projects/app/README.md' }, false],
  ['Read', { file_path: 'app/README.md' }, false],
  ['Read', { file_path: '/work/extra/x/A.java' }, false],
  ['Read', { file_path: '/etc/hosts' }, true],
  ['Read', { file_path: '../secret.txt' }, true],
  ['Read', { file_path: '/work/projects-other/a' }, true],
  ['Read', { file_path: 'switchboard/.env' }, true],
  ['Read', { file_path: '/work/projects/switchboard/data.nosync/switchboard.db' }, true],
  ['Read', { file_path: 'switchboard/README.md' }, false],
  ['Read', null, true],
  ['Grep', { pattern: 'KEY', path: '~/.ssh' }, true],
  ['Grep', { pattern: 'KEY', path: ' /etc' }, true],
  ['Grep', { pattern: 'KEY' }, false],
  ['Grep', { pattern: 'TOKEN', path: 'switchboard/data.nosync' }, true],
  ['Glob', { pattern: '/home/someone/.ssh/*' }, true],
  ['Glob', { pattern: '~/.aws/*' }, true],
  ['Glob', { pattern: '**/*.ts' }, false],
  ['Glob', { pattern: '*.ts', path: '~' }, true],
  ['Bash', { command: 'ls' }, true],
  ['Write', { file_path: 'a.txt', content: 'x' }, true],
  ['Edit', { file_path: 'a.txt', old_string: 'a', new_string: 'b' }, true],
  ['WebFetch', { url: 'https://example.com' }, true],
  ['mcp__server__tool', {}, true],
  ['TodoWrite', { todos: [] }, false],
  ['Agent', { prompt: 'x', description: 'y' }, false],
  ['Agent', { prompt: 'x', isolation: 'worktree' }, true],
]

for (const [tool, input, expected] of cases) {
  test(`${tool} ${JSON.stringify(input)} ${expected ? 'asks' : 'passes'}`, () => {
    assert.equal(needsApproval(tool, input, roots, secrets), expected)
  })
}

test('turn trust covers plain edits inside the project only', () => {
  const excluded = ['/work/projects/switchboard']
  assert.equal(isProjectEdit('Edit', { file_path: 'app/a.ts' }, roots, excluded), true)
  assert.equal(isProjectEdit('Write', { file_path: '/work/extra/b.ts' }, roots, excluded), true)
  assert.equal(isProjectEdit('NotebookEdit', { notebook_path: 'app/n.ipynb' }, roots, excluded), true)
  assert.equal(isProjectEdit('Edit', { file_path: '/etc/hosts' }, roots, excluded), false)
  assert.equal(isProjectEdit('Edit', { file_path: '~/notes.txt' }, roots, excluded), false)
  assert.equal(isProjectEdit('Write', { file_path: 'switchboard/.env' }, roots, excluded), false)
  assert.equal(isProjectEdit('Edit', { file_path: 'switchboard/host/src/agents/policy.ts' }, roots, excluded), false)
  assert.equal(isProjectEdit('Write', { file_path: 'app/.claude/settings.local.json' }, roots, excluded), false)
  assert.equal(isProjectEdit('Write', { file_path: 'app/.git/hooks/pre-commit' }, roots, excluded), false)
  assert.equal(isProjectEdit('Write', { file_path: 'app/.mcp.json' }, roots, excluded), false)
  assert.equal(isProjectEdit('Bash', { command: 'rm -rf .' }, roots, excluded), false)
  assert.equal(isProjectEdit('Edit', {}, roots, excluded), false)
})

test('turn trust does not follow a symlink out of the project', () => {
  const base = realpathSync.native(mkdtempSync(join(tmpdir(), 'sb-policy-')))
  const project = join(base, 'project')
  const outside = join(base, 'outside')
  mkdirSync(project)
  mkdirSync(outside)
  symlinkSync(outside, join(project, 'link'))
  assert.equal(isProjectEdit('Write', { file_path: join(project, 'ok.txt') }, [project], []), true)
  assert.equal(isProjectEdit('Write', { file_path: join(project, 'link', 'escaped.txt') }, [project], []), false)
})

test('reads do not follow a symlink to a secret or out of the project', (t) => {
  const base = realpathSync.native(mkdtempSync(join(tmpdir(), 'sb-policy-')))
  t.after(() => rmSync(base, { recursive: true, force: true }))
  const project = join(base, 'project')
  const home = join(base, 'home')
  const outside = join(base, 'outside')
  for (const folder of [project, home, outside]) mkdirSync(folder)
  writeFileSync(join(home, '.env'), 'SWITCHBOARD_TOKEN=x\n')
  writeFileSync(join(outside, 'notes.txt'), 'x\n')
  symlinkSync(join(home, '.env'), join(project, 'notes.txt'))
  symlinkSync(home, join(project, 'home-link'))
  symlinkSync(join(outside, 'notes.txt'), join(project, 'outside.txt'))
  const secrets = [join(home, '.env'), home]
  assert.equal(needsApproval('Read', { file_path: join(project, 'notes.txt') }, [project], secrets), true)
  assert.equal(needsApproval('Read', { file_path: 'notes.txt' }, [project], secrets), true)
  assert.equal(needsApproval('Grep', { pattern: 'TOKEN', path: 'home-link' }, [project], secrets), true)
  assert.equal(needsApproval('Read', { file_path: 'outside.txt' }, [project], secrets), true)
  writeFileSync(join(project, 'plain.txt'), 'x\n')
  assert.equal(needsApproval('Read', { file_path: 'plain.txt' }, [project], secrets), false)
})

test('a secret reached through a symlinked parent folder still needs approval', (t) => {
  const base = realpathSync.native(mkdtempSync(join(tmpdir(), 'sb-policy-')))
  t.after(() => rmSync(base, { recursive: true, force: true }))
  const realHome = join(base, 'real home')
  const linkedHome = join(base, 'linked home')
  const project = join(base, 'project')
  mkdirSync(realHome)
  mkdirSync(project)
  symlinkSync(realHome, linkedHome)
  writeFileSync(join(realHome, '.env'), 'SWITCHBOARD_TOKEN=x\n')
  assert.equal(needsApproval('Read', { file_path: join(realHome, '.env') }, [project, base], [join(linkedHome, '.env')]), true)
})
