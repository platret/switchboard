import { Check, Copy } from 'lucide-react'
import { useRef, type ComponentProps } from 'react'
import { useCopied } from '@/lib/useCopied.ts'

export function CodeBlock({ children, ...props }: ComponentProps<'pre'>) {
  const block = useRef<HTMLPreElement>(null)
  const [copied, copy] = useCopied()

  return (
    <div className="group/code relative my-3 overflow-hidden rounded-lg border bg-card">
      <pre ref={block} {...props}>
        {children}
      </pre>
      <button
        type="button"
        onClick={() => copy(block.current?.textContent ?? '')}
        aria-label={copied ? 'Copied' : 'Copy code'}
        className="absolute right-1.5 top-1.5 rounded-md border bg-card p-1.5 text-muted-foreground opacity-0 transition-opacity hover:text-foreground focus-visible:opacity-100 group-hover/code:opacity-100 [@media(hover:none)]:opacity-100"
      >
        {copied ? <Check className="size-3.5" /> : <Copy className="size-3.5" />}
      </button>
    </div>
  )
}
