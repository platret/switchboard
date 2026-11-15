import { useState } from 'react'
import { copyText } from './copyText.ts'
import { useStore } from './store.ts'

export function useCopied(): [boolean, (text: string) => Promise<void>] {
  const [copied, setCopied] = useState(false)
  const copy = async (text: string) => {
    if (!(await copyText(text))) return useStore.getState().setNotice('Copying is not available in this browser.')
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }
  return [copied, copy]
}
