import SwiftUI
import StoreKit

public struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        
                        // Header
                        VStack(spacing: AppSpacing.s) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.primary)
                                .padding(.top, AppSpacing.xl)
                            
                            Text("Fitness Pro")
                                .font(AppTypography.title)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Unlock your AI Coach and accelerate your progress.")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: AppSpacing.m) {
                            benefitRow(icon: "brain.head.profile", title: "AI Workout Generation", desc: "Instantly create tailored workouts.")
                            benefitRow(icon: "chart.line.uptrend.xyaxis", title: "Progressive Overload", desc: "AI-driven weight recommendations.")
                            benefitRow(icon: "sparkles", title: "Post-Workout Debrief", desc: "Detailed AI analysis of every session.")
                            benefitRow(icon: "mic.fill", title: "Fast AI Logging", desc: "Log sets using natural language.")
                        }
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                        }
                        
                        // Products
                        if subscriptionManager.products.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            VStack(spacing: AppSpacing.m) {
                                ForEach(subscriptionManager.products, id: \.id) { product in
                                    Button(action: {
                                        purchase(product)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(product.displayName)
                                                    .font(AppTypography.headline)
                                                    .foregroundColor(AppColors.textPrimary)
                                                Text(product.description)
                                                    .font(AppTypography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            Text(product.displayPrice)
                                                .font(AppTypography.title3)
                                                .foregroundColor(AppColors.primary)
                                        }
                                        .padding()
                                        .background(AppColors.secondaryBackground)
                                        .cornerRadius(AppRadius.large)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.large)
                                                .stroke(AppColors.primary, lineWidth: 1)
                                        )
                                    }
                                    .disabled(isPurchasing)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Footer Actions
                        VStack(spacing: AppSpacing.l) {
                            Button(action: restorePurchases) {
                                Text("Restore Purchases")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.primary)
                            }
                            .disabled(isPurchasing)
                            
                            HStack(spacing: AppSpacing.l) {
                                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            }
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(.top, AppSpacing.xl)
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
            }
            // Dismiss automatically if entitlement becomes pro during purchase
            .onChange(of: subscriptionManager.entitlement) { _, newValue in
                if newValue == .pro {
                    Haptics.shared.success()
                    dismiss()
                }
            }
        }
    }
    
    private func benefitRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(desc)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await subscriptionManager.purchase(product)
            } catch SubscriptionError.userCancelled {
                // Ignore silent cancellation
            } catch {
                errorMessage = "Purchase failed. Please try again."
            }
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        errorMessage = nil
        
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.entitlement != .pro {
                    errorMessage = "No active subscription found."
                }
            } catch {
                errorMessage = "Failed to restore purchases."
            }
            isPurchasing = false
        }
    }
}
