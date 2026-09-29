import SwiftUI
import SwiftData

public struct AIProgressionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    
    @State private var recommendation: AIProgressionRecommendation?
    @State private var contextData: AIProgressionContext?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingRoutinePicker = false
    
    public init(exercise: Exercise) {
        self.exercise = exercise
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        
                        // Header
                        VStack(spacing: AppSpacing.s) {
                            Text(exercise.name)
                                .font(AppTypography.title2)
                                .foregroundColor(AppColors.textPrimary)
                            Text("Progression Analysis")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                                .kerning(1.2)
                        }
                        
                        if isLoading {
                            ProgressView("Analyzing Performance...")
                                .padding(.top, AppSpacing.xxl)
                        } else if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.error)
                                .padding()
                        } else if let context = contextData, let rec = recommendation {
                            
                            // Deterministic Context
                            if let last = context.recentSessions.first {
                                VStack(alignment: .leading, spacing: AppSpacing.s) {
                                    Text("CURRENT PERFORMANCE")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    HStack {
                                        Text("\(formatWeight(last.weight)) kg × \(last.reps)")
                                            .font(AppTypography.title3)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("Trend: \(context.progressionStatus)")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppRadius.large)
                            }
                            
                            // Recommendation
                            VStack(alignment: .leading, spacing: AppSpacing.m) {
                                Text("COACH RECOMMENDATION")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                                    .kerning(1.2)
                                
                                HStack {
                                    Text("\(formatWeight(rec.recommendedWeight)) kg")
                                        .font(AppTypography.title)
                                        .foregroundColor(AppColors.success)
                                    Text("× \(rec.recommendedRepMin)–\(rec.recommendedRepMax)")
                                        .font(AppTypography.title2)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                Text(rec.reasoning)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(.top, AppSpacing.xs)
                                
                                if let caution = rec.caution {
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(AppColors.warning)
                                        Text(caution)
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                    .padding(.top, AppSpacing.s)
                                }
                            }
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppRadius.large)
                            .appShadow(AppShadows.medium)
                            
                            // Actions
                            VStack(spacing: AppSpacing.m) {
                                Button(action: {
                                    showingRoutinePicker = true
                                }) {
                                    Text("APPLY TO ROUTINE")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.primaryGradient)
                                        .cornerRadius(AppRadius.large)
                                        .appShadow(AppShadows.medium)
                                }
                                .disabled(rec.recommendationType == "insufficientData")
                                
                                Button(action: { dismiss() }) {
                                    Text("NOT NOW")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.top, AppSpacing.l)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: loadAnalysis)
            .sheet(isPresented: $showingRoutinePicker) {
                if let rec = recommendation {
                    RoutinePickerView(exercise: exercise, recommendation: rec)
                }
            }
        }
    }
    
    private func loadAnalysis() {
        Task {
            let service = AIProgressionAnalysisService(context: modelContext)
            let context = await service.analyze(exercise: exercise)
            
            await MainActor.run {
                self.contextData = context
            }
            
            do {
                let rec = try await AIProviderFactory.shared.recommendProgression(context: context)
                let validator = AIProgressionValidator()
                
                await MainActor.run {
                    if case .invalid(let reason) = validator.validate(recommendation: rec, context: context) {
                        self.errorMessage = "Unsafe recommendation rejected: \(reason)"
                    } else {
                        self.recommendation = rec
                    }
                    self.isLoading = false
                    Haptics.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatWeight(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}

// MARK: - Routine Picker Subview

struct RoutinePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var routines: [Routine]
    
    let exercise: Exercise
    let recommendation: AIProgressionRecommendation
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                List {
                    let matchingRoutines = routines.filter { r in
                        r.routineExercises.contains(where: { $0.exercise?.id == exercise.id })
                    }
                    
                    if matchingRoutines.isEmpty {
                        Text("This exercise is not currently in any of your routines.")
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Section("Select Routine to Update") {
                            ForEach(matchingRoutines) { routine in
                                Button(action: {
                                    applyToRoutine(routine)
                                }) {
                                    HStack {
                                        Text(routine.name)
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Apply Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func applyToRoutine(_ routine: Routine) {
        if let routineEx = routine.routineExercises.first(where: { $0.exercise?.id == exercise.id }) {
            routineEx.targetWeight = recommendation.recommendedWeight
            routineEx.targetRepRange = "\(recommendation.recommendedRepMin)-\(recommendation.recommendedRepMax)"
            routineEx.targetSets = recommendation.recommendedSets
            try? modelContext.save()
            Haptics.shared.success()
        }
        dismiss()
    }
}
