import UIKit
import Photos

enum ImageProcessor {
    /// Center-crops to a square (matching the viewfinder) and normalises orientation.
    static func squareCrop(_ image: UIImage, mirrored: Bool, side: CGFloat = 1080) -> UIImage {
        let size = image.size   // already orientation-aware
        let s = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - s) / 2, y: (size.height - s) / 2)
        let scale = side / s

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { ctx in
            if mirrored {
                ctx.cgContext.translateBy(x: side, y: 0)
                ctx.cgContext.scaleBy(x: -1, y: 1)
            }
            image.draw(in: CGRect(x: -origin.x * scale, y: -origin.y * scale,
                                  width: size.width * scale, height: size.height * scale))
        }
    }
}

enum PhotoSaver {
    enum SaveError: LocalizedError {
        case denied
        var errorDescription: String? { "Roll needs permission to add photos. You can enable it in Settings." }
    }

    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
