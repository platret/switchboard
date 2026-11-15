import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { enableNotifications, notificationsSupported } from '@/lib/notify.ts'
import { useStore } from '@/lib/store.ts'
import type { Theme } from '@/lib/theme.ts'
import { dictationSupported } from '@/lib/useDictation.ts'
import { cn } from '@/lib/utils'
import { PairPhone } from './PairPhone.tsx'

const themes: { value: Theme; label: string }[] = [
  { value: 'system', label: 'Match system' },
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
]

const languages = [
  { value: '', label: 'Browser language' },
  { value: 'en-US', label: 'English (US)' },
  { value: 'en-GB', label: 'English (UK)' },
  { value: 'de-DE', label: 'Deutsch' },
  { value: 'de-CH', label: 'Deutsch (Schweiz)' },
  { value: 'fr-FR', label: 'Français' },
  { value: 'fr-CH', label: 'Français (Suisse)' },
  { value: 'es-ES', label: 'Español' },
  { value: 'it-IT', label: 'Italiano' },
  { value: 'pt-BR', label: 'Português (Brasil)' },
  { value: 'nl-NL', label: 'Nederlands' },
]

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="grid gap-2.5">
      <h3 className="text-sm font-medium">{title}</h3>
      {children}
    </section>
  )
}

export function SettingsDialog() {
  const open = useStore((state) => state.settingsOpen)
  const theme = useStore((state) => state.theme)
  const voiceLanguage = useStore((state) => state.voiceLanguage)
  const notifications = useStore((state) => state.notifications)
  const { setSettingsOpen, setTheme, setVoiceLanguage, setNotifications, setNotice, signOut } = useStore.getState()

  const toggleNotifications = async () => {
    if (notifications) return setNotifications(false)
    const granted = await enableNotifications()
    setNotifications(granted)
    if (!granted) setNotice('Notifications are blocked for this site in the browser settings.')
  }

  return (
    <Dialog open={open} onOpenChange={setSettingsOpen}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Settings</DialogTitle>
          <DialogDescription>These apply to this browser only.</DialogDescription>
        </DialogHeader>
        <div className="grid gap-6">
          <Section title="Appearance">
            <div role="radiogroup" aria-label="Theme" className="grid grid-cols-3 gap-1 rounded-lg bg-muted p-1">
              {themes.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  role="radio"
                  aria-checked={theme === option.value}
                  onClick={() => setTheme(option.value)}
                  className={cn('rounded-md px-2 py-1.5 text-sm transition-colors', theme === option.value ? 'bg-card font-medium shadow-sm' : 'text-muted-foreground')}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </Section>
          <Section title="Voice input">
            {dictationSupported ? (
              <select value={voiceLanguage} onChange={(event) => setVoiceLanguage(event.target.value)} aria-label="Dictation language" className="h-10 rounded-md border border-input bg-card px-3 text-base">
                {languages.map((language) => (
                  <option key={language.value} value={language.value}>
                    {language.label}
                  </option>
                ))}
              </select>
            ) : (
              <p className="text-sm text-muted-foreground">This browser only offers dictation on a secure address such as localhost. On the iPhone use the microphone key on the keyboard, or the Switchboard app.</p>
            )}
          </Section>
          <Section title="Notifications">
            {notificationsSupported ? (
              <label className="flex items-center gap-3 text-sm">
                <input type="checkbox" checked={notifications} onChange={toggleNotifications} className="size-4 accent-primary" />
                Tell me when an agent needs approval or finishes while this tab is in the background
              </label>
            ) : (
              <p className="text-sm text-muted-foreground">Browser notifications need a secure address such as localhost. The Mac and iPhone apps notify you everywhere.</p>
            )}
          </Section>
          <Section title="Pair your phone">
            <PairPhone />
          </Section>
          <Button type="button" variant="outline" onClick={signOut} className="justify-self-start">
            Forget the access token on this browser
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
