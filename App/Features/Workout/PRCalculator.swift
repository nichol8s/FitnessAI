import Foundation
import SwiftData

public final class PRCalculator {
    private let context: ModelContext
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    @MainActor
    public func detectAndSavePRs(for workout: Workout) -> Int {
        var newPRCount = 0
        
        for workoutEx in workout.workoutExercises {
            guard let exercise = workoutEx.exercise else { continue }
            
            let completedSets = workoutEx.sets.filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }
            guard !completedSets.isEmpty else { continue }
            
            // Calculate bests for this session
            let sessionMaxWeight = completedSets.map { $0.weight }.max() ?? 0
            let sessionMaxVolume = completedSets.map { $0.weight * Double($0.reps) }.reduce(0, +)
            let sessionMax1RM = completedSets.map { calculate1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
            
            // Query existing PRs
            let existingPRs = getExistingPRs(for: exercise)
            
            // 1. Max Weight PR
            let historicalMaxWeight = existingPRs.first(where: { $0.recordType == "weight" })?.value ?? 0
            if sessionMaxWeight > historicalMaxWeight {
                savePR(exercise: exercise, type: "weight", value: sessionMaxWeight, date: workout.endTime ?? Date())
                newPRCount += 1
            }
            
            // 2. Max Volume PR
            let historicalMaxVolume = existingPRs.first(where: { $0.recordType == "volume" })?.value ?? 0
            if sessionMaxVolume > historicalMaxVolume {
                savePR(exercise: exercise, type: "volume", value: sessionMaxVolume, date: workout.endTime ?? Date())
                newPRCount += 1
            }
            
            // 3. Estimated 1RM PR
            let historicalMax1RM = existingPRs.first(where: { $0.recordType == "1rm" })?.value ?? 0
            if sessionMax1RM > historicalMax1RM {
                savePR(exercise: exercise, type: "1rm", value: sessionMax1RM, date: workout.endTime ?? Date())
                newPRCount += 1
            }
        }
        
        try? context.save()
        return newPRCount
    }
    
    @MainActor
    private func getExistingPRs(for exercise: Exercise) -> [PersonalRecord] {
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.exercise?.id == exerciseId
            }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    @MainActor
    private func savePR(exercise: Exercise, type: String, value: Double, date: Date) {
        let pr = PersonalRecord(recordType: type, value: value, date: date)
        pr.exercise = exercise
        context.insert(pr)
    }
    
    @MainActor
    public func rebuildAllPRs() {
        // 1. Delete all existing PRs
        let allPRsDescriptor = FetchDescriptor<PersonalRecord>()
        if let allPRs = try? context.fetch(allPRsDescriptor) {
            for pr in allPRs {
                context.delete(pr)
            }
        }
        
        // 2. Fetch all completed workouts sorted chronologically
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.startTime, order: .forward)] // forward to simulate history
        )
        guard let completedWorkouts = try? context.fetch(workoutDescriptor) else { return }
        
        // 3. Re-run detection over history
        for workout in completedWorkouts {
            _ = detectAndSavePRs(for: workout)
        }
        try? context.save()
    }
    
    /// Epley Formula for 1RM
    private func calculate1RM(weight: Double, reps: Int) -> Double {
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}
