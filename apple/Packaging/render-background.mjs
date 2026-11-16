// Renders dmg-background.html to the 1x and 2x PNGs and the Retina TIFF that the disk image uses.
//
//   node apple/Packaging/render-background.mjs [path/to/puppeteer-core]
//
// Needs Google Chrome and puppeteer-core. Pass the folder that holds puppeteer-core (or set
// PUPPETEER_CORE) when it is not resolvable from here. The rendered files are committed, so a
// normal build of the disk image does not need Chrome.
import { execFileSync } from 'node:child_process'
import { existsSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const chrome = process.env.CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const searchFrom = process.argv[2] ?? process.env.PUPPETEER_CORE

function loadPuppeteer() {
  const require = createRequire(searchFrom ? join(searchFrom, 'noop.js') : import.meta.url)
  return import(pathToFileURL(require.resolve('puppeteer-core')).href)
}

if (!existsSync(chrome)) throw new Error(`Google Chrome not found at ${chrome}. Set CHROME_PATH.`)
const { default: puppeteer } = await loadPuppeteer()
const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--allow-file-access-from-files'] })
try {
  const page = await browser.newPage()
  for (const [scale, name] of [
    [1, 'dmg-background.png'],
    [2, 'dmg-background@2x.png'],
  ]) {
    await page.setViewport({ width: 660, height: 420, deviceScaleFactor: scale })
    await page.goto(pathToFileURL(join(here, 'dmg-background.html')).href, { waitUntil: 'load' })
    await page.evaluate(() => document.fonts.ready)
    const loaded = await page.evaluate(() => document.fonts.check('500 13px Onest'))
    if (!loaded) throw new Error('The Onest font did not load. Run pnpm install so web/node_modules exists.')
    await page.screenshot({ path: join(here, name), clip: { x: 0, y: 0, width: 660, height: 420 } })
    console.log(`Wrote ${name}`)
  }
} finally {
  await browser.close()
}

execFileSync('tiffutil', ['-cathidpicheck', join(here, 'dmg-background.png'), join(here, 'dmg-background@2x.png'), '-out', join(here, 'dmg-background.tiff')], { stdio: 'inherit' })
console.log('Wrote dmg-background.tiff')
