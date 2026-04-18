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
print("using brew at \(brew)")

for cmd in [
    ["untap", "itsmehatef/tap"],          // clean slate; may fail if not tapped — ignored
    ["tap", "itsmehatef/tap"],
    ["info", "--cask", "stash-mac"],
    ["style", "--cask", "stash-mac"],
] {
    let (rc, out) = run(brew, cmd)
    print("--- brew \(cmd.joined(separator: " ")) ---")
    print(out.trimmingCharacters(in: .whitespacesAndNewlines))
    print("  → exit \(rc)")
}
