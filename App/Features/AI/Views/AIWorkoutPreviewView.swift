import SwiftUI
import SwiftData

public struct AIWorkoutPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var generatedWorkout: AIGeneratedWorkout
    @State private var exercisesMap: [String: Exercise] = [:]
    
    public init(generatedWorkout: AIGeneratedWorkout) {
        _generatedWorkout = State(initialValue: generatedWorkout)
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.l) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                        Text(generatedWorkout.name)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)
                        Text(generatedWorkout.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            Image(systemName: "clock")
                            Text("~ \(generatedWorkout.estimatedDurationMinutes) min")
                        }
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.primary)
                        .padding(.top, AppSpacing.xs)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                    
                    // Exercise List
                    ForEach($generatedWorkout.exercises) { $genEx in
                        if let exercise = exercisesMap[genEx.exerciseID] {
                            AIPreviewExerciseCard(genEx: $genEx, exercise: exercise)
                        }
                    }
                    
                    // Actions
                    VStack(spacing: AppSpacing.m) {
                        Button(action: saveToSwiftData) {
                            Text("SAVE ROUTINE")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primaryGradient)
                                .cornerRadius(AppRadius.large)
                                .appShadow(AppShadows.medium)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Discard & Regenerate")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(.top, AppSpacing.l)
                }
                .padding()
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExercises)
    }
    
    private func loadExercises() {
        let descriptor = FetchDescriptor<Exercise>()
        if let allExercises = try? modelContext.fetch(descriptor) {
            var map = [String: Exercise]()
            for ex in allExercises {
                map[ex.id.uuidString] = ex
            }
            exercisesMap = map
        }
    }
    
    private func saveToSwiftData() {
        // Safe conversion from AIGeneratedWorkout -> Routine -> RoutineExercise
        let routine = Routine(name: generatedWorkout.name)
        routine.userNotes = generatedWorkout.description
        modelContext.insert(routine)
        
        let sortedEx = generatedWorkout.exercises.sorted(by: { $0.order < $1.order })
        
        for genEx in sortedEx {
            guard let realExercise = exercisesMap[genEx.exerciseID] else { continue }
            
            let routineEx = RoutineExercise(
                order: genEx.order,
                targetSets: genEx.targetSets,
                targetRepRange: "\(genEx.repRangeMin)-\(genEx.repRangeMax)",
                restSeconds: genEx.restSeconds,
                supersetID: genEx.supersetGroupID != nil ? UUID(uuidString: genEx.supersetGroupID!) : nil
            )
            routineEx.notes = genEx.notes
            routineEx.exercise = realExercise
            routineEx.routine = routine
            
            modelContext.insert(routineEx)
        }
        
        do {
            try modelContext.save()
            Haptics.shared.success()
            // In a real app we'd pop to root here
            dismiss()
        } catch {
            print("Failed to save generated routine: \(error)")
        }
    }
}

struct AIPreviewExerciseCard: View {
    @Binding var genEx: AIGeneratedExercise
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(exercise.primaryMuscle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            
            HStack(spacing: AppSpacing.l) {
                VStack(alignment: .center) {
                    Text("SETS")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(genEx.targetSets)")
                        .font(AppTypography.title3)
                }
                VStack(alignment: .center) {
                    Text("REPS")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(genEx.repRangeMin)-\(genEx.repRangeMax)")
                        .font(AppTypography.title3)
                }
                VStack(alignment: .center) {
                    Text("REST")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(genEx.restSeconds)s")
                        .font(AppTypography.title3)
                }
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(.top, AppSpacing.xs)
            
            if let notes = genEx.notes {
                Text(notes)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
}
