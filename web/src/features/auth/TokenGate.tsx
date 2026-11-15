import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useStore } from '@/lib/store.ts'

export function TokenGate() {
  const rejected = useStore((state) => state.tokenRejected)
  const setToken = useStore((state) => state.setToken)
  const [value, setValue] = useState('')

  const submit = (event: FormEvent) => {
    event.preventDefault()
    const token = value.trim()
    if (token) setToken(token)
  }

  return (
    <main className="flex h-full items-center justify-center px-6 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <form onSubmit={submit} className="grid w-full max-w-sm gap-5">
        <div className="grid gap-1.5">
          <img src="/icon.svg" alt="" className="mb-2 size-12 rounded-xl" />
          <h1 className="text-2xl font-semibold tracking-tight">Switchboard</h1>
          <p className="text-muted-foreground">Paste the access token from the .env file in your Switchboard folder on your Mac. It is the value of SWITCHBOARD_TOKEN.</p>
        </div>
        <div className="grid gap-2">
          <Label htmlFor="token">Access token</Label>
          <Input id="token" type="password" value={value} onChange={(event) => setValue(event.target.value)} autoComplete="off" autoCapitalize="off" autoCorrect="off" spellCheck={false} required className="text-base" />
          {rejected && <p role="alert" className="text-sm text-destructive">The host did not accept that token. Check it and try again.</p>}
        </div>
        <Button type="submit" size="lg" disabled={value.trim().length === 0}>
          Connect
        </Button>
      </form>
    </main>
  )
}
