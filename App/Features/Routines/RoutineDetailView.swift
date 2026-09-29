import SwiftUI
import SwiftData

public struct RoutineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    @Bindable var routine: Routine
    
    @State private var showingAddExercise = false
    @State private var exerciseToSubstitute: RoutineExercise?
    
    public init(routine: Routine) {
        self.routine = routine
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    Section {
                        if routine.routineExercises.isEmpty {
                            Text("No exercises added yet.")
                                .foregroundColor(AppColors.textSecondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(routine.routineExercises.sorted(by: { $0.order < $1.order })) { routineEx in
                                RoutineExerciseRow(routineExercise: routineEx)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            exerciseToSubstitute = routineEx
                                        } label: {
                                            Label("Substitute", systemImage: "sparkles")
                                        }
                                        .tint(AppColors.primary)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onMove(perform: moveExercises)
                            .onDelete(perform: deleteExercises)
                        }
                    }
                    
                    Section {
                        Button(action: { showingAddExercise = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                            }
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.primary)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                // Start Workout Button
                Button(action: {
                    Haptics.shared.playSelection()
                    workoutManager.startWorkout(from: routine, context: modelContext)
                }) {
                    Text("START WORKOUT")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGradient)
                        .cornerRadius(AppRadius.large)
                        .appShadow(AppShadows.medium)
                }
                .padding()
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    routine.isFavorite.toggle()
                }) {
                    Image(systemName: routine.isFavorite ? "star.fill" : "star")
                        .foregroundColor(routine.isFavorite ? AppColors.warning : AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(routine: routine)
        }
        .sheet(item: $exerciseToSubstitute) { routineEx in
            if let exercise = routineEx.exercise {
                ExerciseSubstitutionView(originalExercise: exercise) { newExercise in
                    routineEx.exercise = newExercise
                    try? modelContext.save()
                }
            }
        }
        .requiresProEntitlement(for: .aiExerciseSubstitution, item: $exerciseToSubstitute)
    }
    
    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = routine.routineExercises.sorted(by: { $0.order < $1.order })
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() {
            exercise.order = index
        }
        try? modelContext.save()
    }
    
    private func deleteExercises(offsets: IndexSet) {
        let sorted = routine.routineExercises.sorted(by: { $0.order < $1.order })
        for index in offsets {
            let exercise = sorted[index]
            modelContext.delete(exercise)
        }
        try? modelContext.save()
    }
}

public struct RoutineExerciseRow: View {
    let routineExercise: RoutineExercise
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(routineExercise.exercise?.name ?? "Unknown Exercise")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.m) {
                Label("\(routineExercise.targetSets) × \(routineExercise.targetRepRange)", systemImage: "repeat")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Label("\(routineExercise.restSeconds)s rest", systemImage: "timer")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
}
