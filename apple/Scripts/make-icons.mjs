import { mkdirSync, writeFileSync } from 'node:fs'
import { deflateSync } from 'node:zlib'
import { art } from '../../web/scripts/icon-art.mjs'

const samples = 4
const macInset = 100 / 1024
const macRadius = 0.2237
const macPixels = [16, 32, 64, 128, 256, 512, 1024]
const macSlots = [[16, 1], [16, 2], [32, 1], [32, 2], [128, 1], [128, 2], [256, 1], [256, 2], [512, 1], [512, 2]]
const target = new URL('../Shared/Assets.xcassets/AppIcon.appiconset/', import.meta.url)

const table = Array.from({ length: 256 }, (_, n) => {
  let c = n
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
  return c >>> 0
})

function crc(buffer) {
  let c = 0xffffffff
  for (const byte of buffer) c = table[(c ^ byte) & 0xff] ^ (c >>> 8)
  return (c ^ 0xffffffff) >>> 0
}

function chunk(type, data) {
  const body = Buffer.concat([Buffer.from(type), data])
  const length = Buffer.alloc(4)
  length.writeUInt32BE(data.length)
  const checksum = Buffer.alloc(4)
  checksum.writeUInt32BE(crc(body))
  return Buffer.concat([length, body, checksum])
}

function insideRoundedSquare(x, y) {
  const dx = Math.max(Math.abs(x - 0.5) - (0.5 - macRadius), 0)
  const dy = Math.max(Math.abs(y - 0.5) - (0.5 - macRadius), 0)
  return Math.hypot(dx, dy) <= macRadius
}

function fullBleed(x, y) {
  return [...art(x, y), 255]
}

function macTile(x, y) {
  const u = (x - macInset) / (1 - 2 * macInset)
  const v = (y - macInset) / (1 - 2 * macInset)
  const inside = u >= 0 && u <= 1 && v >= 0 && v <= 1 && insideRoundedSquare(u, v)
  return inside ? [...art(u, v), 255] : [0, 0, 0, 0]
}

function pixel(size, px, py, colorAt) {
  const sum = [0, 0, 0, 0]
  for (let sy = 0; sy < samples; sy++) {
    for (let sx = 0; sx < samples; sx++) {
      const [r, g, b, a] = colorAt((px + (sx + 0.5) / samples) / size, (py + (sy + 0.5) / samples) / size)
      sum[0] += r * a
      sum[1] += g * a
      sum[2] += b * a
      sum[3] += a
    }
  }
  if (sum[3] === 0) return [0, 0, 0, 0]
  return [sum[0] / sum[3], sum[1] / sum[3], sum[2] / sum[3], sum[3] / samples ** 2].map(Math.round)
}

function png(size, colorAt, channels) {
  const stride = size * channels + 1
  const raw = Buffer.alloc(size * stride)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) raw.set(pixel(size, x, y, colorAt).slice(0, channels), y * stride + 1 + x * channels)
  }
  const header = Buffer.alloc(13)
  header.writeUInt32BE(size, 0)
  header.writeUInt32BE(size, 4)
  header.set([8, channels === 4 ? 6 : 2, 0, 0, 0], 8)
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))])
}

function contents() {
  const ios = { filename: 'ios-1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }
  const mac = macSlots.map(([points, scale]) => ({ filename: `mac-${points * scale}.png`, idiom: 'mac', scale: `${scale}x`, size: `${points}x${points}` }))
  return { images: [ios, ...mac], info: { author: 'xcode', version: 1 } }
}

mkdirSync(target, { recursive: true })
writeFileSync(new URL('ios-1024.png', target), png(1024, fullBleed, 3))
for (const size of macPixels) writeFileSync(new URL(`mac-${size}.png`, target), png(size, macTile, 4))
writeFileSync(new URL('Contents.json', target), `${JSON.stringify(contents(), null, 2)}\n`)
