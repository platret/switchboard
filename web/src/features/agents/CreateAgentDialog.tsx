import { agentNameMaxLength, type Project, type Role } from '@switchboard/shared'
import { Plus } from 'lucide-react'
import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api } from '@/lib/api.ts'
import { errorMessage } from '@/lib/errors.ts'
import { useStore } from '@/lib/store.ts'
import { cn } from '@/lib/utils'

type Props = {
  project: Project
  roles: Role[]
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function CreateAgentDialog({ project, roles, open, onOpenChange }: Props) {
  const [name, setName] = useState('')
  const [role, setRole] = useState(roles[0]?.id ?? '')
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  const change = (next: boolean) => {
    onOpenChange(next)
    if (!next) return
    setName('')
    setRole(roles[0]?.id ?? '')
    setError(null)
  }

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    setSaving(true)
    try {
      const agent = await api.createAgent({ projectId: project.id, role, name })
      const store = useStore.getState()
      store.apply({ type: 'agent.upserted', agent })
      store.openAgent(agent)
      onOpenChange(false)
    } catch (cause) {
      setError(errorMessage(cause, 'Could not create the agent'))
    } finally {
      setSaving(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={change}>
      <DialogTrigger asChild>
        <Button type="button" className="w-full" disabled={roles.length === 0}>
          <Plus />
          New agent
        </Button>
      </DialogTrigger>
      <DialogContent>
        <form onSubmit={submit} className="grid gap-5">
          <DialogHeader>
            <DialogTitle>New agent in {project.name}</DialogTitle>
            <DialogDescription>It works in {project.path} and asks before it changes anything.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-2">
            <Label htmlFor="agent-name">Name</Label>
            <Input id="agent-name" value={name} onChange={(event) => setName(event.target.value)} placeholder="Bob" maxLength={agentNameMaxLength} required autoFocus autoComplete="off" className="text-base" />
          </div>
          <fieldset className="grid gap-2">
            <legend className="mb-2 text-sm font-medium">Role</legend>
            {roles.map((option) => (
              <label
                key={option.id}
                className={cn(
                  'flex cursor-pointer items-start gap-3 rounded-lg border px-3 py-2.5 transition-colors has-focus-visible:ring-[3px] has-focus-visible:ring-ring/40',
                  role === option.id ? 'border-primary bg-accent' : 'hover:bg-accent/50',
                )}
              >
                <input type="radio" name="role" value={option.id} checked={role === option.id} onChange={() => setRole(option.id)} className="mt-1 size-4 accent-primary outline-none" />
                <span className="min-w-0">
                  <span className="block font-medium leading-tight">{option.name}</span>
                  {option.description && <span className="block text-sm text-muted-foreground">{option.description}</span>}
                </span>
              </label>
            ))}
          </fieldset>
          {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={saving || name.trim().length === 0 || !role}>
              Create agent
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
