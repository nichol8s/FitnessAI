import Foundation
import SwiftData
import SwiftUI

public final class AnalyticsService {
    private let context: ModelContext
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Core Aggregations
    
    @MainActor
    public func getCompletedWorkouts(in dateRange: ClosedRange<Date>? = nil) -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        guard let workouts = try? context.fetch(descriptor) else { return [] }
        
        if let range = dateRange {
            return workouts.filter { range.contains($0.startTime) }
        }
        return workouts
    }
    
    @MainActor
    public func getOverviewStats(for workouts: [Workout]) -> OverviewStats {
        let totalWorkouts = workouts.count
        let totalVolume = workouts.reduce(0) { $0 + $1.totalVolume }
        let totalSets = workouts.reduce(0) { $0 + $1.totalSets }
        
        return OverviewStats(
            totalWorkouts: totalWorkouts,
            totalVolume: totalVolume,
            totalSets: totalSets,
            streak: calculateStreak(from: workouts)
        )
    }
    
    // MARK: - Volume Analytics
    
    @MainActor
    public func getVolumeByMuscleGroup(for workouts: [Workout]) -> [(muscle: String, volume: Double, sets: Int)] {
        var muscleData: [String: (volume: Double, sets: Int)] = [:]
        
        for workout in workouts {
            for workoutEx in workout.workoutExercises {
                guard let muscle = workoutEx.exercise?.primaryMuscle else { continue }
                
                var exVolume: Double = 0
                var exSets: Int = 0
                
                for set in workoutEx.sets where set.isCompleted {
                    exSets += 1
                    if set.setType != "warmup" {
                        exVolume += (set.weight * Double(set.reps))
                    }
                }
                
                let current = muscleData[muscle] ?? (volume: 0, sets: 0)
                muscleData[muscle] = (volume: current.volume + exVolume, sets: current.sets + exSets)
            }
        }
        
        return muscleData.map { (muscle: $0.key, volume: $0.value.volume, sets: $0.value.sets) }
            .sorted(by: { $0.volume > $1.volume })
    }
    
    // MARK: - Streak Logic
    
    private func calculateStreak(from workouts: [Workout]) -> Int {
        // Simplified consecutive days streak
        guard !workouts.isEmpty else { return 0 }
        let calendar = Calendar.current
        
        let startOfDays = workouts.map { calendar.startOfDay(for: $0.startTime) }
        let uniqueDays = Array(Set(startOfDays)).sorted(by: >)
        
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())
        
        // If they haven't worked out today or yesterday, streak is broken
        guard let firstDay = uniqueDays.first,
              let daysSinceLatest = calendar.dateComponents([.day], from: firstDay, to: today).day,
              daysSinceLatest <= 1 else {
            return 0
        }
        
        var expectedDay = firstDay
        for day in uniqueDays {
            if day == expectedDay {
                currentStreak += 1
                expectedDay = calendar.date(byAdding: .day, value: -1, to: expectedDay)!
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    // MARK: - Structs
    public struct OverviewStats {
        public let totalWorkouts: Int
        public let totalVolume: Double
        public let totalSets: Int
        public let streak: Int
    }
}
