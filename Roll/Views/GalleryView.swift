import SwiftUI

struct GalleryView: View {
    @EnvironmentObject private var shots: ShotStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.leather.ignoresSafeArea()
                if shots.shots.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36)).foregroundStyle(Theme.bone.opacity(0.6))
                        Text("No prints yet")
                            .font(Theme.mono(15, weight: .bold)).foregroundStyle(Theme.bone)
                        Text("Take a photo and it will develop here.")
                            .font(Theme.mono(12)).foregroundStyle(Theme.bone.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        TimelineView(.animation(minimumInterval: 0.5, paused: !shots.hasUndeveloped)) { context in
                            LazyVGrid(columns: columns, spacing: 22) {
                                ForEach(shots.shots) { shot in
                                    NavigationLink(value: shot.id) {
                                        if let img = shots.filtered(for: shot) {
                                            InstantCard(image: img, frame: shot.frame, caption: shot.caption,
                                                         stickers: shot.stickers,
                                                         progress: shot.progress(at: context.date))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(shot.isDeveloped(at: context.date) ? "Photo" : "Developing photo")
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Your Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.leather, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Theme.orange)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                ShotDetailView(shotID: id)
            }
        }
    }
}
