import Foundation

public struct SyncWorkoutMessage: Codable {
    public let workoutID: String
    public let workoutName: String
    public let startTime: Date
    public let isPaused: Bool
    
    // Flattened exercise data for the watch
    public let exercises: [SyncExerciseMessage]
    
    // Timer state
    public let restEndDate: Date?
    
    public init(workoutID: String, workoutName: String, startTime: Date, isPaused: Bool, exercises: [SyncExerciseMessage], restEndDate: Date?) {
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.startTime = startTime
        self.isPaused = isPaused
        self.exercises = exercises
        self.restEndDate = restEndDate
    }
}

public struct SyncExerciseMessage: Codable {
    public let exerciseID: String
    public let name: String
    public let order: Int
    public let supersetID: String?
    public var sets: [SyncSetMessage]
    
    public init(exerciseID: String, name: String, order: Int, supersetID: String?, sets: [SyncSetMessage]) {
        self.exerciseID = exerciseID
        self.name = name
        self.order = order
        self.supersetID = supersetID
        self.sets = sets
    }
}

public struct SyncSetMessage: Codable {
    public let setID: String
    public let setOrder: Int
    public let weight: Double
    public let reps: Int
    public let isCompleted: Bool
    public let setType: String
    
    public init(setID: String, setOrder: Int, weight: Double, reps: Int, isCompleted: Bool, setType: String) {
        self.setID = setID
        self.setOrder = setOrder
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
        self.setType = setType
    }
}

public struct SyncSetCompletionEvent: Codable {
    public let setID: String
    public let exerciseID: String
    public let workoutID: String
    public let weight: Double
    public let reps: Int
    public let timestamp: Date
    public let restDuration: Int?
    
    public init(setID: String, exerciseID: String, workoutID: String, weight: Double, reps: Int, timestamp: Date, restDuration: Int?) {
        self.setID = setID
        self.exerciseID = exerciseID
        self.workoutID = workoutID
        self.weight = weight
        self.reps = reps
        self.timestamp = timestamp
        self.restDuration = restDuration
    }
}
