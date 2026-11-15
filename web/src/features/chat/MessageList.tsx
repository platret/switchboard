import type { ChatDraft, ChatItem } from '@switchboard/shared'
import { ArrowDown } from 'lucide-react'
import { useEffect, useLayoutEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { ChatMessage } from './ChatMessage.tsx'
import { Markdown } from './Markdown.tsx'
import { ToolGroup } from './ToolGroup.tsx'
import { buildThread } from './thread.ts'

type Props = {
  items: ChatItem[]
  drafts: ChatDraft[]
  empty: ReactNode
  footer: ReactNode
}

const stickThreshold = 120

export function MessageList({ items, drafts, empty, footer }: Props) {
  const scroller = useRef<HTMLDivElement>(null)
  const content = useRef<HTMLDivElement>(null)
  const stick = useRef(true)
  const lastTop = useRef(0)
  const [away, setAway] = useState(false)
  const thread = useMemo(() => buildThread(items), [items])

  useLayoutEffect(() => {
    const element = scroller.current
    if (element && stick.current) element.scrollTop = element.scrollHeight
  })

  useEffect(() => {
    const element = scroller.current
    if (!element || !content.current) return
    const observer = new ResizeObserver(() => {
      if (stick.current) element.scrollTop = element.scrollHeight
    })
    observer.observe(element)
    observer.observe(content.current)
    return () => observer.disconnect()
  }, [])

  const onScroll = () => {
    const element = scroller.current
    if (!element) return
    const distance = element.scrollHeight - element.scrollTop - element.clientHeight
    if (distance < 2) stick.current = true
    else if (element.scrollTop < lastTop.current) stick.current = false
    else if (distance < stickThreshold) stick.current = true
    lastTop.current = element.scrollTop
    setAway(distance > 400)
  }

  const jump = () => {
    stick.current = true
    scroller.current?.scrollTo({ top: scroller.current.scrollHeight, behavior: 'smooth' })
  }

  return (
    <div className="relative min-h-0 flex-1">
      <div ref={scroller} onScroll={onScroll} className="h-full overflow-y-auto overscroll-contain">
        <div ref={content} className="mx-auto flex min-h-full max-w-3xl flex-col justify-end gap-4 px-4 py-6">
          {thread.length === 0 && drafts.length === 0 && empty}
          {thread.map((entry) => (entry.type === 'tools' ? <ToolGroup key={entry.id} tools={entry.tools} /> : <ChatMessage key={entry.id} item={entry.item} closesTurn={entry.closesTurn} />))}
          {drafts.map((draft) => (
            <Markdown key={draft.id} text={draft.text} />
          ))}
          {footer}
        </div>
      </div>
      {away && (
        <button type="button" onClick={jump} aria-label="Jump to the newest message" className="absolute bottom-3 left-1/2 flex size-9 -translate-x-1/2 items-center justify-center rounded-full border bg-card shadow-float">
          <ArrowDown className="size-4" />
        </button>
      )}
    </div>
  )
}
