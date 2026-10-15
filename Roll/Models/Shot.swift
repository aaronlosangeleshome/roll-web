import SwiftUI

struct StickerPlacement: Identifiable, Codable, Hashable {
    var id = UUID()
    var symbol: String
    var x: Double          // 0...1 of card width
    var y: Double          // 0...1 of card height
    var scale: Double = 1
    var rotation: Double = 0
}

struct Shot: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var developEnds: Date
    var filter: FilterStyle = .original
    var frame: FrameStyle = .classic
    var caption: String = ""
    var stickers: [StickerPlacement] = []

    /// 0 = blank, 1 = fully developed.
    func progress(at date: Date = Date()) -> Double {
        let total = developEnds.timeIntervalSince(createdAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, date.timeIntervalSince(createdAt) / total))
    }

    func isDeveloped(at date: Date = Date()) -> Bool { progress(at: date) >= 1 }
}

enum FrameStyle: String, CaseIterable, Codable, Identifiable {
    case classic, noir, kraft, sunbleach, sage
    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: "Classic"
        case .noir: "Noir"
        case .kraft: "Kraft"
        case .sunbleach: "Sunbleach"
        case .sage: "Sage"
        }
    }
    var isPremium: Bool { self != .classic }

    var paper: Color {
        switch self {
        case .classic: Color(hex: 0xF7F3EA)
        case .noir: Color(hex: 0x1F1C1A)
        case .kraft: Color(hex: 0xD8BC93)
        case .sunbleach: Color(hex: 0xEBDDBC)
        case .sage: Color(hex: 0xC9D6C8)
        }
    }
    var ink: Color {
        switch self {
        case .noir: Color(hex: 0xEDE6D6)
        default: Color(hex: 0x2A2724)
        }
    }
}

struct StickerAsset: Identifiable {
    let symbol: String
    let color: Color
    let isPremium: Bool
    var id: String { symbol }

    static let all: [StickerAsset] = [
        .init(symbol: "star.fill", color: Theme.amber, isPremium: false),
        .init(symbol: "heart.fill", color: Color(hex: 0xC8453B), isPremium: false),
        .init(symbol: "sun.max.fill", color: Theme.orange, isPremium: false),
        .init(symbol: "camera.fill", color: Theme.ink, isPremium: false),
        .init(symbol: "bolt.fill", color: Theme.amber, isPremium: true),
        .init(symbol: "moon.stars.fill", color: Color(hex: 0x3E4A6B), isPremium: true),
        .init(symbol: "leaf.fill", color: Color(hex: 0x5C8A5E), isPremium: true),
        .init(symbol: "flame.fill", color: Theme.orange, isPremium: true),
        .init(symbol: "music.note", color: Theme.ink, isPremium: true),
        .init(symbol: "sparkles", color: Theme.amber, isPremium: true),
        .init(symbol: "cloud.fill", color: Theme.sage, isPremium: true),
        .init(symbol: "drop.fill", color: Color(hex: 0x4A86A8), isPremium: true),
    ]

    static func color(for symbol: String) -> Color {
        all.first { $0.symbol == symbol }?.color ?? Theme.ink
    }
}
