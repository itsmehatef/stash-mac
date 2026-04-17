import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        MenuBarController.shared.install()
        ClipboardMonitor.shared.start()

        HotkeyService.register {
            PanelController.shared.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stop()
    }
}
