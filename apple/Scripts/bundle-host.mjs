// Bundles the host (host/src/index.ts, @switchboard/shared and the pure JavaScript packages it uses)
// into one ES module for the packaged app.
//
//   node apple/Scripts/bundle-host.mjs <repo folder> <Host/app folder>
//
// The output lands at <Host/app>/host/dist/index.mjs. config.ts finds its rootDir two folders up from
// its own file, so rootDir is <Host/app>, where make-dmg.sh puts web/dist, roles.json and
// projects.example.json.
//
// Kept out of the bundle and installed by npm next to it:
// - better-sqlite3: loads a native addon from its own folder.
// - @anthropic-ai/claude-agent-sdk: finds its claude binary package relative to its own file.
// - zod: shared with the Agent SDK, so both use one copy.
// - bufferutil and utf-8-validate: optional speedups ws asks for inside try/catch. They are not
//   installed, so ws uses its JavaScript fallback.
import { existsSync, readdirSync, readFileSync, writeFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join, relative, sep } from 'node:path'
import { pathToFileURL } from 'node:url'

const [repo, appDir] = process.argv.slice(2)
if (!repo || !appDir) {
  console.error('usage: bundle-host.mjs <repo folder> <Host/app folder>')
  process.exit(2)
}

// esbuild comes with tsx, which the host already depends on.
const fromHost = createRequire(join(repo, 'host/package.json'))
const fromTsx = createRequire(fromHost.resolve('tsx/package.json'))
const esbuild = await import(pathToFileURL(fromTsx.resolve('esbuild')).href)

const outfile = join(appDir, 'host/dist/index.mjs')
const result = await esbuild.build({
  absWorkingDir: repo,
  entryPoints: [join(repo, 'host/src/index.ts')],
  outfile,
  bundle: true,
  platform: 'node',
  format: 'esm',
  target: 'node24',
  external: ['better-sqlite3', '@anthropic-ai/claude-agent-sdk', 'zod', 'bufferutil', 'utf-8-validate'],
  // CommonJS packages in the bundle (express, ws) call require(); give the ES module one.
  banner: { js: "import { createRequire as __switchboardCreateRequire } from 'node:module'; const require = __switchboardCreateRequire(import.meta.url);" },
  legalComments: 'eof',
  metafile: true,
  logLevel: 'warning',
})

// Collect the licence texts of every package that ended up in the bundle.
const packages = new Map()
for (const input of Object.keys(result.metafile.inputs)) {
  const parts = input.split(sep === '/' ? '/' : /[\\/]/)
  const index = parts.lastIndexOf('node_modules')
  if (index < 0) continue
  const nameParts = parts[index + 1].startsWith('@') ? parts.slice(index + 1, index + 3) : parts.slice(index + 1, index + 2)
  const root = join(repo, ...parts.slice(0, index + 1), ...nameParts)
  if (packages.has(root)) continue
  const manifest = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'))
  const licenceFile = readdirSync(root).find((file) => /^(licen[cs]e|copying)(\.|$)/i.test(file))
  packages.set(root, { name: manifest.name, version: manifest.version, license: manifest.license, text: licenceFile ? readFileSync(join(root, licenceFile), 'utf8').trim() : null })
}
const notices = [...packages.values()]
  .sort((a, b) => a.name.localeCompare(b.name))
  .map((pkg) => `${pkg.name} ${pkg.version} (${pkg.license ?? 'see package'})\n\n${pkg.text ?? 'No licence file in the package.'}`)
writeFileSync(join(dirname(outfile), 'THIRD-PARTY-NOTICES.txt'), `Packages bundled into index.mjs\n\n${notices.join('\n\n' + '-'.repeat(72) + '\n\n')}\n`)

const size = existsSync(outfile) ? readFileSync(outfile).length : 0
console.log(`${relative(repo, outfile) || outfile}: ${(size / 1024).toFixed(0)} KB, ${packages.size} bundled packages`)
