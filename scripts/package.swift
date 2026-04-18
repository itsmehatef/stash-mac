import Foundation

let fm = FileManager.default
let home = URL(fileURLWithPath: NSHomeDirectory())
let dds = (try? fm.contentsOfDirectory(at: home.appendingPathComponent("Library/Developer/Xcode/DerivedData"), includingPropertiesForKeys: nil)) ?? []
guard let stashDD = dds.first(where: { $0.lastPathComponent.hasPrefix("Stash-") }) else {
    fputs("no Stash DerivedData found\n", stderr); exit(2)
}
let appURL = stashDD.appendingPathComponent("Build/Products/Release/Stash.app")
guard fm.fileExists(atPath: appURL.path) else {
    fputs("Stash.app not found at \(appURL.path)\n", stderr); exit(3)
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    fputs("usage: swift package.swift <dist-dir> <version>\n", stderr); exit(1)
}
let distDir = URL(fileURLWithPath: args[1])
let version = args[2]
try? fm.createDirectory(at: distDir, withIntermediateDirectories: true)
let zipURL = distDir.appendingPathComponent("Stash-\(version).zip")
try? fm.removeItem(at: zipURL)

print("src : \(appURL.path)")
print("dest: \(zipURL.path)")

let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
p.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", appURL.path, zipURL.path]
try p.run()
p.waitUntilExit()
guard p.terminationStatus == 0 else {
    fputs("ditto failed with \(p.terminationStatus)\n", stderr); exit(Int32(p.terminationStatus))
}

let attrs = (try? fm.attributesOfItem(atPath: zipURL.path)) ?? [:]
let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
print("wrote \(zipURL.lastPathComponent) · \(size) bytes")
