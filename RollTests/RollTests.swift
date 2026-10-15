import XCTest
@testable import Roll

final class ShotTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testDevelopProgressIsLinearAndClamped() {
        let shot = Shot(id: UUID(), createdAt: start, developEnds: start.addingTimeInterval(20))
        XCTAssertEqual(shot.progress(at: start), 0, accuracy: 0.001)
        XCTAssertEqual(shot.progress(at: start.addingTimeInterval(10)), 0.5, accuracy: 0.001)
        XCTAssertEqual(shot.progress(at: start.addingTimeInterval(500)), 1, accuracy: 0.001)
        XCTAssertEqual(shot.progress(at: start.addingTimeInterval(-5)), 0, accuracy: 0.001)
        XCTAssertFalse(shot.isDeveloped(at: start.addingTimeInterval(19)))
        XCTAssertTrue(shot.isDeveloped(at: start.addingTimeInterval(20)))
    }

    func testZeroLengthDevelopIsInstantlyDeveloped() {
        let shot = Shot(id: UUID(), createdAt: start, developEnds: start)
        XCTAssertTrue(shot.isDeveloped(at: start))
    }

    func testShotRoundTripsThroughJSON() throws {
        var shot = Shot(id: UUID(), createdAt: start, developEnds: start.addingTimeInterval(5))
        shot.caption = "summer"
        shot.filter = .mono
        shot.frame = .kraft
        shot.stickers = [StickerPlacement(symbol: "star.fill", x: 0.4, y: 0.6)]
        let data = try JSONEncoder().encode(shot)
        let decoded = try JSONDecoder().decode(Shot.self, from: data)
        XCTAssertEqual(decoded, shot)
    }
}

final class FilterStyleTests: XCTestCase {
    func testOnlyOriginalAndInstantAreFree() {
        let free = FilterStyle.allCases.filter { !$0.isPremium }
        XCTAssertEqual(Set(free), [.original, .instant])
    }

    func testEveryFilterPreservesImageSize() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format).image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }
        for filter in FilterStyle.allCases {
            let out = filter.apply(to: source)
            XCTAssertEqual(out.size, source.size, "\(filter.title) changed the image size")
        }
    }
}

final class CardMetricsTests: XCTestCase {
    func testAspectMatchesHeightRatio() {
        XCTAssertEqual(CardMetrics.aspect * CardMetrics.heightRatio, 1, accuracy: 0.0001)
        XCTAssertGreaterThan(CardMetrics.heightRatio, 1)
    }
}

@MainActor
final class BuildModeTests: XCTestCase {
    func testOpenSourceBuildIsFullyUnlocked() {
        #if APP_STORE
        XCTAssertTrue(AppConfig.storeEnabled)
        #else
        XCTAssertFalse(AppConfig.storeEnabled)
        XCTAssertTrue(StoreManager().isPlus, "Open source builds must not gate any feature")
        #endif
    }

    func testFreeTierCountsDown() {
        UserDefaults.standard.removeObject(forKey: "usage.day")
        UserDefaults.standard.removeObject(forKey: "usage.count")
        let tracker = UsageTracker()
        XCTAssertEqual(tracker.remaining, AppConfig.freeDailyPics)
        tracker.recordShot()
        XCTAssertEqual(tracker.remaining, AppConfig.freeDailyPics - 1)
    }
}
