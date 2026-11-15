import { useCallback, useEffect, useRef, useState } from 'react'
import { useStore } from './store.ts'

type RecognitionResult = { isFinal: boolean; 0: { transcript: string } }
type RecognitionEvent = { resultIndex: number; results: ArrayLike<RecognitionResult> }
type Recognition = {
  lang: string
  continuous: boolean
  interimResults: boolean
  onresult: ((event: RecognitionEvent) => void) | null
  onend: (() => void) | null
  onerror: ((event: { error: string }) => void) | null
  start: () => void
  stop: () => void
  abort: () => void
}
type RecognitionConstructor = new () => Recognition

declare global {
  interface Window {
    SpeechRecognition?: RecognitionConstructor
    webkitSpeechRecognition?: RecognitionConstructor
  }
}

const Constructor = window.SpeechRecognition ?? window.webkitSpeechRecognition

export const dictationSupported = Constructor !== undefined && window.isSecureContext

const errorTexts: Record<string, string> = {
  'not-allowed': 'Microphone access was denied. Allow it in the browser settings for this site.',
  'service-not-allowed': 'Speech recognition is not allowed in this browser.',
  'audio-capture': 'No microphone was found.',
  network: 'Speech recognition needs a network connection in this browser.',
}

export function useDictation(onText: (text: string) => void) {
  const [listening, setListening] = useState(false)
  const [interim, setInterim] = useState('')
  const recognition = useRef<Recognition | null>(null)
  const deliver = useRef(onText)
  deliver.current = onText

  const stop = useCallback(() => recognition.current?.stop(), [])

  const start = useCallback(() => {
    if (!Constructor || recognition.current) return
    const session = new Constructor()
    const { voiceLanguage, setNotice } = useStore.getState()
    session.lang = voiceLanguage || navigator.language
    session.continuous = true
    session.interimResults = true
    session.onresult = (event) => {
      let pending = ''
      for (let index = event.resultIndex; index < event.results.length; index++) {
        const result = event.results[index]
        if (!result) continue
        if (result.isFinal) deliver.current(result[0].transcript.trim())
        else pending += result[0].transcript
      }
      setInterim(pending)
    }
    session.onerror = (event) => {
      const text = errorTexts[event.error]
      if (text) setNotice(text)
    }
    session.onend = () => {
      recognition.current = null
      setListening(false)
      setInterim('')
    }
    recognition.current = session
    setListening(true)
    session.start()
  }, [])

  useEffect(() => () => recognition.current?.abort(), [])

  return { listening, interim, toggle: listening ? stop : start }
}
