// SubscriptionSettingsView.swift
// SoloOKRs
//
// IAP settings UI with StoreKit 2

import SwiftUI
import StoreKit

struct SubscriptionSettingsView: View {
    @State private var manager = SubscriptionManager.shared
    @State private var showingError = false
    @State private var isPurchasing = false
    
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
