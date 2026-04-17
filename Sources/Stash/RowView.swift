import SwiftUI
import AppKit

struct RowView: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onPaste: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            iconView
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(previewText)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                HStack(spacing: 6) {
                    Text(item.typeBadge)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.18))
                        )
                        .foregroundStyle(Color.accentColor)
                    Text(ago(item.date))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)

            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onPaste() }
        .onTapGesture(count: 1) { onSelect() }
        .contextMenu {
            Button("Paste") { onPaste() }
            Button("Delete", role: .destructive) { onDelete() }
        }
    }

    @ViewBuilder private var iconView: some View {
        if let thumb = item.thumbnail {
            Image(nsImage: thumb)
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        } else {
            Image(systemName: systemIcon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private var systemIcon: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .file: return "doc"
        }
    }

    private var previewText: String {
        let t = item.displayText
        if item.kind == .text {
            let lines = t.split(whereSeparator: { $0.isNewline }).prefix(2)
            return lines.joined(separator: " ")
        }
        return t
    }

    private func ago(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
