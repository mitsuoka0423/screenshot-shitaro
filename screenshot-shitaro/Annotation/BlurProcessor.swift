import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

/// ぼかし処理を担当するアクター。
/// CIContext は GPUメモリリークを防ぐためシングルトンとして一度だけ生成する。
actor BlurProcessor {
    static let shared = BlurProcessor()

    private let ciContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
        }
        return CIContext(options: [.cacheIntermediates: false])
    }()

    private init() {}

    /// 指定領域にガウスぼかしをかけた CGImage を返す。
    /// - Parameters:
    ///   - image: 元画像
    ///   - rect: ぼかしを適用する領域（画像座標系）
    ///   - radius: ぼかし半径（デフォルト 20）
    /// - Returns: ぼかし済み CGImage。失敗時は nil。
    func blur(image: CGImage, rect: CGRect, radius: Double = 20) async -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let cropRect = rect.intersection(CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
        guard !cropRect.isEmpty else { return nil }

        let cropped = ciImage.cropped(to: cropRect)

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = cropped
        filter.radius = Float(radius)

        guard let blurred = filter.outputImage?.cropped(to: cropRect) else { return nil }

        let composed = blurred.composited(over: ciImage)

        return ciContext.createCGImage(composed, from: ciImage.extent)
    }
}
