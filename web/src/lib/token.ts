const tokenKey = 'switchboard.token'
const hashPrefix = '#token='

function read(): string | null {
  try {
    return localStorage.getItem(tokenKey)
  } catch {
    return null
  }
}

function decode(raw: string): string {
  try {
    return decodeURIComponent(raw)
  } catch {
    return raw
  }
}

export function saveToken(token: string): void {
  try {
    localStorage.setItem(tokenKey, token)
  } catch {
    return
  }
}

export function forgetToken(): void {
  try {
    localStorage.removeItem(tokenKey)
  } catch {
    return
  }
}

export function takeHashToken(): string | null {
  if (!location.hash.startsWith(hashPrefix)) return null
  const raw = location.hash.slice(hashPrefix.length)
  history.replaceState(null, '', location.pathname + location.search)
  const token = decode(raw).trim()
  return token.length > 0 ? token : null
}

export function initialToken(): string | null {
  const token = takeHashToken()
  if (!token) return read()
  saveToken(token)
  return token
}
