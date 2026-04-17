import AppKit
import SwiftUI

@MainActor
final class PanelController {
    static let shared = PanelController()

    private var panel: NSPanel?
    private var previousApp: NSRunningApplication?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?

    private init() {}

    var isOpen: Bool { panel?.isVisible == true }

    func toggle() {
        if isOpen { close() } else { show() }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication

        let panel = self.panel ?? makePanel()
        self.panel = panel

        let root = PanelView(
            onPaste: { [weak self] item in self?.paste(item) },
            onClose: { [weak self] in self?.close() }
        )
        panel.contentView = NSHostingView(rootView: root)
        panel.setContentSize(NSSize(width: 520, height: 460))

        centerOnScreen(panel)
        panel.orderFrontRegardless()
        panel.makeKey()

        attachClickOutsideMonitors()
    }

    func close() {
        detachClickOutsideMonitors()
        panel?.orderOut(nil)
        // Restore focus to previously-active app
        previousApp?.activate()
    }

    private func paste(_ item: ClipItem) {
        let prev = previousApp
        detachClickOutsideMonitors()
        panel?.orderOut(nil)
        Paster.paste(item, into: prev)
    }

    private func makePanel() -> NSPanel {
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable]
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: style,
            backing: .buffered,
            defer: false
        )
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.isMovableByWindowBackground = false
        p.isMovable = false
        p.isFloatingPanel = true
        p.level = .floating
        p.becomesKeyOnlyIfNeeded = false
        p.worksWhenModal = true
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.standardWindowButton(.closeButton)?.isHidden = true
        p.standardWindowButton(.miniaturizeButton)?.isHidden = true
        p.standardWindowButton(.zoomButton)?.isHidden = true
        return p
    }

    private func centerOnScreen(_ p: NSPanel) {
        guard let screen = NSScreen.main else { p.center(); return }
        let f = screen.visibleFrame
        let size = p.frame.size
        let x = f.midX - size.width / 2
        let y = f.midY - size.height / 2 + 60
        p.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func attachClickOutsideMonitors() {
        detachClickOutsideMonitors()
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // If click is outside our panel's content view, close. (Clicks on panel return the event untouched.)
            if let p = self?.panel, event.window !== p {
                Task { @MainActor in self?.close() }
            }
            return event
        }
    }

    private func detachClickOutsideMonitors() {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m); globalMouseMonitor = nil }
        if let m = localMouseMonitor { NSEvent.removeMonitor(m); localMouseMonitor = nil }
    }
}
