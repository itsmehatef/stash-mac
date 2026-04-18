import Foundation
import CoreGraphics
import AppKit
import ImageIO
import UniformTypeIdentifiers

// Render the Stash app icon at all macOS AppIcon sizes via CoreGraphics.
// Output: PNGs into Assets.xcassets/AppIcon.appiconset/ + Contents.json

let here = URL(fileURLWithPath: (CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath), isDirectory: true)
let outDir = here.appendingPathComponent("Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// Dimensions requested for AppIcon.appiconset
// (filename, pixel-size, "scale-suffix/idiom entry")
struct Spec {
    let file: String
    let size: Int
    let idiom = "mac"
    let base: Int
    let scale: Int
}
let specs: [Spec] = [
    .init(file: "icon_16x16.png",      size: 16,   base: 16, scale: 1),
    .init(file: "icon_16x16@2x.png",   size: 32,   base: 16, scale: 2),
    .init(file: "icon_32x32.png",      size: 32,   base: 32, scale: 1),
    .init(file: "icon_32x32@2x.png",   size: 64,   base: 32, scale: 2),
    .init(file: "icon_128x128.png",    size: 128,  base: 128, scale: 1),
    .init(file: "icon_128x128@2x.png", size: 256,  base: 128, scale: 2),
    .init(file: "icon_256x256.png",    size: 256,  base: 256, scale: 1),
    .init(file: "icon_256x256@2x.png", size: 512,  base: 256, scale: 2),
    .init(file: "icon_512x512.png",    size: 512,  base: 512, scale: 1),
    .init(file: "icon_512x512@2x.png", size: 1024, base: 512, scale: 2),
]

// --- Drawing -----------------------------------------------------------------

// Palette
let bgTopColor    = CGColor(red: 0x2f/255.0, green: 0xa9/255.0, blue: 0x83/255.0, alpha: 1)  // not used
let amberTop      = CGColor(red: 0xdb/255.0, green: 0x6d/255.0, blue: 0x3b/255.0, alpha: 1)
let amberMid      = CGColor(red: 0xb8/255.0, green: 0x49/255.0, blue: 0x1f/255.0, alpha: 1)
let amberBot      = CGColor(red: 0x6b/255.0, green: 0x24/255.0, blue: 0x08/255.0, alpha: 1)
let paperTop      = CGColor(red: 1, green: 1, blue: 0.98, alpha: 1)
let paperMid      = CGColor(red: 0.93, green: 0.85, blue: 0.70, alpha: 1)
let paperBot      = CGColor(red: 0.87, green: 0.77, blue: 0.60, alpha: 1)
let clipDark      = CGColor(red: 0x1e/255.0, green: 0x18/255.0, blue: 0x14/255.0, alpha: 1)
let clipMid       = CGColor(red: 0x4a/255.0, green: 0x3f/255.0, blue: 0x38/255.0, alpha: 1)
let accent        = CGColor(red: 0xb8/255.0, green: 0x49/255.0, blue: 0x1f/255.0, alpha: 1)
let ink           = CGColor(red: 0x2a/255.0, green: 0x25/255.0, blue: 0x21/255.0, alpha: 1)

func addSquirclePath(_ ctx: CGContext, rect: CGRect) {
    // macOS Big Sur squircle-ish: superellipse approximated via rounded rect with large radius (~22%)
    let r = rect.width * 0.2235
    let path = CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
    ctx.addPath(path)
}

func drawLinearGradient(_ ctx: CGContext, in rect: CGRect, colors: [CGColor], locations: [CGFloat], angleDeg: CGFloat = 135) {
    ctx.saveGState()
    let cs = CGColorSpaceCreateDeviceRGB()
    let grad = CGGradient(colorsSpace: cs, colors: colors as CFArray, locations: locations)!
    let theta = angleDeg * .pi / 180
    let cx = rect.midX, cy = rect.midY
    let r = hypot(rect.width, rect.height) / 2
    let start = CGPoint(x: cx - cos(theta) * r, y: cy - sin(theta) * r)
    let end   = CGPoint(x: cx + cos(theta) * r, y: cy + sin(theta) * r)
    ctx.drawLinearGradient(grad, start: start, end: end, options: [])
    ctx.restoreGState()
}

func drawCard(_ ctx: CGContext, canvas: CGRect, centerOffset: CGPoint, rotation: CGFloat, size: CGSize,
              paperColors: [CGColor], shadowAlpha: CGFloat, isFront: Bool) {
    ctx.saveGState()
    let cx = canvas.midX + centerOffset.x
    let cy = canvas.midY + centerOffset.y
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: rotation * .pi / 180)

    let rect = CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height)
    let corner = size.width * 0.085

    // Shadow baked by drawing a darker offset rect
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -canvas.width * 0.016),
                  blur: canvas.width * 0.022,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: Double(shadowAlpha)))
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(paperColors[0])
    ctx.fillPath()
    ctx.restoreGState()

    // Paper gradient on top (shadow only for the single-fill shape above, no double-shadow)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    drawLinearGradient(ctx, in: rect, colors: paperColors, locations: [0, 1], angleDeg: 90)
    ctx.restoreGState()

    if isFront {
        // Clip silhouette
        let clipW = size.width * 0.24
        let clipH = size.height * 0.094
        let clipY = size.height/2 - clipH * 0.08     // sits at top edge
        let clipRect = CGRect(x: -clipW/2, y: clipY, width: clipW, height: clipH)
        let clipPath = CGPath(roundedRect: clipRect, cornerWidth: clipH * 0.28, cornerHeight: clipH * 0.28, transform: nil)
        ctx.saveGState()
        ctx.addPath(clipPath)
        ctx.clip()
        drawLinearGradient(ctx, in: clipRect, colors: [clipMid, clipDark], locations: [0,1], angleDeg: 90)
        ctx.restoreGState()

        let capW = clipW * 0.72
        let capH = clipH * 0.36
        let capRect = CGRect(x: -capW/2, y: clipRect.maxY - capH * 0.1, width: capW, height: capH)
        let capPath = CGPath(roundedRect: capRect, cornerWidth: capH * 0.4, cornerHeight: capH * 0.4, transform: nil)
        ctx.addPath(capPath)
        ctx.setFillColor(clipDark)
        ctx.fillPath()

        // Text lines — accent then ink pills
        let lineX = -size.width * 0.36
        let lineW = size.width * 0.70
        let lineH = size.height * 0.035
        let lineRadius = lineH * 0.5
        let startY = -size.height * 0.33
        let pitch = size.height * 0.087

        // Accent bar
        let a = CGRect(x: lineX, y: startY, width: lineW * 0.93, height: lineH)
        ctx.addPath(CGPath(roundedRect: a, cornerWidth: lineRadius, cornerHeight: lineRadius, transform: nil))
        ctx.setFillColor(accent)
        ctx.fillPath()

        // Ink lines of varying widths/opacities
        let widths: [CGFloat] = [0.88, 0.97, 0.68, 0.92, 0.56, 0.80, 0.42]
        let alphas: [CGFloat] = [0.28, 0.22, 0.22, 0.18, 0.18, 0.14, 0.14]
        for i in 0..<widths.count {
            let y = startY + pitch * CGFloat(i + 1)
            let r = CGRect(x: lineX, y: y, width: lineW * widths[i], height: lineH)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: lineRadius, cornerHeight: lineRadius, transform: nil))
            ctx.setFillColor(ink.copy(alpha: alphas[i])!)
            ctx.fillPath()
        }
    }
    ctx.restoreGState()
}

func renderIcon(size: Int) -> CGImage {
    let px = CGFloat(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Flip so our +y = up during drawing (CoreGraphics default is already +y up; keep as-is)
    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    let full = CGRect(x: 0, y: 0, width: px, height: px)

    // Background squircle with gradient
    ctx.saveGState()
    addSquirclePath(ctx, rect: full)
    ctx.clip()
    drawLinearGradient(ctx, in: full, colors: [amberTop, amberMid, amberBot], locations: [0, 0.55, 1], angleDeg: 120)

    // Specular highlight
    let hiStart = CGPoint(x: px * 0.15, y: px * 1.0)
    let hiEnd   = CGPoint(x: px * 0.55, y: px * 0.35)
    let hiColors = [CGColor(red: 1, green: 1, blue: 1, alpha: 0.28),
                    CGColor(red: 1, green: 1, blue: 1, alpha: 0)]
    let hiGrad = CGGradient(colorsSpace: cs, colors: hiColors as CFArray, locations: [0,1])!
    ctx.drawLinearGradient(hiGrad, start: hiStart, end: hiEnd, options: [])
    ctx.restoreGState()

    // Inner rim highlight
    ctx.saveGState()
    addSquirclePath(ctx, rect: full.insetBy(dx: px * 0.006, dy: px * 0.006))
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
    ctx.setLineWidth(max(1, px * 0.003))
    ctx.strokePath()
    ctx.restoreGState()

    // Cards (scaled to canvas size)
    let cardBase = CGSize(width: px * 0.47, height: px * 0.61)
    let offsetScale = px / 1024.0

    drawCard(ctx, canvas: full,
             centerOffset: CGPoint(x: -10 * offsetScale, y: -45 * offsetScale),
             rotation: 11,
             size: cardBase,
             paperColors: [paperTop, paperMid],
             shadowAlpha: 0.18,
             isFront: false)

    drawCard(ctx, canvas: full,
             centerOffset: CGPoint(x: 0, y: -25 * offsetScale),
             rotation: 3,
             size: cardBase,
             paperColors: [paperTop, paperMid],
             shadowAlpha: 0.22,
             isFront: false)

    drawCard(ctx, canvas: full,
             centerOffset: CGPoint(x: 15 * offsetScale, y: -5 * offsetScale),
             rotation: -5,
             size: cardBase,
             paperColors: [paperTop, paperBot],
             shadowAlpha: 0.28,
             isFront: true)

    return ctx.makeImage()!
}

// --- Write PNGs --------------------------------------------------------------

func writePNG(_ img: CGImage, to url: URL) throws {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "icon", code: 1)
    }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

for spec in specs {
    let img = renderIcon(size: spec.size)
    let url = outDir.appendingPathComponent(spec.file)
    try writePNG(img, to: url)
    print("wrote \(spec.file) (\(spec.size)px)")
}

// --- Contents.json -----------------------------------------------------------

struct EntryJSON { let size: String; let idiom: String; let filename: String; let scale: String }
let entries = specs.map { s in
    EntryJSON(size: "\(s.base)x\(s.base)", idiom: s.idiom, filename: s.file, scale: "\(s.scale)x")
}
var json = "{\n  \"images\" : [\n"
for (i, e) in entries.enumerated() {
    json += "    {\n"
    json += "      \"filename\" : \"\(e.filename)\",\n"
    json += "      \"idiom\" : \"\(e.idiom)\",\n"
    json += "      \"scale\" : \"\(e.scale)\",\n"
    json += "      \"size\" : \"\(e.size)\"\n"
    json += "    }" + (i < entries.count - 1 ? "," : "") + "\n"
}
json += "  ],\n  \"info\" : {\n    \"author\" : \"xcode\",\n    \"version\" : 1\n  }\n}\n"
try json.write(to: outDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("wrote Contents.json")
print("done.")
