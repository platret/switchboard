import type { Agent, ChatDraft, ChatItem } from '@switchboard/shared'
import { useEffect } from 'react'
import { ApprovalCard } from '@/features/approvals/ApprovalCard.tsx'
import { send, sendOrWarn } from '@/lib/socket.ts'
import { useStore } from '@/lib/store.ts'
import { ActivityLine } from './ActivityLine.tsx'
import { ChatHeader } from './ChatHeader.tsx'
import { Composer } from './Composer.tsx'
import { EmptyChat } from './EmptyChat.tsx'
import { MessageList } from './MessageList.tsx'

const noItems: ChatItem[] = []
const noDrafts: ChatDraft[] = []

export function ChatView({ agent }: { agent: Agent }) {
  const items = useStore((state) => state.items[agent.id])
  const drafts = useStore((state) => state.drafts[agent.id] ?? noDrafts)
  const role = useStore((state) => state.roles.find((candidate) => candidate.id === agent.role))
  const approvals = useStore((state) => state.approvals)
  const mine = approvals.filter((approval) => approval.agentId === agent.id)
  const sendText = (text: string) => sendOrWarn({ type: 'chat.send', agentId: agent.id, text })

  useEffect(() => {
    send({ type: 'history.get', agentId: agent.id })
  }, [agent.id])

  return (
    <section className="flex h-full min-w-0 flex-1 flex-col">
      <ChatHeader agent={agent} />
      <MessageList
        items={items ?? noItems}
        drafts={drafts}
        empty={items ? <EmptyChat agent={agent} role={role} onPick={sendText} /> : null}
        footer={
          <>
            {mine.map((approval) => (
              <ApprovalCard key={approval.id} approval={approval} />
            ))}
            <ActivityLine agent={agent} />
          </>
        }
      />
      <Composer agent={agent} onSend={sendText} onStop={() => sendOrWarn({ type: 'agent.stop', agentId: agent.id })} />
    </section>
  )
}
