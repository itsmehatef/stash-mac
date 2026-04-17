import Foundation
import AppKit

@MainActor
final class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let prefs = Preferences.shared

    // Set by Paster when we write our own payload; monitor skips those change-counts.
    var ignoreNextChange: Bool = false

    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        stop()
        let t = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let cc = pasteboard.changeCount
        guard cc != lastChangeCount else { return }
        lastChangeCount = cc
        if ignoreNextChange {
            ignoreNextChange = false
            return
        }
        capture()
    }

    private func capture() {
        guard let types = pasteboard.types else { return }

        // file URLs first
        if prefs.enableFiles, types.contains(.fileURL) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                for url in urls {
                    let key = url.path.data(using: .utf8) ?? Data()
                    let h = ClipItem.hashBytes(key)
                    let item = ClipItem(kind: .file, hash: h, fileURLString: url.absoluteString)
                    HistoryStore.shared.add(item)
                }
                return
            }
        }

        // images
        if prefs.enableImages {
            if types.contains(.png), let data = pasteboard.data(forType: .png) {
                let h = ClipItem.hashBytes(data)
                HistoryStore.shared.add(ClipItem(kind: .image, hash: h, imageData: data))
                return
            }
            if types.contains(.tiff), let data = pasteboard.data(forType: .tiff) {
                // normalize to PNG for storage/display
                if let rep = NSBitmapImageRep(data: data),
                   let png = rep.representation(using: .png, properties: [:]) {
                    let h = ClipItem.hashBytes(png)
                    HistoryStore.shared.add(ClipItem(kind: .image, hash: h, imageData: png))
                    return
                }
            }
        }

        // text (prefer plain; fall back to RTF → plain)
        if prefs.enableText {
            if let s = pasteboard.string(forType: .string), !s.isEmpty {
                let trimmed = s
                let bytes = trimmed.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) ?? Data()
                if bytes.isEmpty { return }
                let h = ClipItem.hashBytes(bytes)
                HistoryStore.shared.add(ClipItem(kind: .text, hash: h, text: trimmed))
                return
            }
            if types.contains(.rtf), let data = pasteboard.data(forType: .rtf),
               let attr = try? NSAttributedString(data: data, options: [:], documentAttributes: nil) {
                let s = attr.string
                if !s.isEmpty {
                    let bytes = s.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) ?? Data()
                    if bytes.isEmpty { return }
                    let h = ClipItem.hashBytes(bytes)
                    HistoryStore.shared.add(ClipItem(kind: .text, hash: h, text: s))
                }
            }
        }
    }
}
