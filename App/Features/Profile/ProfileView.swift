import SwiftUI

public struct ProfileView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                List {
                    Section(header: Text("Subscription")) {
                        HStack {
                            Text("Plan")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(subscriptionManager.entitlement == .pro ? "Fitness Pro" : "Fitness Free")
                                .foregroundColor(subscriptionManager.entitlement == .pro ? AppColors.primary : AppColors.textSecondary)
                        }
                        
                        if subscriptionManager.entitlement != .pro {
                            Button("Upgrade to Pro") {
                                showingPaywall = true
                            }
                            .foregroundColor(AppColors.primary)
                        }
                        
                        Button("Restore Purchases") {
                            Task { try? await subscriptionManager.restorePurchases() }
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                    Section(header: Text("Integrations")) {
                        NavigationLink(destination: HealthSettingsView()) {
                            Label("Apple Health", systemImage: "heart.text.square.fill")
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    
                    Section(header: Text("Account")) {
                        Text("Profile settings would go here in production.")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
            }
        }
    }
}
