import AppKit
import CoreImage

enum BlurProcessor {
    static func apply(to image: NSImage, in rect: CGRect, radius: Double = 10.0) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])

        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let blurredCI = blurFilter.outputImage else { return image }

        let croppedBlur = blurredCI.cropped(to: rect)
        let composite = croppedBlur.composited(over: ciImage)

        guard let outputCG = context.createCGImage(composite, from: ciImage.extent) else {
            return image
        }

        return NSImage(cgImage: outputCG, size: image.size)
    }
}
