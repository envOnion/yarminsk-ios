import AppKit
import Foundation

// Render the existing vector brand mark on an opaque, full-bleed background.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = try String(contentsOf: root.appendingPathComponent("Resources/logo.svg"), encoding: .utf8)
let pathRegex = try NSRegularExpression(pattern: #"<path[^>]*d="([^"]+)"[^>]*fill="([^"]+)""#)
let tokenRegex = try NSRegularExpression(pattern: #"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?"#)
let range = NSRange(source.startIndex..., in: source)
let markPaths = pathRegex.matches(in: source, range: range).map { match -> (String, String) in
    (String(source[Range(match.range(at: 1), in: source)!]), String(source[Range(match.range(at: 2), in: source)!]))
}
func path(_ data: String) -> CGPath {
    let tokens = tokenRegex.matches(in: data, range: NSRange(data.startIndex..., in: data)).map {
        String(data[Range($0.range, in: data)!])
    }
    let result = CGMutablePath()
    var i = 0
    var command = ""
    func number() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i])!) }
    func point() -> CGPoint { CGPoint(x: number(), y: number()) }
    while i < tokens.count {
        if tokens[i].first!.isLetter { command = tokens[i]; i += 1 }
        switch command {
        case "M": result.move(to: point()); command = "L"
        case "L": result.addLine(to: point())
        case "C":
            let p1 = point(), p2 = point(), p3 = point()
            result.addCurve(to: p3, control1: p1, control2: p2)
        case "Z", "z": result.closeSubpath(); command = ""
        default: fatalError("Unsupported vector command: \(command)")
        }
    }
    return result
}
let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.translateBy(x: 0, y: CGFloat(size))
context.scaleBy(x: 1, y: -1)
let gradient = CGGradient(colorsSpace: space, colors: [
    CGColor(red: 0.12, green: 0.34, blue: 0.25, alpha: 1),
    CGColor(red: 0.025, green: 0.095, blue: 0.072, alpha: 1)
] as CFArray, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 120, y: 0), end: CGPoint(x: 880, y: 1024), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
let glow = CGGradient(colorsSpace: space, colors: [
    CGColor(red: 0.29, green: 0.59, blue: 0.41, alpha: 0.16),
    CGColor(red: 0.29, green: 0.59, blue: 0.41, alpha: 0)
] as CFArray, locations: [0, 1])!
context.drawRadialGradient(glow, startCenter: CGPoint(x: 350, y: 280), startRadius: 0, endCenter: CGPoint(x: 350, y: 280), endRadius: 760, options: [])
context.saveGState()
context.translateBy(x: 168, y: 352)
context.scaleBy(x: 688 / 48, y: 688 / 48)
for (data, fill) in markPaths {
    context.addPath(path(data))
    context.setFillColor(fill == "white" ? CGColor(gray: 1, alpha: 1) : CGColor(red: 237/255, green: 28/255, blue: 36/255, alpha: 1))
    context.drawPath(using: .eoFill)
}
context.restoreGState()
let image = NSBitmapImageRep(cgImage: context.makeImage()!)
let png = image.representation(using: .png, properties: [:])!
let output = root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try png.write(to: output)
let elements = markPaths.map { #"<path d=""# + $0.0 + #"" fill=""# + $0.1 + #"" fill-rule="evenodd"/>"# }.joined(separator: "\n")
let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<defs><linearGradient id="bg" x1="0.12" y1="0" x2="0.86" y2="1"><stop stop-color="#1F5740"/><stop offset="1" stop-color="#061812"/></linearGradient><radialGradient id="glow" cx="34%" cy="27%" r="74%"><stop stop-color="#4A9669" stop-opacity=".16"/><stop offset="1" stop-color="#4A9669" stop-opacity="0"/></radialGradient></defs>
<path fill="url(#bg)" d="M0 0H1024V1024H0Z"/><path fill="url(#glow)" d="M0 0H1024V1024H0Z"/>
<g transform="translate(168 352) scale(14.3333333333)">\(elements)</g>
</svg>
"""
try svg.write(to: root.appendingPathComponent("AppStore/Artwork/AppIcon.svg"), atomically: true, encoding: .utf8)
print("Rendered opaque 1024×1024 AppIcon.png")
