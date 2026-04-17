import Foundation
import AppKit

@MainActor
enum Paster {
    /// Writes the item to pasteboard and synthesizes ⌘V in the previously-active app.
    static func paste(_ item: ClipItem, into target: NSRunningApplication?) {
        writeToPasteboard(item)

        // Activate the previously-active app first, then send ⌘V.
        if let target {
            target.activate()
        }

        // Small delay so the activation settles and our panel is fully gone.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            sendCommandV()
        }
    }

    static func writeToPasteboard(_ item: ClipItem) {
        ClipboardMonitor.shared.ignoreNextChange = true
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .text:
            if let t = item.text {
                pb.setString(t, forType: .string)
            }
        case .image:
            if let d = item.imageData {
                pb.setData(d, forType: .png)
            }
        case .file:
            if let s = item.fileURLString, let url = URL(string: s) {
                pb.writeObjects([url as NSURL])
            }
        }
    }

    private static func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09 // 'v'
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
