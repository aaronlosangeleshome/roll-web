import UIKit

/// On-device persistence. Images are JPEGs in Application Support; metadata is one JSON index.
/// Nothing ever leaves the device.
@MainActor
final class ShotStore: ObservableObject {
    @Published private(set) var shots: [Shot] = []

    private let dir: URL
    private var indexURL: URL { dir.appendingPathComponent("index.json") }
    private let imageCache = NSCache<NSString, UIImage>()
    private let filteredCache = NSCache<NSString, UIImage>()

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("Shots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        load()
    }

    func shot(_ id: UUID) -> Shot? { shots.first { $0.id == id } }

    @discardableResult
    func add(_ image: UIImage, developSeconds: TimeInterval = AppConfig.developSeconds) -> Shot {
        let now = Date()
        let shot = Shot(id: UUID(), createdAt: now, developEnds: now.addingTimeInterval(developSeconds))
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL(shot.id), options: .atomic)
        }
        imageCache.setObject(image, forKey: shot.id.uuidString as NSString)
        shots.insert(shot, at: 0)
        save()
        return shot
    }

    func update(_ id: UUID, _ change: (inout Shot) -> Void) {
        guard let i = shots.firstIndex(where: { $0.id == id }) else { return }
        change(&shots[i])
        save()
    }

    func delete(_ id: UUID) {
        shots.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: fileURL(id))
        imageCache.removeObject(forKey: id.uuidString as NSString)
        save()
    }

    /// Shaking pulls every undeveloped photo closer to done.
    func accelerateDevelopment(by seconds: TimeInterval = AppConfig.shakeBoost) {
        var changed = false
        for i in shots.indices where !shots[i].isDeveloped() {
            let floor = shots[i].createdAt
            shots[i].developEnds = max(floor, shots[i].developEnds.addingTimeInterval(-seconds))
            changed = true
        }
        if changed { save() }
    }

    func finishDevelopment(_ id: UUID) {
        update(id) { $0.developEnds = $0.createdAt }
    }

    var hasUndeveloped: Bool { shots.contains { !$0.isDeveloped() } }

    func original(for shot: Shot) -> UIImage? {
        let key = shot.id.uuidString as NSString
        if let hit = imageCache.object(forKey: key) { return hit }
        guard let img = UIImage(contentsOfFile: fileURL(shot.id).path) else { return nil }
        imageCache.setObject(img, forKey: key)
        return img
    }

    func filtered(for shot: Shot) -> UIImage? {
        guard let base = original(for: shot) else { return nil }
        if shot.filter == .original { return base }
        let key = "\(shot.id.uuidString)-\(shot.filter.rawValue)" as NSString
        if let hit = filteredCache.object(forKey: key) { return hit }
        let out = shot.filter.apply(to: base)
        filteredCache.setObject(out, forKey: key)
        return out
    }

    // MARK: Persistence

    private func fileURL(_ id: UUID) -> URL { dir.appendingPathComponent("\(id.uuidString).jpg") }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([Shot].self, from: data) else { return }
        shots = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(shots) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
