import Foundation
import Combine
import AppKit

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var items: [ClipItem] = []

    private let prefs = Preferences.shared
    private var saveDebounce: DispatchWorkItem?

    private init() {
        if prefs.persistHistory {
            self.items = Persistence.load()
            trim()
        }
    }

    func add(_ item: ClipItem) {
        if let existing = items.firstIndex(where: { $0.hash == item.hash }) {
            var moved = items.remove(at: existing)
            moved = ClipItem(id: moved.id,
                             kind: moved.kind,
                             date: Date(),
                             hash: moved.hash,
                             text: moved.text,
                             imageData: moved.imageData,
                             fileURLString: moved.fileURLString)
            items.insert(moved, at: 0)
        } else {
            items.insert(item, at: 0)
        }
        trim()
        scheduleSave()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        scheduleSave()
    }

    func clear() {
        items.removeAll()
        if prefs.persistHistory {
            Persistence.clear()
        }
    }

    func setCapacity(_ n: Int) {
        _ = n
        trim()
        scheduleSave()
    }

    func setPersistence(_ on: Bool) {
        if on {
            Persistence.save(items)
        } else {
            Persistence.clear()
        }
    }

    private func trim() {
        let cap = max(1, min(100, prefs.capacity))
        if items.count > cap {
            items.removeSubrange(cap..<items.count)
        }
    }

    private func scheduleSave() {
        guard prefs.persistHistory else { return }
        saveDebounce?.cancel()
        let snapshot = items
        let work = DispatchWorkItem {
            Persistence.save(snapshot)
        }
        saveDebounce = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.4, execute: work)
    }
}
