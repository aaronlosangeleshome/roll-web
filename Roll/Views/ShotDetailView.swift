import SwiftUI

struct ShotDetailView: View {
    let shotID: UUID

    @EnvironmentObject private var shots: ShotStore
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    private enum Tab: String, CaseIterable, Identifiable {
        case filter = "Filter", frame = "Frame", stickers = "Stickers", caption = "Caption"
        var id: String { rawValue }
    }

    @State private var tab: Tab = .filter
    @State private var showPaywall = false
    @State private var paywallReason: String?
    @State private var confirmDelete = false
    @State private var toast: String?
    @State private var exported: UIImage?

    var body: some View {
        Group {
            if let shot = shots.shot(shotID), let base = shots.original(for: shot) {
                if shot.isDeveloped() {
                    content(shot: shot, base: base, now: Date())
                } else {
                    TimelineView(.periodic(from: .now, by: 0.25)) { context in
                        content(shot: shot, base: base, now: context.date)
                    }
                }
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: paywallReason) }
    }

    private func content(shot: Shot, base: UIImage, now: Date) -> some View {
        ZStack {
            Theme.leather.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    let p = shot.progress(at: now)
                    VStack(spacing: 12) {
                        InstantCard(
                            image: shots.filtered(for: shot) ?? base,
                            frame: shot.frame,
                            caption: shot.caption,
                            stickers: shot.stickers,
                            progress: p,
                            onStickersChange: p >= 1 ? { new in
                                shots.update(shotID) { $0.stickers = new }
                            } : nil
                        )
                        .padding(.horizontal, 36)

                        if p < 1 {
                            developingBar(progress: p)
                        }
                    }

                    if shot.isDeveloped(at: now) {
                        editor(shot: shot)
                    }
                }
                .padding(.vertical, 16)
            }

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(Theme.mono(13, weight: .bold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.bone, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(Theme.ink)
                        .padding(.bottom, 30)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Print")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.leather, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let exported {
                    ShareLink(item: Image(uiImage: exported),
                              preview: SharePreview("My print", image: Image(uiImage: exported))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                Button { Task { await save(shot: shot) } } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .disabled(!shot.isDeveloped(at: now))
                .accessibilityLabel("Save to Photos")
                Button(role: .destructive) { confirmDelete = true } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete")
            }
        }
        .tint(Theme.bone)
        .confirmationDialog("Delete this print?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                shots.delete(shotID)
                dismiss()
            }
        } message: { Text("This can't be undone.") }
        .task(id: renderKey(shot)) {
            guard shot.isDeveloped(), let img = shots.filtered(for: shot) else { exported = nil; return }
            exported = CardRenderer.render(shot: shot, image: img)
        }
    }

    private func renderKey(_ s: Shot) -> String {
        "\(s.filter.rawValue)|\(s.frame.rawValue)|\(s.caption)|\(s.stickers.hashValue)|\(s.isDeveloped())"
    }

    private func developingBar(progress: Double) -> some View {
        VStack(spacing: 10) {
            ProgressView(value: progress)
                .tint(Theme.amber)
                .padding(.horizontal, 60)
            Text("Developing… shake your phone to speed it up")
                .font(Theme.mono(12)).foregroundStyle(Theme.bone.opacity(0.75))
            Button("Develop now") {
                Haptics.tap(.light)
                shots.finishDevelopment(shotID)
            }
            .font(Theme.mono(13, weight: .bold))
            .buttonStyle(.bordered)
            .tint(Theme.orange)
        }
    }

    // MARK: Editor

    private func editor(shot: Shot) -> some View {
        VStack(spacing: 16) {
            Picker("Edit", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            switch tab {
            case .filter: filterRow(shot)
            case .frame: frameRow(shot)
            case .stickers: stickerRow
            case .caption: captionField(shot)
            }
        }
    }

    private func filterRow(_ shot: Shot) -> some View {
        chipRow {
            ForEach(FilterStyle.allCases) { f in
                chip(title: f.title, selected: shot.filter == f, locked: f.isPremium && !store.isPlus) {
                    if f.isPremium && !store.isPlus {
                        paywallReason = "The \(f.title) filter is part of Roll Plus."
                        showPaywall = true
                    } else {
                        shots.update(shotID) { $0.filter = f }
                    }
                }
            }
        }
    }

    private func frameRow(_ shot: Shot) -> some View {
        chipRow {
            ForEach(FrameStyle.allCases) { f in
                chip(title: f.title, selected: shot.frame == f, locked: f.isPremium && !store.isPlus,
                     swatch: f.paper) {
                    if f.isPremium && !store.isPlus {
                        paywallReason = "The \(f.title) frame is part of Roll Plus."
                        showPaywall = true
                    } else {
                        shots.update(shotID) { $0.frame = f }
                    }
                }
            }
        }
    }

    private var stickerRow: some View {
        VStack(spacing: 8) {
            chipRow {
                ForEach(StickerAsset.all) { s in
                    let locked = s.isPremium && !store.isPlus
                    Button {
                        if locked {
                            paywallReason = "More stickers are part of Roll Plus."
                            showPaywall = true
                        } else {
                            Haptics.tap(.light)
                            shots.update(shotID) {
                                $0.stickers.append(StickerPlacement(symbol: s.symbol, x: 0.5, y: 0.45,
                                                                    scale: 1, rotation: Double.random(in: -12...12)))
                            }
                        }
                    } label: {
                        Image(systemName: s.symbol)
                            .font(.system(size: 22))
                            .foregroundStyle(s.color)
                            .frame(width: 52, height: 52)
                            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                if locked { lockBadge }
                            }
                    }
                    .accessibilityLabel("Add sticker")
                }
            }
            Text("Drag to move, pinch to resize, double tap to remove")
                .font(Theme.mono(11)).foregroundStyle(Theme.bone.opacity(0.6))
        }
    }

    private func captionField(_ shot: Shot) -> some View {
        TextField("Write something", text: Binding(
            get: { shot.caption },
            set: { new in shots.update(shotID) { $0.caption = String(new.prefix(28)) } }
        ))
        .font(.custom("Noteworthy-Bold", size: 18))
        .padding(12)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 20)
    }

    // MARK: Helpers

    private func chipRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) { content() }.padding(.horizontal, 20)
        }
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Theme.leather)
            .padding(4)
            .background(Theme.amber, in: Circle())
            .offset(x: 4, y: -4)
    }

    private func chip(title: String, selected: Bool, locked: Bool, swatch: Color? = nil,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(swatch).frame(width: 14, height: 14)
                        .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous).strokeBorder(.black.opacity(0.3)))
                }
                Text(title).font(Theme.mono(13, weight: .bold))
                if locked { Image(systemName: "lock.fill").font(.system(size: 10)) }
            }
            .padding(.horizontal, 14).frame(height: 40)
            .foregroundStyle(selected ? Theme.leather : Theme.bone)
            .background(selected ? Theme.amber : Theme.leatherLight,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func save(shot: Shot) async {
        guard let img = shots.filtered(for: shot) else { return }
        let flat = exported ?? CardRenderer.render(shot: shot, image: img)
        guard let flat else { return }
        do {
            try await PhotoSaver.save(flat)
            Haptics.success()
            show("Saved to Photos")
        } catch {
            show(error.localizedDescription)
        }
    }

    private func show(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation { toast = nil }
        }
    }
}
