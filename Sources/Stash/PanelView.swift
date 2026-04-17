import SwiftUI
import AppKit

struct PanelView: View {
    @ObservedObject var store: HistoryStore = HistoryStore.shared
    @State private var query: String = ""
    @State private var selection: Int = 0
    @FocusState private var searchFocused: Bool

    let onPaste: (ClipItem) -> Void
    let onClose: () -> Void

    private var filtered: [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return store.items }
        return store.items.filter { item in
            item.displayText.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            content
            Divider().opacity(0.4)
            footer
        }
        .frame(width: 520, height: 460)
        .background(VisualEffect().ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            selection = 0
            searchFocused = true
        }
        .onChange(of: query) { _, _ in
            selection = 0
        }
        .onChange(of: store.items.count) { _, _ in
            selection = min(selection, max(0, filtered.count - 1))
        }
        .background(KeyCatcher(handler: handleKey))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search clipboard history", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .font(.system(size: 14))
                .onSubmit { pasteSelected() }
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder private var content: some View {
        let list = filtered
        if list.isEmpty {
            VStack(spacing: 6) {
                Spacer()
                Image(systemName: "tray")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.secondary)
                Text(store.items.isEmpty ? "Nothing stashed yet — copy something." : "No matches.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(list.enumerated()), id: \.element.id) { idx, item in
                            RowView(
                                item: item,
                                index: idx,
                                isSelected: idx == selection,
                                onSelect: { selection = idx },
                                onPaste: { pasteAt(idx) },
                                onDelete: { delete(item) }
                            )
                            .id(idx)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .onChange(of: selection) { _, new in
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            hint("↑↓", "navigate")
            hint("⏎", "paste")
            hint("⌘⌫", "delete")
            hint("⌘1–9", "quick paste")
            Spacer()
            hint("esc", "close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.primary.opacity(0.1))
                )
            Text(label)
        }
    }

    // MARK: - Key handling

    private func handleKey(_ event: NSEvent) -> Bool {
        let list = filtered
        let cmd = event.modifierFlags.contains(.command)

        switch event.keyCode {
        case 53: // esc
            onClose()
            return true
        case 126: // up
            if !list.isEmpty {
                selection = max(0, selection - 1)
            }
            return true
        case 125: // down
            if !list.isEmpty {
                selection = min(list.count - 1, selection + 1)
            }
            return true
        case 36, 76: // return / numpad enter
            pasteSelected()
            return true
        case 51: // delete/backspace
            if cmd, !list.isEmpty {
                delete(list[selection])
                return true
            }
            return false
        case 38: // j
            if cmd, !list.isEmpty {
                selection = min(list.count - 1, selection + 1)
                return true
            }
            return false
        case 40: // k
            if cmd, !list.isEmpty {
                selection = max(0, selection - 1)
                return true
            }
            return false
        default:
            break
        }

        // ⌘1–9
        if cmd, let chars = event.charactersIgnoringModifiers, let n = Int(chars), n >= 1, n <= 9 {
            let idx = n - 1
            if idx < list.count {
                pasteAt(idx)
                return true
            }
        }
        return false
    }

    private func pasteSelected() {
        let list = filtered
        guard !list.isEmpty, selection < list.count else { return }
        onPaste(list[selection])
    }

    private func pasteAt(_ idx: Int) {
        let list = filtered
        guard idx < list.count else { return }
        onPaste(list[idx])
    }

    private func delete(_ item: ClipItem) {
        store.remove(id: item.id)
    }
}

private struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.state = .active
        v.blendingMode = .behindWindow
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct KeyCatcher: NSViewRepresentable {
    let handler: (NSEvent) -> Bool

    func makeNSView(context: Context) -> NSView {
        let v = CatcherView()
        v.handler = handler
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CatcherView)?.handler = handler
    }

    final class CatcherView: NSView {
        var handler: ((NSEvent) -> Bool)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self, self.window != nil else { return event }
                if self.handler?(event) == true {
                    return nil
                }
                return event
            }
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
