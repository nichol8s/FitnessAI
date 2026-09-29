import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

public struct FitnessLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var restEndDate: Date
        public var nextExerciseName: String
        public var isPaused: Bool
        
        public init(restEndDate: Date, nextExerciseName: String, isPaused: Bool = false) {
            self.restEndDate = restEndDate
            self.nextExerciseName = nextExerciseName
            self.isPaused = isPaused
        }
    }
    
    public var workoutName: String
    
    public init(workoutName: String) {
        self.workoutName = workoutName
    }
}
