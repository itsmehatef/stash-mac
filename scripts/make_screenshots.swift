import Foundation
import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Theme

struct Theme {
    static let panelBG = Color(red: 0.11, green: 0.10, blue: 0.09, opacity: 0.96)
    static let panelHi = Color.white.opacity(0.06)
    static let border  = Color.white.opacity(0.08)
    static let fg      = Color.white.opacity(0.92)
    static let fgDim   = Color.white.opacity(0.52)
    static let fgVeryDim = Color.white.opacity(0.28)
    static let amber   = Color(red: 0.82, green: 0.43, blue: 0.22)
    static let sage    = Color(red: 0.45, green: 0.70, blue: 0.52)
    static let mono    = Font.system(.body, design: .monospaced).weight(.regular)
    static let monoSmall = Font.system(.caption, design: .monospaced)
    static let serif = Font.custom("Georgia", size: 16)
}

// MARK: - Mock models

enum ClipKind { case text, url, image, file }
struct ClipItem: Identifiable {
    let id = UUID()
    let kind: ClipKind
    let preview: String
    let meta: String
    let ago: String
}

let mockClips: [ClipItem] = [
    .init(kind: .url,   preview: "https://github.com/itsmehatef/stash-mac", meta: "github.com",     ago: "just now"),
    .init(kind: .text,  preview: "The Uptown — Mill Creek — eff $1,823 / 650 sqft / 4min 19th St BART", meta: "text · 72 chars", ago: "1m"),
    .init(kind: .image, preview: "Screen Shot 2026-04-17 at 6.42 PM.png", meta: "image · 1920×1200", ago: "4m"),
    .init(kind: .text,  preview: "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", meta: "text · 60 chars · looks like a secret", ago: "12m"),
    .init(kind: .file,  preview: "~/Downloads/lease-residences-lake-merritt.pdf", meta: "file · 241 KB", ago: "32m"),
    .init(kind: .text,  preview: "brew tap itsmehatef/tap && brew install --cask stash-mac", meta: "text · command", ago: "1h"),
    .init(kind: .text,  preview: "(415) 555-0128", meta: "text · phone number", ago: "3h"),
]

// MARK: - Panel view

struct PanelView: View {
    @State var selected: Int = 1
    let clips: [ClipItem] = mockClips

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.fgDim)
                Text("macarthur")
                    .font(.system(.body, design: .default))
                    .foregroundStyle(Theme.fg)
                Spacer()
                Text("7")
                    .font(Theme.monoSmall)
                    .foregroundStyle(Theme.fgDim)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.panelHi))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Theme.panelHi)

            Divider().background(Theme.border)

            // List
            VStack(spacing: 0) {
                ForEach(Array(clips.enumerated()), id: \.offset) { (idx, clip) in
                    RowView(clip: clip, selected: idx == selected, shortcut: idx < 9 ? "\u{2318}\(idx+1)" : nil)
                    if idx < clips.count - 1 { Divider().background(Theme.border.opacity(0.5)) }
                }
            }
            Spacer(minLength: 0)

            // Footer hint
            Divider().background(Theme.border)
            HStack(spacing: 18) {
                hint(key: "↑↓", label: "navigate")
                hint(key: "⌘1–9", label: "quick-pick")
                hint(key: "⏎", label: "paste")
                hint(key: "⌘⌫", label: "delete")
                Spacer()
                hint(key: "esc", label: "close")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 640, height: 520)
        .background(Theme.panelBG)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    func hint(key: String, label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(Theme.monoSmall)
                .foregroundStyle(Theme.fg)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 3).fill(Theme.panelHi))
            Text(label)
                .font(.system(.caption))
                .foregroundStyle(Theme.fgDim)
        }
    }
}

struct RowView: View {
    let clip: ClipItem
    let selected: Bool
    let shortcut: String?

    var body: some View {
        HStack(spacing: 12) {
            iconView
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.panelHi))

            VStack(alignment: .leading, spacing: 3) {
                Text(clip.preview)
                    .font(clip.kind == .text || clip.kind == .url ? .system(.body, design: .monospaced) : .system(.body))
                    .foregroundStyle(selected ? .white : Theme.fg)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(clip.meta)
                    .font(Theme.monoSmall)
                    .foregroundStyle(Theme.fgDim)
            }

            Spacer()

            if let s = shortcut {
                Text(s)
                    .font(Theme.monoSmall)
                    .foregroundStyle(Theme.fgDim)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.panelHi))
            }

            Text(clip.ago)
                .font(Theme.monoSmall)
                .foregroundStyle(Theme.fgVeryDim)
                .frame(width: 48, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(selected ? Theme.amber.opacity(0.22) : Color.clear)
        .overlay(alignment: .leading) {
            if selected {
                Rectangle().fill(Theme.amber).frame(width: 3)
            }
        }
    }

    @ViewBuilder
    var iconView: some View {
        switch clip.kind {
        case .text:
            Image(systemName: "text.alignleft").foregroundStyle(Theme.fgDim)
        case .url:
            Image(systemName: "link").foregroundStyle(Theme.sage)
        case .image:
            Image(systemName: "photo").foregroundStyle(Theme.amber)
        case .file:
            Image(systemName: "doc").foregroundStyle(Theme.fgDim)
        }
    }
}

// MARK: - Settings view

struct SettingsMockView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title bar
            HStack {
                Circle().fill(Color(red: 1.0, green: 0.38, blue: 0.36)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.30)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.21, green: 0.79, blue: 0.36)).frame(width: 12, height: 12)
                Spacer()
                Text("Stash — Settings")
                    .font(.system(.callout, design: .default).weight(.medium))
                    .foregroundStyle(.primary.opacity(0.75))
                Spacer()
                Color.clear.frame(width: 48)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.96, green: 0.96, blue: 0.95))

            Divider()

            // Form
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    label("Hotkey")
                    HStack(spacing: 8) {
                        keyCap("⌘")
                        keyCap("⇧")
                        keyCap("V")
                        Text("·  click to rebind")
                            .font(.system(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                Group {
                    label("History capacity")
                    HStack(spacing: 10) {
                        sliderMock(value: 0.20)
                        Text("5 items")
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }
                Group {
                    label("Capture")
                    toggleRow(title: "Text",        on: true)
                    toggleRow(title: "Images",      on: true)
                    toggleRow(title: "File refs",   on: false)
                }
                Group {
                    label("Behavior")
                    toggleRow(title: "Persist history across restarts", on: false)
                    toggleRow(title: "Launch at login",                 on: true)
                }
            }
            .padding(20)

            Divider()

            HStack {
                Text("v0.1.0 · MIT · hatef kasraei")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Clear all history")
                    .font(.system(.callout))
                    .foregroundStyle(Color(red: 0.72, green: 0.22, blue: 0.12))
            }
            .padding(14)
        }
        .frame(width: 520, height: 560)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
    }

    func label(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(.caption).weight(.semibold))
            .tracking(1.0)
            .foregroundStyle(.secondary)
    }
    func keyCap(_ s: String) -> some View {
        Text(s)
            .font(.system(.title3, design: .monospaced).weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.97))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
    }
    func toggleRow(title: String, on: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(.body))
                .foregroundStyle(.primary)
            Spacer()
            RoundedRectangle(cornerRadius: 14)
                .fill(on ? Color(red: 0.22, green: 0.68, blue: 0.38) : Color(red: 0.82, green: 0.82, blue: 0.82))
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                        .offset(x: on ? 9 : -9)
                )
        }
    }
    func sliderMock(value: Double) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.08)).frame(height: 4)
                Capsule().fill(Color.accentColor).frame(width: g.size.width * value, height: 4)
                Circle().fill(.white).frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    .offset(x: g.size.width * value - 8)
            }
        }
        .frame(height: 16)
    }
}

// MARK: - Menu bar strip

struct MenuBarStrip: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("")
                .font(.system(size: 14))
            Spacer().frame(width: 12)
            Text("Notion  Finder  View  Edit  Help")
                .font(.system(size: 13).weight(.regular))
                .foregroundStyle(.primary.opacity(0.85))
            Spacer()
            HStack(spacing: 14) {
                Image(systemName: "clock")
                Image(systemName: "battery.75")
                Image(systemName: "wifi")
                Image(systemName: "magnifyingglass")
                Image(systemName: "switch.2")
                StashBarIcon()
                Text("Wed 6:42 PM")
                    .font(.system(size: 13))
            }
            .foregroundStyle(.primary.opacity(0.85))
            .padding(.trailing, 18)
        }
        .frame(height: 28)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .background(Color(red: 0.95, green: 0.95, blue: 0.93))
    }
}

struct StashBarIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.primary.opacity(0.7), lineWidth: 1.4)
                .frame(width: 11, height: 13)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(0.7))
                .frame(width: 5, height: 2.5)
                .offset(y: -7)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.amber.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Theme.amber, lineWidth: 1)
        )
    }
}

// MARK: - Render

@MainActor
func render(_ view: some View, to url: URL, scale: CGFloat = 2.0) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    renderer.isOpaque = false
    guard let img = renderer.cgImage else {
        throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "render produced nil"])
    }
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "render", code: 2)
    }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.lastPathComponent) (\(img.width)×\(img.height))")
}

let args = CommandLine.arguments
let outDir: URL
if args.count >= 2 {
    outDir = URL(fileURLWithPath: args[1], isDirectory: true)
} else {
    outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("docs/screenshots", isDirectory: true)
}
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// Wrap rendering in a padded, shadowed frame so the panels look like floating shots

struct ShotFrame<C: View>: View {
    let tint: Color
    @ViewBuilder let content: C
    var body: some View {
        content
            .padding(40)
            .background(
                LinearGradient(colors: [tint.opacity(0.28), tint.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
    }
}

@MainActor
func main() async {
    do {
        try render(
            ShotFrame(tint: Theme.amber) { PanelView() }
                .shadow(color: .black.opacity(0.45), radius: 30, y: 20),
            to: outDir.appendingPathComponent("panel.png")
        )
        try render(
            ShotFrame(tint: Color(red: 0.60, green: 0.65, blue: 0.70)) { SettingsMockView() }
                .shadow(color: .black.opacity(0.30), radius: 24, y: 16),
            to: outDir.appendingPathComponent("settings.png")
        )
        try render(
            MenuBarStrip().frame(width: 980)
                .padding(.bottom, 16)
                .background(Color(red: 0.95, green: 0.95, blue: 0.93)),
            to: outDir.appendingPathComponent("menubar.png")
        )
    } catch {
        print("render error: \(error)")
        exit(1)
    }
}

await main()
