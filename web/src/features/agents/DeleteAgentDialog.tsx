import type { Agent } from '@switchboard/shared'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { api } from '@/lib/api.ts'
import { errorMessage } from '@/lib/errors.ts'

type Props = {
  agent: Agent
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function DeleteAgentDialog({ agent, open, onOpenChange }: Props) {
  const [error, setError] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  const confirm = async () => {
    setDeleting(true)
    try {
      await api.deleteAgent(agent.id)
      onOpenChange(false)
    } catch (cause) {
      setError(errorMessage(cause, 'Could not delete the agent'))
    } finally {
      setDeleting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Delete {agent.name}?</DialogTitle>
          <DialogDescription>This removes the agent and its whole conversation from Switchboard. Files it changed stay as they are. This cannot be undone.</DialogDescription>
        </DialogHeader>
        {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
        <DialogFooter>
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
            Keep agent
          </Button>
          <Button type="button" variant="destructive" disabled={deleting} onClick={confirm}>
            Delete agent
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
