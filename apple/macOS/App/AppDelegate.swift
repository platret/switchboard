import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        MacSession.shared.launch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MacSession.shared.showMainWindow()
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let session = MacSession.shared
        let busy = session.store.workingCount + session.store.waitingCount
        guard session.host.ownsProcess, busy > 0 else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Quit and stop the host?"
        alert.informativeText = "\(busy == 1 ? "1 agent is" : "\(busy) agents are") still working. Switchboard started the host, so quitting stops it and interrupts them."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        MacSession.shared.host.releaseProcess()
    }
}
