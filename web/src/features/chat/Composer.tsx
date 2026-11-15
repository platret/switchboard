import { chatTextMaxLength, isBusy, type Agent } from '@switchboard/shared'
import { ArrowUp, Mic, Square } from 'lucide-react'
import { useEffect, useLayoutEffect, useRef, useState, type KeyboardEvent } from 'react'
import { Button } from '@/components/ui/button'
import { readDraft, writeDraft } from '@/lib/composerDrafts.ts'
import { useStore } from '@/lib/store.ts'
import { dictationSupported, useDictation } from '@/lib/useDictation.ts'
import { cn } from '@/lib/utils'
import { QueueChips } from './QueueChips.tsx'

type Props = {
  agent: Agent
  onSend: (text: string) => boolean
  onStop: () => void
}

const maxHeight = 220

export function Composer({ agent, onSend, onStop }: Props) {
  const [text, setText] = useState(() => readDraft(agent.id))
  const field = useRef<HTMLTextAreaElement>(null)
  const busy = isBusy(agent.status)
  const dictation = useDictation((spoken) => setText((current) => (current.trim().length > 0 ? `${current.trimEnd()} ${spoken}` : spoken)))

  useLayoutEffect(() => {
    writeDraft(agent.id, text)
    const element = field.current
    if (!element) return
    element.style.height = 'auto'
    element.style.height = `${Math.min(element.scrollHeight, maxHeight)}px`
  }, [agent.id, text])

  const undelivered = useStore((state) => (state.undelivered?.agentId === agent.id ? state.undelivered.text : null))

  useEffect(() => {
    if (undelivered === null) return
    setText((current) => (current.trim().length > 0 ? `${undelivered}\n${current}` : undelivered))
    useStore.getState().setUndelivered(null)
  }, [undelivered])

  const submit = () => {
    const trimmed = text.trim()
    if (!trimmed) return
    if (onSend(trimmed)) setText('')
  }

  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key !== 'Enter' || event.shiftKey || event.nativeEvent.isComposing) return
    if (window.matchMedia('(pointer: coarse)').matches) return
    event.preventDefault()
    submit()
  }

  const hint = dictation.listening ? dictation.interim || 'Listening. Speak now.' : busy ? `${agent.name} is busy. Your message is sent when this turn ends.` : 'Enter to send, Shift and Enter for a new line'

  return (
    <div className="px-3 pb-[calc(env(safe-area-inset-bottom)+0.75rem)] pt-1">
      <div className="mx-auto max-w-3xl">
        <div className="rounded-2xl border border-input bg-card shadow-float transition-shadow focus-within:border-ring focus-within:ring-[3px] focus-within:ring-ring/20">
          <QueueChips agent={agent} />
          <div className="flex items-end gap-1.5 p-2">
            {dictationSupported && (
              <Button
                type="button"
                variant={dictation.listening ? 'destructive' : 'ghost'}
                size="icon"
                onClick={dictation.toggle}
                aria-pressed={dictation.listening}
                aria-label={dictation.listening ? 'Stop dictation' : 'Dictate a message'}
                className={cn('rounded-full', dictation.listening && 'listening')}
              >
                <Mic />
              </Button>
            )}
            <textarea
              ref={field}
              rows={1}
              maxLength={chatTextMaxLength}
              value={text}
              onChange={(event) => setText(event.target.value)}
              onKeyDown={onKeyDown}
              placeholder={`Message ${agent.name}`}
              aria-label={`Message ${agent.name}`}
              className="min-h-9 flex-1 resize-none bg-transparent px-2 py-1.5 text-base leading-snug outline-none placeholder:text-muted-foreground"
            />
            {busy && (
              <Button type="button" variant="outline" size="icon" onClick={onStop} aria-label={`Stop ${agent.name}`} className="rounded-full">
                <Square className="size-3.5 fill-current" />
              </Button>
            )}
            <Button type="button" size="icon" onClick={submit} disabled={text.trim().length === 0} aria-label={busy ? 'Queue message' : 'Send message'} className="rounded-full">
              <ArrowUp />
            </Button>
          </div>
        </div>
        <p aria-live="polite" className={cn('truncate px-3 pt-1.5 text-xs text-muted-foreground', !dictation.listening && !busy && 'hidden md:block')}>
          {hint}
        </p>
      </div>
    </div>
  )
}
