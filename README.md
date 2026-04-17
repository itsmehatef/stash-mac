# Stash

Tiny macOS clipboard history app. Menu-bar only, pops up on `⌘⇧V`, pastes into whatever app you were just in.

<!-- screenshot -->

**Apple Silicon only · macOS 14+ · no code-signing** — first launch: right-click the app → **Open**.

## What it does

- Watches the system pasteboard and keeps the last N items (default 5, configurable up to 100).
- Global hotkey pops a centered floating panel with a search field and your history.
- ⏎ pastes the selected item into the previously-active app. Your caret stays where it was.
- Supports **text**, **images**, and **file references**. Each type is toggleable.
- Optional persistence to `~/Library/Application Support/Stash/`.
- Launch-at-login via `SMAppService`.

## Install (from source)

```sh
git clone https://github.com/itsmehatef/stash-mac.git
cd stash-mac
brew install xcodegen
xcodegen generate
xcodebuild -project Stash.xcodeproj -scheme Stash -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY='-' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

The `.app` ends up in `~/Library/Developer/Xcode/DerivedData/Stash-*/Build/Products/Release/Stash.app`. Drag it to `/Applications`. First launch: right-click → **Open** to bypass Gatekeeper.

## Keyboard shortcuts

| Key | Action |
|---|---|
| `⌘⇧V` | Show / hide the panel (rebindable in Settings) |
| `↑` / `↓`, `⌘J` / `⌘K` | Navigate |
| `⏎` | Paste selected into previous app |
| `⌘⌫` | Delete selected item |
| `⌘1`–`⌘9` | Paste Nth item |
| `esc` | Close panel |

Start typing to filter.

## Settings

Menu bar icon → **Settings…**

- Hotkey recorder
- History capacity (1–100)
- Persist history (off by default)
- Capture: text / images / files
- Launch at login

## Build

Requires Xcode 15+, Apple Silicon, macOS 14+. Build with the xcodebuild command above, or open `Stash.xcodeproj` in Xcode after `xcodegen generate`.

Dependency: [`sindresorhus/KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) (SwiftPM, pinned in `Package.resolved`).

## License

MIT — © 2026 Hatef Kasraei
