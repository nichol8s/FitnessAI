import SwiftUI

public struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    let workout: Workout
    
    public init(workout: Workout) {
        self.workout = workout
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        
                        VStack(spacing: AppSpacing.xs) {
                            Text("WORKOUT COMPLETE")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.success)
                                .kerning(1.5)
                            
                            Text(formatTime(workout.duration ?? 0))
                                .font(AppTypography.numericLarge)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.top, AppSpacing.xxl)
                        
                        HStack(spacing: AppSpacing.m) {
                            statBox(title: "Exercises", value: "\(workout.workoutExercises.count)")
                            statBox(title: "Sets", value: "\(workout.completedSets)")
                            statBox(title: "Volume", value: String(format: "%.0f kg", workout.totalVolume))
                        }
                        
                        if workoutManager.sessionPRCount > 0 {
                            VStack(spacing: AppSpacing.m) {
                                Text("PERSONAL RECORDS")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .kerning(1.5)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(AppColors.warning)
                                    Text("\(workoutManager.sessionPRCount) PRs Achieved!")
                                        .font(AppTypography.title3)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppColors.warning.opacity(0.1))
                                .cornerRadius(AppRadius.large)
                            }
                            .padding(.top, AppSpacing.m)
                        }
                        
                        AIWorkoutDebriefView(workout: workout)
                            .padding(.top, AppSpacing.m)
                        
                        Button(action: { dismiss() }) {
                            Text("DONE")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primaryGradient)
                                .cornerRadius(AppRadius.large)
                                .appShadow(AppShadows.medium)
                        }
                        .padding(.top, AppSpacing.l)
                    }
                    .padding()
                }
            }
        }
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
        .padding(AppSpacing.m)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
