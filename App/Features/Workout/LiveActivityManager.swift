import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

public final class LiveActivityManager {
    public static let shared = LiveActivityManager()
    
    private init() {}
    
    public func startRestTimerActivity(workoutName: String, nextExercise: String, endDate: Date) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // End any existing activities first
        endAllActivities()
        
        let attributes = FitnessLiveActivityAttributes(workoutName: workoutName)
        let contentState = FitnessLiveActivityAttributes.ContentState(restEndDate: endDate, nextExerciseName: nextExercise)
        
        do {
            let activity = try Activity<FitnessLiveActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
        #endif
    }
    
    public func updateRestTimerActivity(nextExercise: String, endDate: Date, isPaused: Bool = false) {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<FitnessLiveActivityAttributes>.activities {
                let updatedState = FitnessLiveActivityAttributes.ContentState(restEndDate: endDate, nextExerciseName: nextExercise, isPaused: isPaused)
                let content = ActivityContent(state: updatedState, staleDate: nil)
                await activity.update(content)
            }
        }
        #endif
    }
    
    public func endAllActivities() {
        #if canImport(ActivityKit)
        Task {
            for activity in Activity<FitnessLiveActivityAttributes>.activities {
                let finalState = activity.content.state // Or a distinct completion state if needed
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
