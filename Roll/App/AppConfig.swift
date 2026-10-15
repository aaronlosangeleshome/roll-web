import SwiftUI

/// Everything you must change before shipping lives here.
enum AppConfig {
    static let appName = "Roll"

    /// Replace aaronlosangeleshome after you fork or publish the repo.
    static let repoURL = URL(string: "https://github.com/aaronlosangeleshome/roll-ios")!

    /// Monetization is compiled in only for the `Roll-AppStore` scheme (APP_STORE condition).
    /// Default (open source) builds skip StoreKit entirely and unlock every feature.
    static let storeEnabled: Bool = {
        #if APP_STORE
        return true
        #else
        return false
        #endif
    }()

    // For an App Store release replace these with your own live URLs
    // (App Review checks them: Guidelines 1.5, 3.1.2, 5.1.1).
    static let privacyURL = URL(string: "https://github.com/aaronlosangeleshome/roll-ios/blob/main/PRIVACY_POLICY.md")!
    static let supportURL = URL(string: "https://github.com/aaronlosangeleshome/roll-ios/issues")!
    // Apple's standard EULA is acceptable if you have no custom terms.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Free users can take this many pics per day. Plus users are unlimited.
    static let freeDailyPics = 5
    /// Seconds for a photo to fully develop.
    static let developSeconds: TimeInterval = 25
    /// Seconds removed from development time per shake.
    static let shakeBoost: TimeInterval = 4
}

enum ProductID {
    static let monthly = "com.yourname.roll.monthly"
    static let lifetime = "com.yourname.roll.lifetime"
    static let all = [monthly, lifetime]
}

enum Theme {
    static let bone = Color(hex: 0xEDE6D6)
    static let boneShade = Color(hex: 0xD9D0BC)
    static let boneHighlight = Color(hex: 0xF6F1E5)
    static let leather = Color(hex: 0x2A2420)
    static let leatherLight = Color(hex: 0x3A322C)
    static let ink = Color(hex: 0x2A2724)
    static let paper = Color(hex: 0xF7F3EA)
    static let orange = Color(hex: 0xD9622B)
    static let amber = Color(hex: 0xE8A33D)
    static let sage = Color(hex: 0x7AA096)

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
