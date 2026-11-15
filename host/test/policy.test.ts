import assert from 'node:assert/strict'
import { test } from 'node:test'
import { mkdirSync, mkdtempSync, realpathSync, symlinkSync } from 'node:fs'
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
