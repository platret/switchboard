import { useEffect } from 'react'
import { sendOrWarn } from './socket.ts'
import { useStore } from './store.ts'

export function useShortcuts(): void {
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const store = useStore.getState()
      const command = event.metaKey || event.ctrlKey
      if (command && event.key.toLowerCase() === 'k') {
        event.preventDefault()
        store.setPaletteOpen(!store.paletteOpen)
      }
      if (command && event.key === '.' && store.agentId && store.view === 'chat') {
        event.preventDefault()
        sendOrWarn({ type: 'agent.stop', agentId: store.agentId })
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])
}
