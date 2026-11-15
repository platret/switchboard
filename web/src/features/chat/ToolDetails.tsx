import { cn } from '@/lib/utils'
import { flag, textField } from '@/features/approvals/describe.ts'

type BlockProps = {
  label?: string
  text: string
  tone?: 'removed' | 'added' | 'muted'
}

export function DetailBlock({ label, text, tone }: BlockProps) {
  return (
    <div>
      {label && <p className="pb-1 text-xs text-muted-foreground">{label}</p>}
      <pre
        tabIndex={0}
        className={cn(
          'max-h-48 overflow-auto whitespace-pre-wrap break-words rounded-md border bg-background px-2.5 py-2 font-mono text-xs leading-relaxed',
          tone === 'removed' && 'border-destructive/40',
          tone === 'added' && 'border-added/50',
          tone === 'muted' && 'text-muted-foreground',
        )}
      >
        {text}
      </pre>
    </div>
  )
}

function FilePath({ path }: { path: string }) {
  return <p className="break-all font-mono text-xs">{path}</p>
}

type Props = {
  toolName: string
  input: unknown
}

export function ToolDetails({ toolName, input }: Props) {
  const command = textField(input, 'command')
  const filePath = textField(input, 'file_path')
  const oldText = textField(input, 'old_string')
  const newText = textField(input, 'new_string')
  const content = textField(input, 'content')

  if (toolName === 'Bash' && command !== null) {
    return <DetailBlock label={flag(input, 'run_in_background') ? 'Command, keeps running in the background' : 'Command'} text={command} />
  }
  if (toolName === 'Edit' && filePath !== null && oldText !== null && newText !== null) {
    return (
      <div className="grid gap-2">
        <FilePath path={filePath} />
        <DetailBlock label={flag(input, 'replace_all') ? 'Remove, every occurrence in the file' : 'Remove'} text={oldText} tone="removed" />
        <DetailBlock label="Add" text={newText} tone="added" />
      </div>
    )
  }
  if (toolName === 'Write' && filePath !== null && content !== null) {
    return (
      <div className="grid gap-2">
        <FilePath path={filePath} />
        <DetailBlock label="New content" text={content} tone="added" />
      </div>
    )
  }
  return <DetailBlock text={JSON.stringify(input, null, 2)} />
}
