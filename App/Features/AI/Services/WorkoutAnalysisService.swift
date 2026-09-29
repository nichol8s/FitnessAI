import Foundation
import SwiftData

public final class WorkoutAnalysisService {
    private let modelContext: ModelContext
    
    public init(context: ModelContext) {
        self.modelContext = context
    }
    
    @MainActor
    public func analyzeWorkout(_ workout: Workout) -> AIWorkoutAnalysisContext {
        let duration = Int(workout.duration ?? 0)
        let totalVolume = workout.totalVolume
        var completedSets = 0
        var totalSets = 0
        var exercisesContext: [AIAnalysisExerciseContext] = []
        var musclesTrained = Set<String>()
        
        for workoutEx in workout.workoutExercises {
            let sets = workoutEx.sets
            totalSets += sets.count
            
            let completed = sets.filter { $0.isCompleted && $0.setType == "working" }
            completedSets += completed.count
            
            if let pm = workoutEx.exercise?.primaryMuscle {
                musclesTrained.insert(pm)
            }
            
            let maxW = completed.map(\.weight).max() ?? 0
            let exVol = completed.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            
            exercisesContext.append(AIAnalysisExerciseContext(
                exerciseID: workoutEx.exercise?.id.uuidString ?? UUID().uuidString,
                name: workoutEx.exercise?.name ?? "Unknown",
                setsCompleted: completed.count,
                maxWeight: maxW,
                totalVolume: exVol
            ))
        }
        
        let prCount = calculatePRCount(for: workout)
        let comparison = buildComparison(for: workout, musclesTrained: musclesTrained)
        
        return AIWorkoutAnalysisContext(
            workoutID: workout.id.uuidString,
            workoutName: workout.name,
            durationSeconds: duration,
            totalVolume: totalVolume,
            totalSets: totalSets,
            completedSets: completedSets,
            exerciseCount: workout.workoutExercises.count,
            muscleGroups: Array(musclesTrained),
            prCount: prCount,
            exercises: exercisesContext,
            comparison: comparison
        )
    }
    
    @MainActor
    private func calculatePRCount(for workout: Workout) -> Int {
        // Query PRs achieved exactly on this workout date
        let start = Calendar.current.startOfDay(for: workout.startTime)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.date >= start && $0.date < end }
        )
        let prs = (try? modelContext.fetch(descriptor)) ?? []
        return prs.count
    }
    
    @MainActor
    private func buildComparison(for workout: Workout, musclesTrained: Set<String>) -> AIWorkoutComparisonContext? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == true && $0.id != workout.id },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let allWorkouts = try? modelContext.fetch(descriptor) else { return nil }
        
        // Find the most recent workout that trained heavily overlapping muscles
        for pastWorkout in allWorkouts {
            var pastMuscles = Set<String>()
            for ex in pastWorkout.workoutExercises {
                if let pm = ex.exercise?.primaryMuscle {
                    pastMuscles.insert(pm)
                }
            }
            
            let intersection = musclesTrained.intersection(pastMuscles)
            // If they share at least 50% of muscle groups, consider it comparable
            if !intersection.isEmpty && Double(intersection.count) / Double(musclesTrained.count) >= 0.5 {
                
                let volDiff = pastWorkout.totalVolume > 0 ? (workout.totalVolume - pastWorkout.totalVolume) / pastWorkout.totalVolume : 0
                let durDiff = Int((workout.duration ?? 0) - (pastWorkout.duration ?? 0))
                
                return AIWorkoutComparisonContext(
                    previousWorkoutDate: pastWorkout.startTime,
                    volumeChangePercent: volDiff,
                    durationChangeSeconds: durDiff
                )
            }
        }
        
        return nil
    }
}
