import Foundation

enum Persistence {
    static var appSupportDir: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Stash", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var blobsDir: URL {
        let dir = appSupportDir.appendingPathComponent("blobs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static var historyFile: URL {
        appSupportDir.appendingPathComponent("history.json")
    }

    // Serialized form — images are stored as blob files referenced by hash, not inline.
    private struct StoredItem: Codable {
        let id: UUID
        let kind: ClipKind
        let date: Date
        let hash: String
        let text: String?
        let imageBlobName: String?
        let fileURLString: String?
    }

    static func save(_ items: [ClipItem]) {
        let stored: [StoredItem] = items.map { item in
            var blobName: String? = nil
            if item.kind == .image, let data = item.imageData {
                let name = "\(item.hash).png"
                let url = blobsDir.appendingPathComponent(name)
                if !FileManager.default.fileExists(atPath: url.path) {
                    try? data.write(to: url, options: .atomic)
                }
                blobName = name
            }
            return StoredItem(id: item.id,
                              kind: item.kind,
                              date: item.date,
                              hash: item.hash,
                              text: item.text,
                              imageBlobName: blobName,
                              fileURLString: item.fileURLString)
        }
        do {
            let data = try JSONEncoder().encode(stored)
            try data.write(to: historyFile, options: .atomic)
            pruneBlobs(referenced: Set(stored.compactMap { $0.imageBlobName }))
        } catch {
            NSLog("Stash: failed to save history: \(error)")
        }
    }

    static func load() -> [ClipItem] {
        guard let data = try? Data(contentsOf: historyFile) else { return [] }
        guard let stored = try? JSONDecoder().decode([StoredItem].self, from: data) else { return [] }
        return stored.map { s in
            var imageData: Data? = nil
            if let name = s.imageBlobName {
                let url = blobsDir.appendingPathComponent(name)
                imageData = try? Data(contentsOf: url)
            }
            return ClipItem(id: s.id,
                            kind: s.kind,
                            date: s.date,
                            hash: s.hash,
                            text: s.text,
                            imageData: imageData,
                            fileURLString: s.fileURLString)
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: historyFile)
        if let items = try? FileManager.default.contentsOfDirectory(at: blobsDir, includingPropertiesForKeys: nil) {
            for url in items {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private static func pruneBlobs(referenced: Set<String>) {
        guard let items = try? FileManager.default.contentsOfDirectory(at: blobsDir, includingPropertiesForKeys: nil) else { return }
        for url in items where !referenced.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
