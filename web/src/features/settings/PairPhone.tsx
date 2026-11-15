import qrcode from 'qrcode-generator'
import { useMemo } from 'react'
import { useStore } from '@/lib/store.ts'

export function PairPhone() {
  const tailscaleUrl = useStore((state) => state.tailscaleUrl)
  const token = useStore((state) => state.token)
  const link = tailscaleUrl && token ? `${tailscaleUrl}/#token=${encodeURIComponent(token)}` : null
  const markup = useMemo(() => {
    if (!link) return null
    const code = qrcode(0, 'M')
    code.addData(link)
    code.make()
    return code.createSvgTag({ cellSize: 4, margin: 2, scalable: true })
  }, [link])

  if (!markup) return <p className="text-sm text-muted-foreground">Start Tailscale on this Mac and restart Switchboard. Then a code for your phone appears here.</p>
  return (
    <div className="flex items-center gap-4">
      <div aria-label="Pairing code for your phone" role="img" className="size-36 flex-none overflow-hidden rounded-lg bg-white p-1 [&_svg]:size-full" dangerouslySetInnerHTML={{ __html: markup }} />
      <p className="text-sm text-muted-foreground">
        Point your iPhone camera at this code while Tailscale is connected on the phone. It opens Switchboard at {tailscaleUrl} and signs you in. The code contains your access token, so do not share a screenshot of it.
      </p>
    </div>
  )
}
