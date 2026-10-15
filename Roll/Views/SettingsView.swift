import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showManage = false

    var body: some View {
        NavigationStack {
            Form {
                if AppConfig.storeEnabled {
                    Section("Roll Plus") {
                        if store.isPlus {
                            Label("Plus is active", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.orange)
                            Button("Manage Subscription") { showManage = true }
                        } else {
                            Button("Get Roll Plus") { showPaywall = true }
                        }
                        Button("Restore Purchases") { Task { await store.restore() } }
                    }
                } else {
                    Section("Open Source") {
                        Label("All features are unlocked", systemImage: "lock.open.fill")
                            .foregroundStyle(Theme.orange)
                        Link("Source code on GitHub", destination: AppConfig.repoURL)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: AppConfig.privacyURL)
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    Link("Support", destination: AppConfig.supportURL)
                    Button("Rate Roll") { requestReview() }
                    LabeledContent("Version", value: version)
                }

                Section {
                    Text("Your photos are stored only on this device. Roll has no accounts, no analytics and no tracking.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .tint(Theme.orange)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .manageSubscriptionsSheet(isPresented: $showManage)
        .alert("Roll", isPresented: Binding(get: { store.message != nil },
                                            set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(store.message ?? "") }
    }

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}
