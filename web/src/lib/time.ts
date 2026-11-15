const formatter = new Intl.RelativeTimeFormat('en', { numeric: 'auto', style: 'short' })

const steps: [Intl.RelativeTimeFormatUnit, number][] = [
  ['day', 86_400_000],
  ['hour', 3_600_000],
  ['minute', 60_000],
]

export function relativeTime(timestamp: number, now: number = Date.now()): string {
  const elapsed = timestamp - now
  for (const [unit, size] of steps) {
    if (Math.abs(elapsed) >= size) return formatter.format(Math.round(elapsed / size), unit)
  }
  return 'just now'
}
