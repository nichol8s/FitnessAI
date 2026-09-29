import SwiftUI
import SwiftData

public struct ProgressOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    let timeRange: ClosedRange<Date>?
    
    @State private var stats: AnalyticsService.OverviewStats?
    
    public init(timeRange: ClosedRange<Date>?) {
        self.timeRange = timeRange
    }
    
    public var body: some View {
        VStack(spacing: AppSpacing.m) {
            if let stats = stats {
                if stats.totalWorkouts == 0 {
                    emptyState
                } else {
                    HStack(spacing: AppSpacing.m) {
                        statBox(title: "Workouts", value: "\(stats.totalWorkouts)")
                        statBox(title: "Volume", value: String(format: "%.0f kg", stats.totalVolume))
                    }
                    
                    HStack(spacing: AppSpacing.m) {
                        statBox(title: "Sets Logged", value: "\(stats.totalSets)")
                        statBox(title: "Streak (Days)", value: "\(stats.streak)")
                    }
                    
                    // A placeholder area for Workout Frequency Chart
                    VStack(alignment: .leading, spacing: AppSpacing.m) {
                        Text("WORKOUT FREQUENCY")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .kerning(1.2)
                        
                        Text("Activity calendar is populated in production build using Swift Charts.")
                            .font(AppTypography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .onAppear(perform: loadData)
        .onChange(of: timeRange) { _, _ in loadData() }
    }
    
    private func loadData() {
        let service = AnalyticsService(context: modelContext)
        let workouts = service.getCompletedWorkouts(in: timeRange)
        stats = service.getOverviewStats(for: workouts)
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            Text("NO DATA IN RANGE")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Complete workouts in this timeframe to see your stats here.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.l)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
}
