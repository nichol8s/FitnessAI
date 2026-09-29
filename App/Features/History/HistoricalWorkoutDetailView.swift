import SwiftUI
import SwiftData

public struct HistoricalWorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutManager.self) private var workoutManager
    
    let workout: Workout
    @State private var showingDeleteConfirmation = false
    
    public init(workout: Workout) {
        self.workout = workout
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.l) {
                    
                    // Header Stats
                    HStack(spacing: AppSpacing.m) {
                        statBox(title: "Duration", value: formatTime(workout.duration ?? 0))
                        statBox(title: "Volume", value: String(format: "%.0f kg", workout.totalVolume))
                        statBox(title: "Sets", value: "\(workout.completedSets)")
                    }
                    
                    // Exercises
                    let sortedExercises = workout.workoutExercises.sorted(by: { $0.order < $1.order })
                    ForEach(sortedExercises) { workoutEx in
                        HistoricalExerciseCard(workoutExercise: workoutEx)
                    }
                    
                    // Action Buttons
                    VStack(spacing: AppSpacing.m) {
                        Button(action: repeatWorkout) {
                            Text("Repeat Workout")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .cornerRadius(AppRadius.large)
                        }
                        
                        Button(action: { showingDeleteConfirmation = true }) {
                            Text("Delete Workout")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.error)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(AppRadius.large)
                        }
                    }
                    .padding(.top, AppSpacing.l)
                }
                .padding()
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(dateString)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .confirmationDialog("Delete Workout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: deleteWorkout)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove this workout and its stats from your history. Personal records set here may be invalidated.")
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startTime)
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(AppTypography.headline)
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
        return "\(minutes)m"
    }
    
    private func repeatWorkout() {
        guard let routine = workout.routine else { return }
        // For a full production implementation, if no routine exists, we'd dynamically create an ephemeral routine here
        // Based on the constraints, we will start it from the linked routine.
        workoutManager.startWorkout(from: routine, context: modelContext)
        dismiss()
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        
        // Rebuild PRs to remove any stale data from this workout
        let prCalculator = PRCalculator(context: modelContext)
        prCalculator.rebuildAllPRs()
        
        dismiss()
    }
}

public struct HistoricalExerciseCard: View {
    let workoutExercise: WorkoutExercise
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(workoutExercise.exercise?.name ?? "Exercise")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding()
            
            let completedSets = workoutExercise.sets.filter { $0.isCompleted }.sorted(by: { $0.setOrder < $1.setOrder })
            
            if completedSets.isEmpty {
                Text("No completed sets.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding()
            } else {
                ForEach(completedSets) { set in
                    HStack {
                        Text(setTypeLabel(for: set))
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text(formatWeight(set.weight) + " kg")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                        
                        Text("\(set.reps) reps")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                        
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.success)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, AppSpacing.xs)
                }
                .padding(.bottom, AppSpacing.s)
            }
        }
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
    
    private func setTypeLabel(for set: WorkoutSet) -> String {
        switch set.setType {
        case "warmup": return "W"
        case "drop": return "D"
        case "failure": return "F"
        default: return "\(set.setOrder + 1)"
        }
    }
    
    private func formatWeight(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
