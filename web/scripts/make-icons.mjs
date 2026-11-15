import { writeFileSync } from 'node:fs'
import { deflateSync } from 'node:zlib'
import { art } from './icon-art.mjs'

const samples = 4

function crcTable() {
  return Array.from({ length: 256 }, (_, n) => {
    let c = n
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    return c >>> 0
  })
}

const table = crcTable()

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

function pixel(size, px, py) {
  const sum = [0, 0, 0]
  for (let sy = 0; sy < samples; sy++) {
    for (let sx = 0; sx < samples; sx++) {
      const color = art((px + (sx + 0.5) / samples) / size, (py + (sy + 0.5) / samples) / size)
      for (let channel = 0; channel < 3; channel++) sum[channel] += color[channel]
    }
  }
  return sum.map((value) => Math.round(value / samples ** 2))
}

function png(size) {
  const raw = Buffer.alloc(size * (size * 3 + 1))
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) raw.set(pixel(size, x, y), y * (size * 3 + 1) + 1 + x * 3)
  }
  const header = Buffer.alloc(13)
  header.writeUInt32BE(size, 0)
  header.writeUInt32BE(size, 4)
  header.set([8, 2, 0, 0, 0], 8)
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))])
}

for (const [name, size] of [['icon-192.png', 192], ['icon-512.png', 512], ['apple-touch-icon.png', 180]]) {
  writeFileSync(new URL(`../public/${name}`, import.meta.url), png(size))
}
