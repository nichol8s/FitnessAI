import SwiftUI
import SwiftData

public struct ExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    @Bindable var workoutExercise: WorkoutExercise
    
    @State private var previousSets: [WorkoutSet] = []
    @State private var showingOptions = false
    
    public init(workoutExercise: WorkoutExercise) {
        self.workoutExercise = workoutExercise
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(workoutExercise.exercise?.name ?? "Exercise")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.primary)
                Spacer()
                Button(action: {
                    showingOptions = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.textSecondary)
                        .padding(AppSpacing.xs)
                }
            }
            .padding()
            .confirmationDialog("Exercise Options", isPresented: $showingOptions, titleVisibility: .visible) {
                Button("Add Note") {
                    // Note action
                }
                Button("Replace Exercise") {
                    // Replace action
                }
                Button("Cancel", role: .cancel) {}
            }
            
            // Previous Performance
            HStack {
                if previousSets.isEmpty {
                    Text("FIRST SESSION")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAST TIME")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        ForEach(previousSets) { set in
                            Text("\(format(set.weight)) kg × \(set.reps)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, AppSpacing.s)
            .onAppear {
                if let exercise = workoutExercise.exercise {
                    let historyService = WorkoutHistoryService(context: modelContext)
                    previousSets = historyService.getPreviousPerformance(for: exercise)
                }
            }
            
            // Column Headers
            HStack(spacing: AppSpacing.s) {
                Text("SET")
                    .frame(width: 40)
                Text("KG")
                    .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Image(systemName: "checkmark")
                    .frame(width: 44)
            }
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal)
            
            // Sets
            VStack(spacing: 0) {
                let sortedSets = workoutExercise.sets.sorted(by: { $0.setOrder < $1.setOrder })
                ForEach(sortedSets) { set in
                    SetRow(set: set)
                }
            }
            .padding(.horizontal)
            
            // Add Set Button
            Button(action: {
                let newSetOrder = workoutExercise.sets.count
                // Try to infer weight/reps from last set
                let lastSet = workoutExercise.sets.sorted(by: { $0.setOrder < $1.setOrder }).last
                let set = WorkoutSet(setOrder: newSetOrder, weight: lastSet?.weight ?? 0, reps: lastSet?.reps ?? 0)
                set.restDuration = lastSet?.restDuration ?? 90
                set.workoutExercise = workoutExercise
                try? modelContext.save()
                Haptics.shared.playSelection()
            }) {
                Text("+ ADD SET")
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.m)
                    .background(AppColors.tertiaryBackground)
                    .cornerRadius(AppRadius.medium)
            }
            .padding()
        }
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
        .appShadow(AppShadows.subtle)
        .padding(.horizontal, AppSpacing.m)
    }
    
    private func format(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
