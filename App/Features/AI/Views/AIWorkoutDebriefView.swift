import SwiftUI
import SwiftData

public struct AIWorkoutDebriefView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    let workout: Workout
    
    @State private var analysis: AIWorkoutAnalysis?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    
    public init(workout: Workout) {
        self.workout = workout
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            
            Text("COACH'S TAKE")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.primary)
                .kerning(1.2)
            
            if subscriptionManager.entitlement != .pro {
                VStack(spacing: AppSpacing.m) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                    Text("Subscribe to Fitness Pro to unlock AI workout analysis.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(action: { showingPaywall = true }) {
                        Text("Unlock AI Coach")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.large)
            } else if isLoading {
                VStack(spacing: AppSpacing.s) {
                    ProgressView()
                        .tint(AppColors.primary)
                    Text("Analyzing your performance...")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xl)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.large)
                
            } else if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
            } else if let analysis = analysis {
                
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    // Headline & Summary
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(analysis.headline)
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        Text(analysis.summary)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Highlights
                    if !analysis.highlights.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            Text("WHAT WENT WELL")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textTertiary)
                                .kerning(1.2)
                            
                            ForEach(analysis.highlights) { highlight in
                                HStack(alignment: .top, spacing: AppSpacing.m) {
                                    Image(systemName: iconForHighlight(highlight.type))
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading) {
                                        Text(highlight.title)
                                            .font(AppTypography.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(highlight.description)
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding(.vertical, AppSpacing.xs)
                            }
                        }
                    }
                    
                    // Observations & Next Steps
                    if !analysis.observations.isEmpty || !analysis.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            Text("NOTES FOR NEXT TIME")
                                .font(AppTypography.caption2)
                                .foregroundColor(AppColors.textTertiary)
                                .kerning(1.2)
                            
                            ForEach(analysis.observations + analysis.recommendations, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .foregroundColor(AppColors.primary)
                                    Text(item)
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.large)
                .appShadow(AppShadows.subtle)
            }
        }
        .onAppear(perform: loadAnalysis)
        .sheet(isPresented: $showingPaywall) {
            SubscriptionView()
        }
    }
    
    private func loadAnalysis() {
        guard subscriptionManager.entitlement == .pro else { return }
        Task {
            let service = WorkoutAnalysisService(context: modelContext)
            let context = await service.analyzeWorkout(workout)
            
            do {
                let result = try await AIProviderFactory.shared.analyzeWorkout(context: context)
                let validator = AIWorkoutAnalysisValidator()
                
                await MainActor.run {
                    if case .invalid(let reason) = validator.validate(analysis: result, context: context) {
                        self.errorMessage = "Analysis unavailable offline." // Masking validation error to user
                        print("AI Validation Error: \(reason)")
                    } else {
                        self.analysis = result
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Analysis unavailable offline."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func iconForHighlight(_ type: String) -> String {
        switch type {
        case "personalRecord": return "trophy.fill"
        case "volumeIncrease": return "chart.line.uptrend.xyaxis"
        case "consistency": return "checkmark.seal.fill"
        case "strengthIncrease": return "flame.fill"
        case "volumeDecrease": return "arrow.down.right.circle"
        default: return "star.fill"
        }
    }
}
