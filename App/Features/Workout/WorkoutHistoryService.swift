import Foundation
import SwiftData

public final class WorkoutHistoryService {
    private let context: ModelContext
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    /// Finds the most recent completed sets for a given exercise
    @MainActor
    public func getPreviousPerformance(for exercise: Exercise) -> [WorkoutSet] {
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.isCompleted == true
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let workouts = try? context.fetch(descriptor) else { return [] }
        
        // Find the first workout that contains this exercise
        for workout in workouts {
            if let workoutEx = workout.workoutExercises.first(where: { $0.exercise?.id == exerciseId }) {
                // Return only completed sets
                let sets = workoutEx.sets.filter { $0.isCompleted }.sorted(by: { $0.setOrder < $1.setOrder })
                if !sets.isEmpty {
                    return sets
                }
            }
        }
        
        return []
    }
}
