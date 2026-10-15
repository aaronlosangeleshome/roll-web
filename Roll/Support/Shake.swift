import SwiftUI

extension UIDevice {
    static let deviceDidShake = Notification.Name("roll.deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

private struct OnShake: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShake)) { _ in action() }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(OnShake(action: action))
    }
}

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
