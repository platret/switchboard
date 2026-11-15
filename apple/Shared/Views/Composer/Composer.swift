import SwiftUI

struct Composer: View {
    let agent: Agent
    var onSent: () -> Void = {}

    @Environment(AppStore.self) private var store
    @State private var text = ""
    @State private var speech = SpeechRecognizer()
    @State private var dictationBase = ""
    @State private var dictated = ""
    @FocusState private var isFocused: Bool

    private var isOnline: Bool {
        store.connection == .connected
    }

    private var canSend: Bool {
        isOnline && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !agent.queue.isEmpty { QueueChips(agent: agent) }
            DictationStatus(state: speech.state)
            if !isOnline {
                Label("\(store.connection.label). Messages can be sent again once the host is back.", systemImage: "wifi.slash").font(.footnote).foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 2) {
                field
                MicrophoneButton(state: speech.state, action: toggleDictation).keyboardShortcut("d", modifiers: .command)
                if agent.status.isBusy {
                    ComposerButton(symbol: "stop.fill", label: "Stop \(agent.name)", fill: .primary) { store.stop(agentId: agent.id) }
                        .keyboardShortcut(".", modifiers: .command)
                }
                ComposerButton(symbol: "arrow.up", label: agent.status.isBusy ? "Add message to the queue" : "Send message", fill: Palette.cobalt, isEnabled: canSend, action: send)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .padding(.vertical, 4)
            .background(.background.secondary, in: shape)
            .overlay(shape.strokeBorder(isFocused ? Palette.cobalt.opacity(0.7) : Surface.hairline))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: Surface.readingWidth)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .onAppear(perform: restore)
        .onDisappear { speech.stop() }
        .onChange(of: text) { _, value in
            ComposerDrafts.save(value, for: agent.id)
            if speech.isBusy, value != dictated { speech.stop() }
        }
        .onChange(of: speech.transcript) { _, transcript in
            dictated = SpeechRecognizer.merge(base: dictationBase, transcript: transcript)
            text = dictated
        }
    }

    private var field: some View {
        TextField(agent.status.isBusy ? "Queue a message for \(agent.name)" : "Message \(agent.name)", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...8)
            .focused($isFocused)
            .padding(.vertical, 9)
            .modifier(ComposerKeys(onSend: send))
            .accessibilityLabel("Message to \(agent.name)")
    }

    private func restore() {
        text = ComposerDrafts.text(for: agent.id)
        #if os(macOS)
        isFocused = true
        #endif
    }

    private func toggleDictation() {
        if speech.isBusy {
            speech.stop()
            return
        }
        dictationBase = text
        dictated = text
        Task { await speech.start(localeIdentifier: store.settings.dictationLocale) }
    }

    private func send() {
        speech.stop()
        guard canSend, store.send(text, to: agent.id) else { return }
        text = ""
        dictationBase = ""
        isFocused = true
        onSent()
    }
}
