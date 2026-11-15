export type Theme = 'system' | 'light' | 'dark'

const media = window.matchMedia('(prefers-color-scheme: dark)')
let current: Theme = 'system'

function paint(): void {
  const dark = current === 'dark' || (current === 'system' && media.matches)
  document.documentElement.dataset.theme = dark ? 'dark' : 'light'
}

export function applyTheme(theme: Theme): void {
  current = theme
  paint()
}

media.addEventListener('change', paint)
