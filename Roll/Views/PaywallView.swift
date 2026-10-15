import SwiftUI
import StoreKit

/// Paywall written to satisfy App Review Guideline 3.1.2:
/// shows localized price + billing period, auto-renew disclosure, Restore, Terms and Privacy,
/// and has a clearly visible close button (no dark patterns).
struct PaywallView: View {
    var reason: String? = nil

    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = ProductID.lifetime

    private let features: [(String, String)] = [
        ("infinity", "Unlimited pics every day"),
        ("square.on.square", "All frames and filters"),
        ("star.square", "Every sticker"),
        ("timer", "Selfie timer"),
        ("sparkles", "All future updates"),
    ]

    var body: some View {
        ZStack {
            Theme.leather.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    featureList
                    plans
                    continueButton
                    legal
                }
                .padding(.horizontal, 22)
                .padding(.top, 56)
                .padding(.bottom, 28)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.bone)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Theme.leatherLight))
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 16).padding(.top, 8)
                Spacer()
            }
        }
        .alert("Roll", isPresented: Binding(get: { store.message != nil },
                                            set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(store.message ?? "") }
        .onChange(of: store.isPlus) { _, plus in if plus { dismiss() } }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("ROLL PLUS")
                .font(Theme.mono(13, weight: .bold)).tracking(5)
                .foregroundStyle(Theme.amber)
            Text("Shoot without limits")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Theme.bone)
            if let reason {
                Text(reason)
                    .font(Theme.mono(13)).foregroundStyle(Theme.bone.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(features, id: \.1) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .frame(width: 24)
                        .foregroundStyle(Theme.amber)
                    Text(text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.bone)
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(Theme.leatherLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var plans: some View {
        Group {
            if store.isLoadingProducts && store.products.isEmpty {
                ProgressView().tint(Theme.bone).frame(height: 120)
            } else if store.products.isEmpty {
                VStack(spacing: 10) {
                    Text("Couldn't load prices.")
                        .font(Theme.mono(13)).foregroundStyle(Theme.bone.opacity(0.8))
                    Button("Try again") { Task { await store.loadProducts() } }
                        .buttonStyle(.bordered).tint(Theme.orange)
                }
                .frame(height: 120)
            } else {
                HStack(spacing: 12) {
                    if let m = store.monthly {
                        planCard(m, title: "Monthly", note: "per month, cancel anytime", badge: nil)
                    }
                    if let l = store.lifetime {
                        planCard(l, title: "Lifetime", note: "pay once", badge: "BEST VALUE")
                    }
                }
            }
        }
    }

    private func planCard(_ product: Product, title: String, note: String, badge: String?) -> some View {
        let selected = selectedID == product.id
        return Button { selectedID = product.id } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.mono(14, weight: .bold))
                Text(product.displayPrice)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                Text(note)
                    .font(Theme.mono(11))
                    .multilineTextAlignment(.center)
                    .opacity(0.75)
            }
            .foregroundStyle(selected ? Theme.leather : Theme.bone)
            .frame(maxWidth: .infinity, minHeight: 130)
            .padding(.vertical, 8)
            .background(selected ? Theme.bone : Theme.leatherLight,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Theme.orange : Theme.bone.opacity(0.15), lineWidth: selected ? 3 : 1)
            )
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge)
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(Theme.leather)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.amber, in: Capsule())
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(product.displayPrice), \(note)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedID }
    }

    private var continueButton: some View {
        Button {
            guard let p = selectedProduct else { return }
            Task { await store.purchase(p) }
        } label: {
            HStack {
                if store.isWorking { ProgressView().tint(Theme.leather) }
                Text(selectedID == ProductID.monthly ? "Subscribe" : "Unlock Lifetime")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Theme.leather)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Theme.orange, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(selectedProduct == nil || store.isWorking)
        .opacity(selectedProduct == nil ? 0.5 : 1)
    }

    private var legal: some View {
        VStack(spacing: 12) {
            Text(disclosure)
                .font(.system(size: 11))
                .foregroundStyle(Theme.bone.opacity(0.6))
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Button("Restore Purchases") { Task { await store.restore() } }
                Link("Terms of Use", destination: AppConfig.termsURL)
                Link("Privacy Policy", destination: AppConfig.privacyURL)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.bone.opacity(0.85))
        }
    }

    private var disclosure: String {
        if selectedID == ProductID.monthly, let m = store.monthly {
            return "Roll Plus Monthly: \(m.displayPrice) per month. Payment is charged to your Apple Account at confirmation of purchase. The subscription renews automatically each month unless you cancel at least 24 hours before the end of the current period. Manage or cancel in your Apple Account settings."
        }
        if let l = store.lifetime {
            return "Roll Lifetime: one-time purchase of \(l.displayPrice). No subscription, no recurring charges. Use Restore Purchases on a new device."
        }
        return ""
    }
}
