import UIKit
import CoreImage

enum FilterStyle: String, CaseIterable, Codable, Identifiable {
    case original, instant, fade, chrome, mono, noir, warm, vivid
    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: "Original"
        case .instant: "Instant"
        case .fade: "Fade"
        case .chrome: "Chrome"
        case .mono: "Mono"
        case .noir: "Noir"
        case .warm: "Warm"
        case .vivid: "Vivid"
        }
    }

    var isPremium: Bool {
        switch self {
        case .original, .instant: false
        default: true
        }
    }

    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    func apply(to image: UIImage) -> UIImage {
        guard self != .original, let input = CIImage(image: image) else { return image }
        let output: CIImage?
        switch self {
        case .original: output = input
        case .instant: output = Self.run("CIPhotoEffectInstant", input)
        case .fade: output = Self.run("CIPhotoEffectFade", input)
        case .chrome: output = Self.run("CIPhotoEffectChrome", input)
        case .mono: output = Self.run("CIPhotoEffectMono", input)
        case .noir: output = Self.run("CIPhotoEffectNoir", input)
        case .warm:
            output = Self.run("CIColorMatrix", input, [
                "inputRVector": CIVector(x: 1.08, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.88, w: 0),
                "inputBiasVector": CIVector(x: 0.02, y: 0.01, z: 0, w: 0),
            ])
        case .vivid:
            output = Self.run("CIColorControls", input, [
                kCIInputSaturationKey: 1.35,
                kCIInputContrastKey: 1.08,
            ])
        }
        guard let output, let cg = Self.context.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: cg)
    }

    private static func run(_ name: String, _ input: CIImage, _ params: [String: Any] = [:]) -> CIImage? {
        guard let f = CIFilter(name: name) else { return nil }
        f.setValue(input, forKey: kCIInputImageKey)
        for (k, v) in params { f.setValue(v, forKey: k) }
        return f.outputImage
    }
}
