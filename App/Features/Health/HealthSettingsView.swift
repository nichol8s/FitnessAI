import SwiftUI

public struct HealthSettingsView: View {
    @Bindable private var healthManager = HealthKitManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.l) {
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppColors.error)
                        .padding(.top, AppSpacing.xxl)
                    
                    Text("CONNECT APPLE HEALTH")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Sync your fitness information with Apple Health. We use this to save your workouts and read your body metrics.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.m) {
                        Text("Permissions Requested:")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Label("Workout Data (Write)", systemImage: "figure.strengthtraining.traditional")
                        Label("Body Weight (Read & Write)", systemImage: "scalemass")
                        Label("Height (Read)", systemImage: "ruler")
                        Label("Active Energy (Read)", systemImage: "flame.fill")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                    
                    Spacer()
                    
                    if healthManager.isConnected {
                        Text("Connected to Apple Health")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.success)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.success.opacity(0.1))
                            .cornerRadius(AppRadius.large)
                    } else if let error = healthManager.errorMessage {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                            .multilineTextAlignment(.center)
                    }
                    
                    if !healthManager.isConnected {
                        Button(action: {
                            Task {
                                await healthManager.requestAuthorization()
                            }
                        }) {
                            Text("CONNECT APPLE HEALTH")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.error)
                                .cornerRadius(AppRadius.large)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
