import { query, type Options, type Query, type SDKMessage, type SDKUserMessage } from '@anthropic-ai/claude-agent-sdk'

type RunnerEvents = {
  onMessage: (message: SDKMessage) => void
  onExit: (error: Error | null) => void
}

type Feed = {
  closed: boolean
  wake: (() => void) | null
}

type Session = {
  feed: Feed
  query: Query
}

export class AgentRunner {
  private readonly pending: SDKUserMessage[] = []
  private session: Session | null = null

  constructor(
    private readonly buildOptions: () => Options,
    private readonly events: RunnerEvents,
  ) {}

  get active(): boolean {
    return this.session !== null
  }

  send(text: string): void {
    this.pending.push({ type: 'user', message: { role: 'user', content: text }, parent_tool_use_id: null })
    if (this.session) this.session.feed.wake?.()
    else this.start()
  }

  async interrupt(): Promise<void> {
    await this.session?.query.interrupt()
  }

  close(): void {
    const session = this.session
    if (!session) return
    this.end(session)
    session.query.close()
  }

  private start(): void {
    const feed: Feed = { closed: false, wake: null }
    const session: Session = { feed, query: query({ prompt: this.input(feed), options: this.buildOptions() }) }
    this.session = session
    void this.consume(session)
  }

  private async *input(feed: Feed): AsyncGenerator<SDKUserMessage> {
    while (!feed.closed) {
      const next = this.pending.shift()
      if (next) yield next
      else await new Promise<void>((resolve) => (feed.wake = resolve))
    }
  }

  private async consume(session: Session): Promise<void> {
    let error: Error | null = null
    try {
      for await (const message of session.query) this.events.onMessage(message)
    } catch (cause) {
      error = cause instanceof Error ? cause : new Error(String(cause))
    }
    const wasClosed = session.feed.closed
    this.end(session)
    this.pending.length = 0
    this.events.onExit(wasClosed ? null : (error ?? new Error('Agent process ended unexpectedly')))
  }

  private end(session: Session): void {
    session.feed.closed = true
    session.feed.wake?.()
    if (this.session === session) this.session = null
  }
}
