import Foundation
import SwiftData

public enum AIValidationResult {
    case valid
    case invalid(reason: String)
}

public final class AIWorkoutValidator {
    private let modelContext: ModelContext
    
    public init(context: ModelContext) {
        self.modelContext = context
    }
    
    @MainActor
    public func validate(_ workout: AIGeneratedWorkout) -> AIValidationResult {
        // 1. Basic structural checks
        guard !workout.name.isEmpty else { return .invalid(reason: "Workout name is empty.") }
        guard !workout.exercises.isEmpty else { return .invalid(reason: "Workout contains no exercises.") }
        guard workout.exercises.count <= 15 else { return .invalid(reason: "Workout contains too many exercises.") }
        guard workout.estimatedDurationMinutes > 0 && workout.estimatedDurationMinutes <= 180 else {
            return .invalid(reason: "Workout duration is unreasonable.")
        }
        
        // 2. Database mapping
        let allExercisesDescriptor = FetchDescriptor<Exercise>()
        guard let allExercises = try? modelContext.fetch(allExercisesDescriptor) else {
            return .invalid(reason: "Failed to read local exercise database.")
        }
        let validExerciseIDs = Set(allExercises.map { $0.id.uuidString })
        
        // 3. Deep exercise validation
        var seenOrders = Set<Int>()
        var calculatedDurationSeconds = 0
        
        for exercise in workout.exercises {
            // Validate UUID exists locally
            guard validExerciseIDs.contains(exercise.exerciseID) else {
                return .invalid(reason: "AI generated an unknown exercise ID: \(exercise.exerciseID)")
            }
            
            // Validate sets
            guard exercise.targetSets > 0 && exercise.targetSets <= 10 else {
                return .invalid(reason: "Unreasonable target sets for exercise: \(exercise.targetSets)")
            }
            
            // Validate reps
            guard exercise.repRangeMin > 0 && exercise.repRangeMax >= exercise.repRangeMin && exercise.repRangeMax <= 100 else {
                return .invalid(reason: "Unreasonable rep range: \(exercise.repRangeMin)-\(exercise.repRangeMax)")
            }
            
            // Validate rest
            guard exercise.restSeconds >= 0 && exercise.restSeconds <= 600 else {
                return .invalid(reason: "Unreasonable rest duration: \(exercise.restSeconds)s")
            }
            
            // Duplicate order protection
            if seenOrders.contains(exercise.order) {
                return .invalid(reason: "Duplicate exercise order index.")
            }
            seenOrders.insert(exercise.order)
            
            // Estimate duration (assume 45s per set on average + rest)
            calculatedDurationSeconds += exercise.targetSets * (45 + exercise.restSeconds)
        }
        
        let calculatedMinutes = calculatedDurationSeconds / 60
        if calculatedMinutes > (workout.estimatedDurationMinutes * 2) || calculatedMinutes < (workout.estimatedDurationMinutes / 3) {
            // If the AI's estimate is wildly off from reality, we flag it. 
            // In a production app we might just auto-correct it instead of blocking, but this satisfies the strict check.
            return .invalid(reason: "Estimated duration of \(workout.estimatedDurationMinutes)m conflicts with actual calculated time of \(calculatedMinutes)m.")
        }
        
        return .valid
    }
}
