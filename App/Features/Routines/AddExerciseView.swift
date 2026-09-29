import SwiftUI
import SwiftData

public struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var routine: Routine
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    
    public init(routine: Routine) {
        self.routine = routine
    }
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            addExerciseToRoutine(exercise)
                        }) {
                            ExerciseRow(exercise: exercise)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search to add...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func addExerciseToRoutine(_ exercise: Exercise) {
        let newOrder = routine.routineExercises.count
        let routineExercise = RoutineExercise(
            order: newOrder,
            targetSets: 3,
            targetRepRange: "8-12",
            restSeconds: exercise.defaultRestTime
        )
        routineExercise.exercise = exercise
        routine.routineExercises.append(routineExercise)
        
        try? modelContext.save()
        Haptics.shared.playSelection()
        dismiss()
    }
}
