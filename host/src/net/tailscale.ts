import { networkInterfaces } from 'node:os'

export function isTailscaleAddress(address: string): boolean {
  const [first, second] = address.split('.').map(Number)
  return first === 100 && second !== undefined && second >= 64 && second <= 127
}

export function findTailscaleAddress(): string | null {
  for (const [name, addresses] of Object.entries(networkInterfaces())) {
    if (!name.startsWith('utun') && !name.startsWith('tailscale')) continue
    const match = addresses?.find((entry) => entry.family === 'IPv4' && isTailscaleAddress(entry.address))
    if (match) return match.address
  }
  return null
}
