import CoreGraphics
import Foundation
import ImageIO

private struct IconImage {
    let filename: String
    let pixels: Int
}

private let outputDirectory = URL(fileURLWithPath: "CBORGUsageMonitor/Assets.xcassets/AppIcon.appiconset")

private let images: [IconImage] = [
    IconImage(filename: "icon_16x16.png", pixels: 16),
    IconImage(filename: "icon_16x16@2x.png", pixels: 32),
    IconImage(filename: "icon_32x32.png", pixels: 32),
    IconImage(filename: "icon_32x32@2x.png", pixels: 64),
    IconImage(filename: "icon_128x128.png", pixels: 128),
    IconImage(filename: "icon_128x128@2x.png", pixels: 256),
    IconImage(filename: "icon_256x256.png", pixels: 256),
    IconImage(filename: "icon_256x256@2x.png", pixels: 512),
    IconImage(filename: "icon_512x512.png", pixels: 512),
    IconImage(filename: "icon_512x512@2x.png", pixels: 1024)
]

private func cgColor(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

private func drawIcon(size pixelSize: Int) -> CGImage {
    let side = CGFloat(pixelSize)
    let scale = side / 1024
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    context.scaleBy(x: scale, y: scale)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let tileRect = CGRect(x: 54, y: 54, width: 916, height: 916)
    let tilePath = CGPath(
        roundedRect: tileRect,
        cornerWidth: 214,
        cornerHeight: 214,
        transform: nil
    )

    context.saveGState()
    context.addPath(tilePath)
    context.clip()

    let baseGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(28, 52, 116).copy(alpha: 1)!,
            cgColor(34, 124, 190).copy(alpha: 1)!,
            cgColor(89, 202, 205).copy(alpha: 1)!
        ] as CFArray,
        locations: [0, 0.52, 1]
    )!
    context.drawLinearGradient(
        baseGradient,
        start: CGPoint(x: 120, y: 74),
        end: CGPoint(x: 930, y: 948),
        options: []
    )

    context.setBlendMode(.screen)
    context.setFillColor(cgColor(255, 255, 255, 0.15))
    context.fillEllipse(in: CGRect(x: 92, y: 76, width: 560, height: 370))
    context.setFillColor(cgColor(138, 226, 255, 0.17))
    context.fillEllipse(in: CGRect(x: 470, y: 510, width: 470, height: 420))
    context.restoreGState()

    context.saveGState()
    context.addPath(tilePath)
    context.setShadow(offset: CGSize(width: 0, height: 28), blur: 56, color: cgColor(0, 18, 50, 0.38))
    context.setStrokeColor(cgColor(255, 255, 255, 0.25))
    context.setLineWidth(3)
    context.strokePath()
    context.restoreGState()

    let glassRect = CGRect(x: 160, y: 146, width: 704, height: 704)
    let glassPath = CGPath(roundedRect: glassRect, cornerWidth: 156, cornerHeight: 156, transform: nil)

    context.saveGState()
    context.addPath(glassPath)
    context.clip()
    let glassGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(255, 255, 255, 0.42),
            cgColor(255, 255, 255, 0.12),
            cgColor(255, 255, 255, 0.22)
        ] as CFArray,
        locations: [0, 0.52, 1]
    )!
    context.drawLinearGradient(
        glassGradient,
        start: CGPoint(x: 170, y: 148),
        end: CGPoint(x: 830, y: 850),
        options: []
    )
    context.restoreGState()

    context.addPath(glassPath)
    context.setStrokeColor(cgColor(255, 255, 255, 0.55))
    context.setLineWidth(7)
    context.strokePath()

    let center = CGPoint(x: 512, y: 518)
    context.setLineCap(.round)

    context.setStrokeColor(cgColor(255, 255, 255, 0.26))
    context.setLineWidth(76)
    context.addArc(center: center, radius: 235, startAngle: 0.78 * .pi, endAngle: 2.22 * .pi, clockwise: false)
    context.strokePath()

    let meterGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            cgColor(180, 236, 255, 1),
            cgColor(84, 148, 255, 1),
            cgColor(107, 232, 219, 1)
        ] as CFArray,
        locations: [0, 0.58, 1]
    )!

    context.saveGState()
    context.setLineCap(.round)
    context.setLineWidth(82)
    context.addArc(center: center, radius: 235, startAngle: 0.84 * .pi, endAngle: 1.88 * .pi, clockwise: false)
    context.replacePathWithStrokedPath()
    context.clip()
    context.drawLinearGradient(
        meterGradient,
        start: CGPoint(x: 250, y: 300),
        end: CGPoint(x: 800, y: 690),
        options: []
    )
    context.restoreGState()

    context.setStrokeColor(cgColor(255, 255, 255, 0.66))
    context.setLineWidth(22)
    context.move(to: center)
    context.addLine(to: CGPoint(x: 664, y: 416))
    context.strokePath()

    context.setFillColor(cgColor(255, 255, 255, 0.94))
    context.fillEllipse(in: CGRect(x: 458, y: 464, width: 108, height: 108))
    context.setFillColor(cgColor(52, 112, 210, 1))
    context.fillEllipse(in: CGRect(x: 485, y: 491, width: 54, height: 54))

    let progressRect = CGRect(x: 276, y: 714, width: 472, height: 54)
    let progressPath = CGPath(roundedRect: progressRect, cornerWidth: 27, cornerHeight: 27, transform: nil)
    context.addPath(progressPath)
    context.setFillColor(cgColor(255, 255, 255, 0.28))
    context.fillPath()

    context.saveGState()
    context.addPath(progressPath)
    context.clip()
    let fillPath = CGPath(
        roundedRect: CGRect(x: 276, y: 714, width: 308, height: 54),
        cornerWidth: 27,
        cornerHeight: 27,
        transform: nil
    )
    context.addPath(fillPath)
    context.setFillColor(cgColor(159, 235, 255, 0.88))
    context.fillPath()
    context.restoreGState()

    context.setFillColor(cgColor(255, 255, 255, 0.85))
    context.fillEllipse(in: CGRect(x: 718, y: 250, width: 62, height: 62))

    return context.makeImage()!
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for image in images {
    let icon = drawIcon(size: image.pixels)
    try writePNG(icon, to: outputDirectory.appendingPathComponent(image.filename))
}

print("Generated \(images.count) app icon images in \(outputDirectory.path)")
