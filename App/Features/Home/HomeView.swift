import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        headerSection
                        todayWorkoutSection
                        weeklyActivitySection
                        recentPRSection
                        aiInsightSection
                    }
                    .padding(AppSpacing.m)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Good morning, \(users.first?.name ?? "Athlete")")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        // Handled in toolbar for premium look, but can place extra greetings here if desired
        EmptyView()
    }
    
    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("TODAY'S WORKOUT")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .kerning(1.2)
            
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Push Day")
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("5 exercises • 45–60 min")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.primary)
                }
                
                Button(action: {
                    Haptics.shared.playSelection()
                    // Start workout action
                }) {
                    Text("START WORKOUT")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGradient)
                        .cornerRadius(AppRadius.large)
                        .appShadow(AppShadows.medium)
                }
            }
            .padding(AppSpacing.l)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppRadius.extraLarge)
        }
    }
    
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("WEEKLY ACTIVITY")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .kerning(1.2)
            
            HStack(spacing: AppSpacing.m) {
                activityStat(title: "Workouts", value: "3")
                activityStat(title: "Volume", value: "12.4k")
                activityStat(title: "Sets", value: "72")
            }
        }
    }
    
    private func activityStat(title: String, value: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            Text(title)
                .font(AppTypography.caption2)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.m)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
    
    private var recentPRSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("RECENT PRs")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .kerning(1.2)
            
            HStack(spacing: AppSpacing.m) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Bench Press")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("80 kg × 8")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("NEW PR")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, AppSpacing.s)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.success.opacity(0.2))
                    .foregroundColor(AppColors.success)
                    .cornerRadius(AppRadius.medium)
            }
            .padding(AppSpacing.l)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppRadius.large)
        }
    }
    
    private var aiInsightSection: some View {
        AIInsightCard()
    }
}
