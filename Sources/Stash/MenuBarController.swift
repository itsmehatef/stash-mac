import AppKit
import KeyboardShortcuts

@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Stash")
            button.image?.isTemplate = true
            button.toolTip = "Stash — clipboard history"
        }
        item.menu = buildMenu()
        self.statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let shortcutLabel = KeyboardShortcuts.getShortcut(for: .togglePanel)?.description ?? "⌘⇧V"
        let show = NSMenuItem(title: "Show history  (\(shortcutLabel))",
                              action: #selector(showHistory),
                              keyEquivalent: "")
        show.target = self
        menu.addItem(show)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        settings.keyEquivalentModifierMask = [.command]
        menu.addItem(settings)

        let clear = NSMenuItem(title: "Clear history", action: #selector(clearHistory), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Stash", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        quit.keyEquivalentModifierMask = [.command]
        menu.addItem(quit)

        return menu
    }

    @objc private func showHistory() {
        PanelController.shared.show()
    }

    @objc private func openSettings() {
        SettingsWindow.shared.show()
    }

    @objc private func clearHistory() {
        HistoryStore.shared.clear()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
