import { useEffect } from 'react'
import { TooltipProvider } from '@/components/ui/tooltip'
import { Sidebar } from '@/features/agents/Sidebar.tsx'
import { ApprovalBar } from '@/features/approvals/ApprovalBar.tsx'
import { TokenGate } from '@/features/auth/TokenGate.tsx'
import { ChatView } from '@/features/chat/ChatView.tsx'
import { CommandPalette } from '@/features/command/CommandPalette.tsx'
import { Overview } from '@/features/overview/Overview.tsx'
import { SettingsDialog } from '@/features/settings/SettingsDialog.tsx'
import { connect, disconnect } from '@/lib/socket.ts'
import { useStore } from '@/lib/store.ts'
import { takeHashToken } from '@/lib/token.ts'
import { useShortcuts } from '@/lib/useShortcuts.ts'
import { useViewportHeight } from '@/lib/useViewportHeight.ts'
import { cn } from '@/lib/utils'

function Welcome() {
  const hasAgents = useStore((state) => Object.keys(state.agents).length > 0)
  return (
    <div className="m-auto max-w-sm px-6 text-center">
      <img src="/icon.svg" alt="" className="mx-auto mb-4 size-14 rounded-2xl" />
      <h2 className="text-xl font-semibold tracking-tight">{hasAgents ? 'Pick an agent' : 'Create your first agent'}</h2>
      <p className="pt-1 text-muted-foreground">{hasAgents ? 'Choose one on the left, or press Command K to jump to any agent.' : 'Agents live inside a project folder. Use New agent on the left to add one.'}</p>
    </div>
  )
}

function Workspace() {
  const agent = useStore((state) => (state.agentId ? state.agents[state.agentId] : undefined))
  const view = useStore((state) => state.view)
  const pending = useStore((state) => state.approvals.length)
  const barVisible = useStore((state) => state.approvals.some((approval) => state.view !== 'chat' || approval.agentId !== state.agentId))
  const focused = view === 'overview' || agent !== undefined

  useShortcuts()

  return (
    <>
      <p role="status" className="sr-only">
        {pending > 0 ? `${pending} approvals waiting` : ''}
      </p>
      <ApprovalBar />
      <div className={cn('flex min-h-0 flex-1', barVisible && '[--inset-top:0px]')}>
        <Sidebar className={cn('w-full md:flex md:w-80 md:flex-none', focused ? 'hidden' : 'flex')} />
        <main className={cn('min-w-0 flex-1', focused ? 'flex' : 'hidden md:flex')}>{view === 'overview' ? <Overview /> : agent ? <ChatView key={agent.id} agent={agent} /> : <Welcome />}</main>
      </div>
      <CommandPalette />
      <SettingsDialog />
    </>
  )
}

export function App() {
  const token = useStore((state) => state.token)
  const notice = useStore((state) => state.notice)
  const setNotice = useStore((state) => state.setNotice)

  useViewportHeight()

  useEffect(() => {
    if (!token) return
    connect()
    return disconnect
  }, [token])

  useEffect(() => {
    const onHashChange = () => {
      const next = takeHashToken()
      if (next) useStore.getState().setToken(next)
    }
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  useEffect(() => {
    if (!notice) return
    const timer = setTimeout(() => setNotice(null), 6000)
    return () => clearTimeout(timer)
  }, [notice, setNotice])

  return (
    <TooltipProvider>
      <div className="flex h-[var(--app-height,100dvh)] flex-col overflow-hidden">
        {token ? <Workspace /> : <TokenGate />}
        {notice && (
          <p role="alert" className="fixed inset-x-4 top-[calc(env(safe-area-inset-top)+0.75rem)] z-50 mx-auto w-fit max-w-md rounded-lg bg-foreground px-4 py-2 text-sm text-background shadow-float">
            {notice}
          </p>
        )}
      </div>
    </TooltipProvider>
  )
}
