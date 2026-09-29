import Foundation
import SwiftData

public final class AIContextBuilder {
    private let modelContext: ModelContext
    
    public init(context: ModelContext) {
        self.modelContext = context
    }
    
    @MainActor
    public func buildFitnessContext() -> AIFitnessContext {
        // Fetch User profile (No names or PII exposed)
        let userDescriptor = FetchDescriptor<User>()
        let user = (try? modelContext.fetch(userDescriptor))?.first
        let experience = user?.trainingExperience ?? "intermediate"
        
        // Fetch recent workouts (Last 14 days)
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == true && $0.startTime >= twoWeeksAgo },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let recentWorkouts = (try? modelContext.fetch(workoutDescriptor)) ?? []
        
        let recentWorkoutContexts = recentWorkouts.map { workout -> AIRecentWorkoutContext in
            let daysAgo = calendar.dateComponents([.day], from: workout.startTime, to: Date()).day ?? 0
            
            // Extract unique primary muscles trained
            var muscles: Set<String> = []
            for ex in workout.workoutExercises {
                if let pm = ex.exercise?.primaryMuscle {
                    muscles.insert(pm)
                }
            }
            
            return AIRecentWorkoutContext(
                name: workout.name,
                durationMinutes: Int(workout.duration ?? 0) / 60,
                totalVolume: workout.totalVolume,
                primaryMuscleGroups: Array(muscles),
                daysAgo: daysAgo
            )
        }
        
        // Calculate total volume for the past 7 days
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recentWeekWorkouts = recentWorkouts.filter { $0.startTime >= oneWeekAgo }
        let totalVolumeWeek = recentWeekWorkouts.reduce(0) { $0 + $1.totalVolume }
        
        // Calculate Streak
        let analyticsService = AnalyticsService(context: modelContext)
        let streak = analyticsService.getOverviewStats(for: recentWorkouts).streak
        
        // Fetch recent PRs (Last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let prDescriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.date >= thirtyDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let recentPRs = (try? modelContext.fetch(prDescriptor)) ?? []
        
        let recentPRContexts = recentPRs.map { pr -> AIRecentPRContext in
            let daysAgo = calendar.dateComponents([.day], from: pr.date, to: Date()).day ?? 0
            return AIRecentPRContext(
                exerciseName: pr.exercise?.name ?? "Unknown",
                recordType: pr.recordType,
                value: pr.value,
                daysAgo: daysAgo
            )
        }
        
        return AIFitnessContext(
            userExperienceLevel: experience,
            trainingStreakDays: streak,
            totalVolumePastWeek: totalVolumeWeek,
            recentWorkouts: recentWorkoutContexts,
            recentPRs: recentPRContexts
        )
    }
}
