import AVFoundation
import UIKit

enum CameraError: LocalizedError {
    case unavailable, noData
    var errorDescription: String? {
        switch self {
        case .unavailable: "The camera isn't available right now."
        case .noData: "The photo couldn't be processed. Try again."
        }
    }
}

@MainActor
final class CameraService: NSObject, ObservableObject {
    nonisolated(unsafe) let session = AVCaptureSession()
    @Published private(set) var authorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var position: AVCaptureDevice.Position = .back
    @Published var flashOn = false
    @Published private(set) var isRunning = false

    // Touched only on sessionQueue after init.
    nonisolated(unsafe) private let output = AVCapturePhotoOutput()
    nonisolated private let sessionQueue = DispatchQueue(label: "roll.camera.session")
    nonisolated(unsafe) private var configured = false
    private var continuation: CheckedContinuation<UIImage, Error>?

    // MARK: Lifecycle

    func start() async {
        if authorization == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            authorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
        guard authorization == .authorized else { return }
        let pos = position
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [self] in
                if !configured { configure(position: pos) }
                if !session.isRunning { session.startRunning() }
                cont.resume()
            }
        }
        isRunning = session.isRunning
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        isRunning = false
    }

    func flip() {
        let next: AVCaptureDevice.Position = position == .back ? .front : .back
        position = next
        if next == .front { flashOn = false }
        sessionQueue.async { [self] in configure(position: next) }
    }

    // MARK: Capture

    func capture() async throws -> UIImage {
        #if targetEnvironment(simulator)
        if true { return Self.simulatorTestImage() }
        #endif
        guard session.isRunning else { throw CameraError.unavailable }
        let flash = flashOn
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            sessionQueue.async { [self] in
                let settings = AVCapturePhotoSettings()
                if output.supportedFlashModes.contains(.on) {
                    settings.flashMode = flash ? .on : .off
                }
                if let connection = output.connection(with: .video),
                   connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: Configuration (runs on sessionQueue)

    private nonisolated func configure(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo

        for input in session.inputs { session.removeInput(input) }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)

        if !session.outputs.contains(output), session.canAddOutput(output) {
            session.addOutput(output)
        }
        configured = true
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let result: Result<UIImage, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            result = .success(image)
        } else {
            result = .failure(CameraError.noData)
        }
        Task { @MainActor in
            self.continuation?.resume(with: result)
            self.continuation = nil
        }
    }
}

#if targetEnvironment(simulator)
extension CameraService {
    /// The iOS Simulator has no camera. Synthesize a recognizable frame instead.
    static func simulatorTestImage() -> UIImage {
        let size = CGSize(width: 1600, height: 1200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let colors = [UIColor(red: 0.96, green: 0.72, blue: 0.45, alpha: 1).cgColor,
                          UIColor(red: 0.35, green: 0.45, blue: 0.55, alpha: 1).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            UIColor(red: 0.98, green: 0.85, blue: 0.55, alpha: 1).setFill()
            cg.fillEllipse(in: CGRect(x: 1000, y: 220, width: 260, height: 260))
            UIColor(red: 0.16, green: 0.2, blue: 0.24, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 820, width: size.width, height: 380))
            UIColor(red: 0.22, green: 0.28, blue: 0.3, alpha: 1).setFill()
            cg.move(to: CGPoint(x: 0, y: 820)); cg.addLine(to: CGPoint(x: 420, y: 520))
            cg.addLine(to: CGPoint(x: 800, y: 820)); cg.fillPath()
        }
    }
}
#endif
