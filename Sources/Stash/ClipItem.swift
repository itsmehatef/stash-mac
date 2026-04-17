import Foundation
import AppKit
import CryptoKit

enum ClipKind: String, Codable {
    case text
    case image
    case file
}

struct ClipItem: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: ClipKind
    let date: Date
    let hash: String

    // text payload
    var text: String?

    // image payload: stored as PNG data on disk via Persistence; kept here as PNG bytes
    var imageData: Data?

    // file URL payload (file-url)
    var fileURLString: String?

    init(id: UUID = UUID(),
         kind: ClipKind,
         date: Date = Date(),
         hash: String,
         text: String? = nil,
         imageData: Data? = nil,
         fileURLString: String? = nil) {
        self.id = id
        self.kind = kind
        self.date = date
        self.hash = hash
        self.text = text
        self.imageData = imageData
        self.fileURLString = fileURLString
    }

    var displayText: String {
        switch kind {
        case .text:
            return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .image:
            if let d = imageData {
                let kb = max(1, d.count / 1024)
                return "Image · \(kb) KB"
            }
            return "Image"
        case .file:
            if let s = fileURLString, let url = URL(string: s) {
                return url.lastPathComponent
            }
            return fileURLString ?? "File"
        }
    }

    var thumbnail: NSImage? {
        switch kind {
        case .image:
            guard let d = imageData else { return nil }
            return NSImage(data: d)
        case .file:
            if let s = fileURLString, let url = URL(string: s) {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return nil
        case .text:
            return nil
        }
    }

    var typeBadge: String {
        switch kind {
        case .text: return "TEXT"
        case .image: return "IMG"
        case .file: return "FILE"
        }
    }

    static func hashBytes(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
