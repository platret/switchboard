import type { ChatItem } from '@switchboard/shared'
import { Check, Copy } from 'lucide-react'
import { memo } from 'react'
import { useCopied } from '@/lib/useCopied.ts'
import { Markdown } from './Markdown.tsx'

function CopyButton({ text }: { text: string }) {
  const [copied, copy] = useCopied()
  return (
    <button
      type="button"
      onClick={() => copy(text)}
      aria-label={copied ? 'Copied' : 'Copy message'}
      className="mt-1.5 inline-flex items-center gap-1.5 rounded-md py-1 text-xs text-muted-foreground transition-colors hover:text-foreground"
    >
      {copied ? <Check className="size-3.5" /> : <Copy className="size-3.5" />}
      {copied ? 'Copied' : 'Copy'}
    </button>
  )
}

export const ChatMessage = memo(function ChatMessage({ item, closesTurn }: { item: ChatItem; closesTurn: boolean }) {
  const { content } = item
  const time = new Date(item.createdAt).toLocaleString()
  switch (content.kind) {
    case 'tool':
      return null
    case 'error':
      return <p className="rounded-lg border border-destructive/40 bg-destructive/10 px-3.5 py-2.5 text-sm text-destructive">{content.text}</p>
    case 'notice':
      return (
        <p className="flex items-center gap-3 text-xs text-muted-foreground before:h-px before:flex-1 before:bg-border after:h-px after:flex-1 after:bg-border">{content.text}</p>
      )
    case 'text':
      return item.role === 'user' ? (
        <p title={time} className="ml-auto w-fit max-w-[85%] whitespace-pre-wrap break-words rounded-2xl rounded-br-md bg-bubble px-4 py-2.5 text-[0.9375rem] leading-relaxed">
          {content.text}
        </p>
      ) : (
        <div title={time} className="group/message">
          <Markdown text={content.text} />
          {closesTurn && <CopyButton text={content.text} />}
        </div>
      )
  }
})
