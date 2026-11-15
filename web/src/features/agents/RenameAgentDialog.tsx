import { agentNameMaxLength, type Agent } from '@switchboard/shared'
import { useEffect, useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api } from '@/lib/api.ts'
import { errorMessage } from '@/lib/errors.ts'

type Props = {
  agent: Agent
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function RenameAgentDialog({ agent, open, onOpenChange }: Props) {
  const [name, setName] = useState(agent.name)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!open) return
    setName(agent.name)
    setError(null)
  }, [open, agent.name])

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    try {
      await api.renameAgent(agent.id, name)
      onOpenChange(false)
    } catch (cause) {
      setError(errorMessage(cause, 'Could not rename the agent'))
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <form onSubmit={submit} className="grid gap-5">
          <DialogHeader>
            <DialogTitle>Rename {agent.name}</DialogTitle>
            <DialogDescription>The agent keeps its conversation and role.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-2">
            <Label htmlFor="agent-rename">Name</Label>
            <Input id="agent-rename" value={name} onChange={(event) => setName(event.target.value)} maxLength={agentNameMaxLength} required autoFocus autoComplete="off" className="text-base" />
          </div>
          {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={saving || name.trim().length === 0}>
              Save name
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
