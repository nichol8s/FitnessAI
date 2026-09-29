import Foundation
import SwiftData

public struct SampleData {
    
    @MainActor
    public static func seedExercisesIfNeeded(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Exercise>()
            let existingCount = try context.fetchCount(descriptor)
            guard existingCount == 0 else { return }
            
            let initialExercises: [(name: String, primaryMuscle: String, equipment: String, type: String)] = [
                // Chest
                ("Barbell Bench Press", "Chest", "Barbell", "Compound"),
                ("Incline Bench Press", "Chest", "Barbell", "Compound"),
                ("Dumbbell Bench Press", "Chest", "Dumbbell", "Compound"),
                ("Incline Dumbbell Press", "Chest", "Dumbbell", "Compound"),
                ("Dumbbell Fly", "Chest", "Dumbbell", "Isolation"),
                ("Cable Fly", "Chest", "Cable", "Isolation"),
                ("Pec Deck", "Chest", "Machine", "Isolation"),
                ("Push-Up", "Chest", "Bodyweight", "Compound"),
                
                // Back
                ("Deadlift", "Back", "Barbell", "Compound"),
                ("Lat Pulldown", "Back", "Machine", "Compound"),
                ("Pull-Up", "Back", "Bodyweight", "Compound"),
                ("Chin-Up", "Back", "Bodyweight", "Compound"),
                ("Barbell Row", "Back", "Barbell", "Compound"),
                ("Dumbbell Row", "Back", "Dumbbell", "Compound"),
                ("Seated Cable Row", "Back", "Cable", "Compound"),
                ("Chest Supported Row", "Back", "Machine", "Compound"),
                
                // Shoulders
                ("Overhead Press", "Shoulders", "Barbell", "Compound"),
                ("Dumbbell Shoulder Press", "Shoulders", "Dumbbell", "Compound"),
                ("Arnold Press", "Shoulders", "Dumbbell", "Compound"),
                ("Lateral Raise", "Shoulders", "Dumbbell", "Isolation"),
                ("Front Raise", "Shoulders", "Dumbbell", "Isolation"),
                ("Rear Delt Fly", "Shoulders", "Machine", "Isolation"),
                ("Face Pull", "Shoulders", "Cable", "Isolation"),
                
                // Biceps
                ("Barbell Curl", "Biceps", "Barbell", "Isolation"),
                ("Dumbbell Curl", "Biceps", "Dumbbell", "Isolation"),
                ("Hammer Curl", "Biceps", "Dumbbell", "Isolation"),
                ("Incline Dumbbell Curl", "Biceps", "Dumbbell", "Isolation"),
                ("Preacher Curl", "Biceps", "Machine", "Isolation"),
                ("Cable Curl", "Biceps", "Cable", "Isolation"),
                
                // Triceps
                ("Tricep Pushdown", "Triceps", "Cable", "Isolation"),
                ("Overhead Tricep Extension", "Triceps", "Cable", "Isolation"),
                ("Skull Crusher", "Triceps", "Barbell", "Isolation"),
                ("Close Grip Bench Press", "Triceps", "Barbell", "Compound"),
                ("Dips", "Triceps", "Bodyweight", "Compound"),
                
                // Legs
                ("Barbell Squat", "Legs", "Barbell", "Compound"),
                ("Front Squat", "Legs", "Barbell", "Compound"),
                ("Leg Press", "Legs", "Machine", "Compound"),
                ("Romanian Deadlift", "Legs", "Barbell", "Compound"),
                ("Leg Curl", "Legs", "Machine", "Isolation"),
                ("Leg Extension", "Legs", "Machine", "Isolation"),
                ("Bulgarian Split Squat", "Legs", "Dumbbell", "Compound"),
                ("Walking Lunge", "Legs", "Dumbbell", "Compound"),
                ("Hip Thrust", "Legs", "Barbell", "Compound"),
                ("Calf Raise", "Legs", "Machine", "Isolation"),
                ("Seated Calf Raise", "Legs", "Machine", "Isolation"),
                
                // Core
                ("Plank", "Core", "Bodyweight", "Isolation"),
                ("Hanging Leg Raise", "Core", "Bodyweight", "Isolation"),
                ("Cable Crunch", "Core", "Cable", "Isolation"),
                ("Ab Wheel", "Core", "Bodyweight", "Isolation"),
                ("Russian Twist", "Core", "Bodyweight", "Isolation")
            ]
            
            for ex in initialExercises {
                let exercise = Exercise(
                    name: ex.name,
                    primaryMuscle: ex.primaryMuscle,
                    equipment: ex.equipment,
                    movementType: ex.type
                )
                context.insert(exercise)
            }
            
            try context.save()
        } catch {
            print("Failed to seed data: \(error)")
        }
    }
}
