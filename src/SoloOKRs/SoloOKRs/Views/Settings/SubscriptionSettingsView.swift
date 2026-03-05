// SubscriptionSettingsView.swift
// SoloOKRs
//
// IAP settings UI with StoreKit 2

import SwiftUI
import StoreKit
import SwiftData

struct SubscriptionSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var manager = SubscriptionManager.shared
    @State private var showingError = false
    @State private var isPurchasing = false
    @State private var showingClearConfirmation = false
    
    var body: some View {
        Form {
            // Current status
            Section("Current Plan") {
                HStack {
                    Text("Status")
                    Spacer()
                    statusBadge
                }

                if manager.subscriptionStatus == .trial {
                    HStack {
                        Text("Objectives Used")
                        Spacer()
                        Text("\(manager.objectivesCreated) / 3")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Upgrade options (only show if not subscribed)
            if manager.subscriptionStatus != .subscribed {
                Section("Upgrade to Pro") {
                    if manager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if manager.products.isEmpty {
                        Text("Products unavailable")
                            .foregroundStyle(.secondary)
                    } else {
                        // Lifetime option
                        if let lifetime = manager.lifetimeProduct {
                            ProductRow(
                                product: lifetime,
                                title: "Lifetime Access",
                                subtitle: "One-time purchase, forever yours",
                                isPurchasing: $isPurchasing
                            )
                        }
                        
                        // Monthly option
                        if let monthly = manager.monthlyProduct {
                            ProductRow(
                                product: monthly,
                                title: "Monthly",
                                subtitle: "Cancel anytime",
                                isPurchasing: $isPurchasing
                            )
                        }
                    }
                }
            }

            // Restore
            Section {
                Button {
                    Task {
                        await manager.restorePurchases()
                    }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                        if manager.isLoading {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(manager.isLoading)
            }
            
            // Danger Zone
            Section("Danger Zone") {
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete All App Data")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Subscription")
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(manager.errorMessage ?? "Unknown error")
        }
        .onChange(of: manager.errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .confirmationDialog("Clear All Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All Objectives, Key Results & Tasks", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your OKR data. This action cannot be undone.")
        }
    }
    
    private func clearAllData() {
        DispatchQueue.main.async {
            do {
                try modelContext.delete(model: Objective.self)
                try modelContext.save()
            } catch {
                manager.errorMessage = "Failed to clear data: \(error.localizedDescription)"
            }
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch manager.subscriptionStatus {
        case .trial:
            Text("Trial")
                .foregroundStyle(.orange)
        case .subscribed:
            Text("Pro ✓")
                .foregroundStyle(.green)
        case .expired:
            Text("Expired")
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Product Row

private struct ProductRow: View {
    let product: Product
    let title: String
    let subtitle: String
    @Binding var isPurchasing: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    isPurchasing = true
                    defer { isPurchasing = false }
                    
                    do {
                        try await SubscriptionManager.shared.purchase(product)
                    } catch {
                        print("Purchase failed: \(error)")
                    }
                }
            } label: {
                Text(product.displayPrice)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SubscriptionSettingsView()
}
