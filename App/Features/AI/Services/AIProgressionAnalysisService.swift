import Foundation
import SwiftData

public final class AIProgressionAnalysisService {
    private let modelContext: ModelContext
    
    public init(context: ModelContext) {
        self.modelContext = context
    }
    
    @MainActor
    public func analyze(exercise: Exercise) -> AIProgressionContext {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        guard let workouts = try? modelContext.fetch(descriptor) else {
            return fallbackContext(exercise: exercise, status: "insufficientData")
        }
        
        var sessions: [AIProgressionSession] = []
        var latestDate: Date? = nil
        
        // Find top 3 recent sessions containing this exercise
        for workout in workouts {
            guard let workoutEx = workout.workoutExercises.first(where: { $0.exercise?.id == exercise.id }) else { continue }
            
            let workingSets = workoutEx.sets.filter { $0.setType == "working" && $0.isCompleted }
            guard !workingSets.isEmpty else { continue }
            
            // Average weight/reps of working sets for the session profile
            let avgWeight = workingSets.reduce(0.0) { $0 + $1.weight } / Double(workingSets.count)
            let avgReps = workingSets.reduce(0) { $0 + $1.reps } / workingSets.count
            let totalVolume = workingSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
            
            // Reusing existing PRCalculator formula (Epley) locally
            let estimated1RM = calculate1RM(weight: avgWeight, reps: avgReps)
            
            if latestDate == nil {
                latestDate = workout.startTime
            }
            
            sessions.append(AIProgressionSession(
                date: workout.startTime,
                weight: avgWeight,
                reps: avgReps,
                sets: workingSets.count,
                volume: totalVolume,
                estimated1RM: estimated1RM
            ))
            
            if sessions.count == 3 { break }
        }
        
        var status = "insufficientData"
        if sessions.count >= 2 {
            let latest = sessions[0].estimated1RM
            let previous = sessions[1].estimated1RM
            let diff = (latest - previous) / previous
            
            if diff > 0.05 {
                status = "progressing"
            } else if diff < -0.05 {
                status = "regressing"
            } else {
                status = "stable"
            }
        }
        
        // Find global PR
        let prDescriptor = FetchDescriptor<PersonalRecord>()
        let allPRs = (try? modelContext.fetch(prDescriptor)) ?? []
        let bestPR = allPRs.first(where: { $0.exercise?.id == exercise.id && $0.recordType == "1rm" })?.value
        
        let daysSince = latestDate.flatMap { Calendar.current.dateComponents([.day], from: $0, to: Date()).day }
        
        return AIProgressionContext(
            exerciseID: exercise.id.uuidString,
            exerciseName: exercise.name,
            primaryMuscleGroup: exercise.primaryMuscle,
            recentSessions: sessions,
            progressionStatus: status,
            personalRecord: bestPR,
            daysSinceLastPerformed: daysSince
        )
    }
    
    private func calculate1RM(weight: Double, reps: Int) -> Double {
        if reps == 1 { return weight }
        if reps == 0 { return 0 }
        return weight * (1.0 + (Double(reps) / 30.0))
    }
    
    private func fallbackContext(exercise: Exercise, status: String) -> AIProgressionContext {
        return AIProgressionContext(
            exerciseID: exercise.id.uuidString,
            exerciseName: exercise.name,
            primaryMuscleGroup: exercise.primaryMuscle,
            recentSessions: [],
            progressionStatus: status,
            personalRecord: nil,
            daysSinceLastPerformed: nil
        )
    }
}
