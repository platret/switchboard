export const background = [20, 25, 37]
export const cord = [138, 160, 255]
export const lamp = [242, 177, 58]

const canvas = 256
const scale = 0.9
const offset = [12.8, 11.8]
const half = 13
const bend = 27
const lampAt = [180, 74]
const jackAt = [76, 182]

function near(value, target) {
  return Math.abs(value - target) <= half
}

function onRun(x, y, row, from, to) {
  return near(y, row) && x >= from && x <= to
}

function onBend(x, y, centerX, centerY, opensLeft) {
  const side = opensLeft ? x <= centerX : x >= centerX
  return side && near(Math.hypot(x - centerX, y - centerY), bend)
}

function onCord(x, y) {
  return (
    onRun(x, y, 74, 106, 178) ||
    onBend(x, y, 106, 101, true) ||
    onRun(x, y, 128, 106, 150) ||
    onBend(x, y, 150, 155, false) ||
    onRun(x, y, 182, 100, 150)
  )
}

export function art(u, v) {
  const x = (u * canvas - offset[0]) / scale
  const y = (v * canvas - offset[1]) / scale
  const toLamp = Math.hypot(x - lampAt[0], y - lampAt[1])
  if (toLamp <= 28) return lamp
  if (toLamp <= 37) return background
  if (Math.abs(Math.hypot(x - jackAt[0], y - jackAt[1]) - 20) <= 8) return cord
  return onCord(x, y) ? cord : background
}
