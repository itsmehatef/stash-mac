import Foundation

func run(_ path: String, _ args: [String]) -> (Int32, String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, "launch error: \(error)") }
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

let brew = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"].first { FileManager.default.fileExists(atPath: $0) } ?? ""
guard !brew.isEmpty else { print("brew not found"); exit(2) }

// Remove any pre-existing /Applications/Stash.app from a prior manual install
let manual = "/Applications/Stash.app"
if FileManager.default.fileExists(atPath: manual) {
    do {
        try FileManager.default.removeItem(atPath: manual)
        print("removed stale \(manual)")
    } catch {
        print("could not remove \(manual): \(error)")
    }
}

for cmd in [
    ["update"],
    ["uninstall", "--cask", "--zap", "stash-mac"],          // ignore failure if not installed
    ["install", "--cask", "stash-mac"],
    ["list", "--cask", "--versions", "stash-mac"],
] {
    let (rc, out) = run(brew, cmd)
    print("--- brew \(cmd.joined(separator: " ")) ---")
    print(out.trimmingCharacters(in: .whitespacesAndNewlines))
    print("  → exit \(rc)")
}

// Verify the app is installed
let appPath = "/Applications/Stash.app"
if FileManager.default.fileExists(atPath: appPath) {
    print("✓ \(appPath) exists")
    let (_, out) = run("/usr/bin/mdls", ["-name", "kMDItemVersion", appPath])
    print(out.trimmingCharacters(in: .whitespacesAndNewlines))
} else {
    print("✗ \(appPath) missing!")
    exit(1)
}
