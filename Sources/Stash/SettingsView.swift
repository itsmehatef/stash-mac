import SwiftUI
import AppKit
import KeyboardShortcuts
import ServiceManagement

struct SettingsView: View {
    @ObservedObject private var prefs = Preferences.shared

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Show history:", name: .togglePanel)
            }
            Section("History") {
                HStack {
                    Text("Capacity")
                    Slider(value: Binding(
                        get: { Double(prefs.capacity) },
                        set: { newValue in
                            prefs.capacity = Int(newValue.rounded())
                            HistoryStore.shared.setCapacity(prefs.capacity)
                        }
                    ), in: 1...100, step: 1)
                    Text("\(prefs.capacity)")
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)
                }
                Toggle("Persist history across restarts", isOn: Binding(
                    get: { prefs.persistHistory },
                    set: { newValue in
                        prefs.persistHistory = newValue
                        HistoryStore.shared.setPersistence(newValue)
                    }
                ))
            }
            Section("Capture types") {
                Toggle("Text", isOn: $prefs.enableText)
                Toggle("Images", isOn: $prefs.enableImages)
                Toggle("Files", isOn: $prefs.enableFiles)
            }
            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { newValue in
                        setLaunchAtLogin(newValue)
                    }
                ))
            }
            Section {
                HStack {
                    Text("Stash v0.1").foregroundStyle(.secondary)
                    Spacer()
                    Text("© 2026 Hatef Kasraei").foregroundStyle(.secondary)
                }
                .font(.system(size: 11))
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 460)
    }

    private func setLaunchAtLogin(_ on: Bool) {
        let service = SMAppService.mainApp
        do {
            if on {
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                try service.unregister()
            }
            prefs.launchAtLogin = on
        } catch {
            NSLog("Stash: launch-at-login toggle failed: \(error)")
            // reflect real state
            prefs.launchAtLogin = (service.status == .enabled)
        }
    }
}

@MainActor
final class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: SettingsView())
        let w = NSWindow(contentViewController: hosting)
        w.title = "Stash Settings"
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.isReleasedWhenClosed = false
        w.center()
        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
