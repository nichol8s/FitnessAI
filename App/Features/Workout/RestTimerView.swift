import SwiftUI

public struct RestTimerView: View {
    @Environment(WorkoutManager.self) private var workoutManager
    
    public var body: some View {
        if let restString = workoutManager.currentTimer.formattedRest {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: "timer")
                    .foregroundColor(AppColors.warning)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("REST")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .kerning(1.2)
                    
                    Text(restString)
                        .font(AppTypography.numericMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    workoutManager.currentTimer.subtractRestTime(15)
                    Haptics.shared.playSelection()
                }) {
                    Text("-15s")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, AppSpacing.s)
                        .background(AppColors.tertiaryBackground)
                        .cornerRadius(AppRadius.medium)
                }
                
                Button(action: {
                    workoutManager.currentTimer.addRestTime(30)
                    Haptics.shared.playSelection()
                }) {
                    Text("+30s")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppSpacing.m)
                        .padding(.vertical, AppSpacing.s)
                        .background(AppColors.tertiaryBackground)
                        .cornerRadius(AppRadius.medium)
                }
                
                Button(action: {
                    workoutManager.currentTimer.skipRest()
                    Haptics.shared.playSelection()
                }) {
                    Text("Skip")
                        .font(AppTypography.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppSpacing.m)
                        .padding(.vertical, AppSpacing.s)
                        .background(AppColors.primary.opacity(0.2))
                        .foregroundColor(AppColors.primary)
                        .cornerRadius(AppRadius.medium)
                }
            }
            .padding(AppSpacing.m)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppRadius.large)
            .appShadow(AppShadows.strong)
            .padding(.horizontal, AppSpacing.m)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
