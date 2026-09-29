import SwiftUI
import SwiftData

public struct ExerciseSubstitutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let originalExercise: Exercise
    
    @State private var suggestions: [AISubstitutionSuggestion] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var exercisesMap: [String: Exercise] = [:]
    
    // Callback to let the parent handle the actual substitution logic (Routine vs Active Workout)
    let onSubstitute: (Exercise) -> Void
    
    public init(originalExercise: Exercise, onSubstitute: @escaping (Exercise) -> Void) {
        self.originalExercise = originalExercise
        self.onSubstitute = onSubstitute
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.l) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            Text("REPLACE")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .kerning(1.2)
                            Text(originalExercise.name)
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if isLoading {
                            ProgressView("Finding alternatives...")
                                .padding(.top, AppSpacing.xxl)
                        } else if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.error)
                        } else if suggestions.isEmpty {
                            Text("No suitable alternatives found.")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.s) {
                                Text("SUGGESTED ALTERNATIVES")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.primary)
                                    .kerning(1.2)
                                
                                ForEach(suggestions) { suggestion in
                                    if let exercise = exercisesMap[suggestion.exerciseID] {
                                        Button(action: {
                                            Haptics.shared.success()
                                            onSubstitute(exercise)
                                            dismiss()
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                                    Text(exercise.name)
                                                        .font(AppTypography.headline)
                                                        .foregroundColor(AppColors.textPrimary)
                                                    
                                                    HStack {
                                                        Text(exercise.equipment)
                                                        Text("•")
                                                        Text(exercise.primaryMuscle)
                                                    }
                                                    .font(AppTypography.caption2)
                                                    .foregroundColor(AppColors.textSecondary)
                                                    
                                                    Text(suggestion.reason)
                                                        .font(AppTypography.caption)
                                                        .foregroundColor(AppColors.primary)
                                                        .padding(.top, AppSpacing.xxs)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .foregroundColor(AppColors.textTertiary)
                                            }
                                            .padding()
                                            .background(AppColors.secondaryBackground)
                                            .cornerRadius(AppRadius.large)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Substitute Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: loadSuggestions)
        }
    }
    
    private func loadSuggestions() {
        Task {
            let descriptor = FetchDescriptor<Exercise>()
            guard let allExercises = try? modelContext.fetch(descriptor) else {
                await MainActor.run {
                    self.errorMessage = "Failed to load local exercises."
                    self.isLoading = false
                }
                return
            }
            
            var map = [String: Exercise]()
            for ex in allExercises { map[ex.id.uuidString] = ex }
            
            await MainActor.run { self.exercisesMap = map }
            
            let catalog = allExercises.map {
                ExerciseReference(id: $0.id.uuidString, name: $0.name, primaryMuscleGroup: $0.primaryMuscle, equipment: $0.equipment)
            }
            
            let request = AIExerciseSubstitutionRequest(
                exerciseID: originalExercise.id.uuidString,
                exerciseName: originalExercise.name,
                primaryMuscleGroup: originalExercise.primaryMuscle,
                equipment: originalExercise.equipment,
                availableExercises: catalog
            )
            
            do {
                let response = try await AIProviderFactory.shared.suggestExerciseSubstitutions(request: request)
                let validator = AIExerciseSubstitutionValidator()
                
                await MainActor.run {
                    if case .invalid(let reason) = validator.validate(response: response, validExerciseIDs: Set(map.keys)) {
                        self.errorMessage = "AI suggested invalid substitutions: \(reason)"
                    } else {
                        self.suggestions = response.suggestions
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Substitution unavailable offline."
                    self.isLoading = false
                }
            }
        }
    }
}
