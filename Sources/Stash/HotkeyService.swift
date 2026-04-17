import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.v, modifiers: [.command, .shift]))
}

@MainActor
enum HotkeyService {
    static func register(onTrigger: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) {
            onTrigger()
        }
    }
}
