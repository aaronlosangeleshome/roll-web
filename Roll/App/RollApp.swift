import SwiftUI

@main
struct RollApp: App {
    @StateObject private var store = StoreManager()
    @StateObject private var shots = ShotStore()
    @StateObject private var camera = CameraService()
    @StateObject private var usage = UsageTracker()

    var body: some Scene {
        WindowGroup {
            CameraView()
                .environmentObject(store)
                .environmentObject(shots)
                .environmentObject(camera)
                .environmentObject(usage)
                .preferredColorScheme(.light)
                .onShake {
                    guard shots.hasUndeveloped else { return }
                    Haptics.tap(.rigid)
                    shots.accelerateDevelopment()
                }
        }
    }
}
