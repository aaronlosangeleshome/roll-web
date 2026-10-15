import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject private var camera: CameraService
    @EnvironmentObject private var shots: ShotStore
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var usage: UsageTracker
    @Environment(\.scenePhase) private var scenePhase

    @State private var showGallery = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var paywallReason: String?

    @State private var timerSeconds = 0
    @State private var countdown: Int?
    @State private var isCapturing = false
    @State private var flash = false
    @State private var ejectedID: UUID?
    @State private var ejectProgress: CGFloat = 0
    @State private var errorMessage: String?
    @State private var captureTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.leatherLight, Theme.leather], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    ejectedCard
                    cameraBody
                }
                .padding(.horizontal, 22)
                Spacer(minLength: 0)
                bottomBar
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                usage.refresh()
                await camera.start()
            } else {
                camera.stop()
            }
        }
        .sheet(isPresented: $showGallery) { GalleryView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: paywallReason) }
        .alert("Something went wrong", isPresented: Binding(get: { errorMessage != nil },
                                                           set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Text(AppConfig.appName.uppercased())
                .font(Theme.mono(15, weight: .bold))
                .tracking(4)
                .foregroundStyle(Theme.bone)
            if store.isPlus && AppConfig.storeEnabled {
                Text("PLUS")
                    .font(Theme.mono(10, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .foregroundStyle(Theme.leather)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.bone)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
    }

    // MARK: Camera body

    private var cameraBody: some View {
        VStack(spacing: 14) {
            // Exit slot + film counter
            HStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.leather)
                    .frame(height: 6)
                    .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(Theme.boneShade, lineWidth: 1))
                Spacer().frame(width: 18)
                filmCounter
            }
            .padding(.top, 14)

            // Warm three-band stripe
            HStack(spacing: 0) {
                Theme.orange; Theme.amber; Theme.sage
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))

            viewfinder

            controls
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Theme.boneHighlight, Theme.bone, Theme.boneShade],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.5), radius: 18, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var filmCounter: some View {
        HStack(spacing: 6) {
            Text("FILM")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.ink.opacity(0.6))
            Text(store.isPlus ? "∞" : String(format: "%02d", usage.remaining))
                .font(Theme.mono(15, weight: .bold))
                .foregroundStyle(Theme.amber)
                .frame(minWidth: 30)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Theme.leather, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.isPlus ? "Unlimited film" : "\(usage.remaining) pictures left today")
    }

    private var viewfinder: some View {
        ZStack {
            Rectangle().fill(.black)
            if camera.authorization == .authorized {
                CameraPreview(session: camera.session)
            } else if camera.authorization == .notDetermined {
                ProgressView().tint(Theme.bone)
            } else {
                permissionDenied
            }
            #if targetEnvironment(simulator)
            Text("SIMULATOR\nNo camera. The shutter uses a test image.")
                .font(Theme.mono(11, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.bone.opacity(0.7))
                .padding(12)
            #endif
            if let countdown {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }
            Color.white.opacity(flash ? 0.9 : 0).allowsHitTesting(false)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Theme.leather, lineWidth: 5))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.boneShade, lineWidth: 2).padding(-5))
        .padding(.top, 4)
        .animation(.easeOut(duration: 0.25), value: countdown)
        .accessibilityLabel("Viewfinder")
    }

    private var permissionDenied: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.system(size: 28)).foregroundStyle(Theme.bone.opacity(0.7))
            Text("Camera access is off")
                .font(Theme.mono(14, weight: .bold)).foregroundStyle(Theme.bone)
            Text("Turn it on in Settings to take photos.")
                .font(Theme.mono(12)).foregroundStyle(Theme.bone.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.orange)
        }
        .padding(24)
    }

    private var controls: some View {
        HStack {
            roundButton(system: camera.flashOn ? "bolt.fill" : "bolt.slash.fill",
                        label: camera.flashOn ? "Flash on" : "Flash off") {
                guard camera.position == .back else { return }
                camera.flashOn.toggle()
            }
            .opacity(camera.position == .back ? 1 : 0.35)

            Spacer()
            shutter
            Spacer()

            VStack(spacing: 8) {
                roundButton(system: "arrow.triangle.2.circlepath.camera", label: "Flip camera") { camera.flip() }
                timerButton
            }
        }
        .padding(.horizontal, 4)
    }

    private var shutter: some View {
        Button(action: shutterTapped) {
            ZStack {
                Circle().fill(Theme.leather).frame(width: 86, height: 86)
                Circle().strokeBorder(Theme.boneShade, lineWidth: 3).frame(width: 86, height: 86)
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xEE8650), Theme.orange, Color(hex: 0xB04A1E)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 68, height: 68)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            }
        }
        .buttonStyle(PressScaleStyle())
        .disabled(isCapturing && countdown == nil)
        .accessibilityLabel("Take photo")
    }

    private var timerButton: some View {
        Button {
            if !store.isPlus {
                paywallReason = "The selfie timer is part of Roll Plus."
                showPaywall = true
                return
            }
            timerSeconds = timerSeconds == 0 ? 3 : (timerSeconds == 3 ? 10 : 0)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(timerSeconds == 0 ? "OFF" : "\(timerSeconds)s")
                    .font(Theme.mono(11, weight: .bold))
            }
            .foregroundStyle(timerSeconds == 0 ? Theme.ink.opacity(0.7) : Theme.orange)
            .frame(minWidth: 52, minHeight: 32)
            .background(Theme.boneShade.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .accessibilityLabel("Timer \(timerSeconds == 0 ? "off" : "\(timerSeconds) seconds")")
    }

    private func roundButton(system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.bone)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.leather))
                .overlay(Circle().strokeBorder(Theme.boneShade, lineWidth: 2))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(label)
    }

    // MARK: Ejected print

    @ViewBuilder
    private var ejectedCard: some View {
        if let id = ejectedID, let shot = shots.shot(id), let img = shots.filtered(for: shot) {
            GeometryReader { geo in
                let cardW = geo.size.width * 0.72
                let cardH = cardW * CardMetrics.heightRatio
                InstantCard(image: img, frame: shot.frame, caption: shot.caption,
                             stickers: shot.stickers, progress: 0.05)
                    .frame(width: cardW, height: cardH)
                    // starts hidden behind the body, slides up out of the slot
                    .offset(x: (geo.size.width - cardW) / 2,
                            y: 40 - cardH * 0.42 * ejectProgress)
                    .contentShape(Rectangle())
                    .onTapGesture { showGallery = true }
            }
            .frame(height: 0)
            .zIndex(-1)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack {
            Button { showGallery = true } label: {
                HStack(spacing: 10) {
                    thumbnail
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ROLL")
                            .font(Theme.mono(12, weight: .bold)).tracking(2)
                        Text(shots.shots.isEmpty ? "No prints yet" : "\(shots.shots.count) print\(shots.shots.count == 1 ? "" : "s")")
                            .font(Theme.mono(11)).opacity(0.7)
                    }
                    .foregroundStyle(Theme.bone)
                }
                .frame(minHeight: 48)
            }
            .accessibilityLabel("Open your prints")
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if shots.shots.contains(where: { !$0.isDeveloped(at: context.date) }) {
                    Label("Shake to develop", systemImage: "iphone.gen3.radiowaves.left.and.right")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.bone.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 10)
        .padding(.top, 14)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let latest = shots.shots.first, let img = shots.filtered(for: latest) {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .padding(3)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(radius: 3)
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Theme.bone.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3]))
                .frame(width: 48, height: 48)
        }
    }

    // MARK: Capture

    private func shutterTapped() {
        if countdown != nil {   // a second tap cancels a running countdown
            captureTask?.cancel()
            return
        }
        guard !isCapturing else { return }
        if !store.isPlus && usage.remaining == 0 {
            paywallReason = "You've used today's \(AppConfig.freeDailyPics) free pics."
            showPaywall = true
            return
        }
        isCapturing = true
        captureTask = Task {
            defer { isCapturing = false; countdown = nil }
            if timerSeconds > 0 {
                for s in stride(from: timerSeconds, to: 0, by: -1) {
                    countdown = s
                    try? await Task.sleep(for: .seconds(1))
                    if Task.isCancelled { return }
                }
                countdown = nil
            }
            do {
                Haptics.tap(.heavy)
                withAnimation(.easeOut(duration: 0.08)) { flash = true }
                let raw = try await camera.capture()
                withAnimation(.easeIn(duration: 0.25)) { flash = false }

                let square = ImageProcessor.squareCrop(raw, mirrored: camera.position == .front)
                let shot = shots.add(square)
                if !store.isPlus { usage.recordShot() }
                eject(shot)
            } catch {
                flash = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func eject(_ shot: Shot) {
        ejectedID = shot.id
        ejectProgress = 0
        withAnimation(.easeInOut(duration: 1.1)) { ejectProgress = 1 }
        Task {
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation(.easeIn(duration: 0.35)) {
                if ejectedID == shot.id { ejectedID = nil }
            }
        }
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
