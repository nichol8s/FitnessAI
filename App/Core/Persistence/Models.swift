import Foundation
import SwiftData

@Model
public final class User {
    public var id: UUID = UUID()
    public var name: String
    public var profilePictureURL: URL?
    public var height: Double? // cm
    public var weight: Double? // kg
    public var preferredUnits: String // "kg" or "lb"
    public var trainingExperience: String // "beginner", "intermediate", "advanced"
    
    @Relationship(deleteRule: .cascade) public var goals: [UserGoal] = []
    @Relationship(deleteRule: .cascade) public var bodyMeasurements: [BodyMeasurement] = []
    
    public init(name: String, preferredUnits: String = "kg", trainingExperience: String = "intermediate") {
        self.name = name
        self.preferredUnits = preferredUnits
        self.trainingExperience = trainingExperience
    }
}

@Model
public final class UserGoal {
    public var id: UUID = UUID()
    public var title: String
    public var goalType: String // e.g., "muscle_gain", "strength"
    public var targetDate: Date?
    public var isCompleted: Bool = false
    
    public var user: User?
    
    public init(title: String, goalType: String) {
        self.title = title
        self.goalType = goalType
    }
}

@Model
public final class Exercise {
    public var id: UUID = UUID()
    public var name: String
    public var primaryMuscle: String
    public var secondaryMuscles: [String] = []
    public var equipment: String
    public var movementType: String
    public var instructions: String?
    public var defaultRestTime: Int // seconds
    public var isCustom: Bool = false
    public var isFavorite: Bool = false
    
    public init(name: String, primaryMuscle: String, equipment: String, movementType: String, defaultRestTime: Int = 90, isCustom: Bool = false) {
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.equipment = equipment
        self.movementType = movementType
        self.defaultRestTime = defaultRestTime
        self.isCustom = isCustom
    }
}

@Model
public final class Routine {
    public var id: UUID = UUID()
    public var name: String
    public var userNotes: String?
    public var icon: String?
    public var color: String?
    public var isFavorite: Bool = false
    
    @Relationship(deleteRule: .cascade) public var routineExercises: [RoutineExercise] = []
    
    public init(name: String, icon: String? = nil, color: String? = nil) {
        self.name = name
        self.icon = icon
        self.color = color
    }
}

@Model
public final class RoutineExercise {
    public var id: UUID = UUID()
    public var order: Int
    public var targetSets: Int
    public var targetRepRange: String // e.g., "8-12"
    public var targetWeight: Double?
    public var restSeconds: Int
    public var notes: String?
    public var supersetID: UUID?
    
    public var exercise: Exercise?
    public var routine: Routine?
    
    public init(order: Int, targetSets: Int, targetRepRange: String, targetWeight: Double? = nil, restSeconds: Int, supersetID: UUID? = nil) {
        self.order = order
        self.targetSets = targetSets
        self.targetRepRange = targetRepRange
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.supersetID = supersetID
    }
}

@Model
public final class Workout {
    public var id: UUID = UUID()
    public var name: String
    public var startTime: Date
    public var endTime: Date?
    public var duration: TimeInterval?
    public var totalVolume: Double = 0
    public var totalSets: Int = 0
    public var completedSets: Int = 0
    public var isCompleted: Bool = false
    public var notes: String?
    
    // HealthKit Sync
    public var hkWorkoutID: String?
    public var hkSyncStatus: String = "notSynced" // "notSynced", "pending", "synced", "failed"
    
    public var routine: Routine?
    
    @Relationship(deleteRule: .cascade) public var workoutExercises: [WorkoutExercise] = []
    
    public init(name: String, startTime: Date = Date()) {
        self.name = name
        self.startTime = startTime
    }
}

@Model
public final class WorkoutExercise {
    public var id: UUID = UUID()
    public var order: Int
    public var supersetID: UUID?
    public var notes: String?
    
    public var exercise: Exercise?
    public var workout: Workout?
    
    @Relationship(deleteRule: .cascade) public var sets: [WorkoutSet] = []
    
    public init(order: Int) {
        self.order = order
    }
}

@Model
public final class WorkoutSet {
    public var id: UUID = UUID()
    public var setOrder: Int
    public var weight: Double
    public var reps: Int
    public var setType: String // "warmup", "working", "drop", "failure", "amrap"
    public var isCompleted: Bool = false
    public var restDuration: Int?
    public var timestamp: Date?
    public var notes: String?
    
    public var workoutExercise: WorkoutExercise?
    
    public init(setOrder: Int, weight: Double, reps: Int, setType: String = "working") {
        self.setOrder = setOrder
        self.weight = weight
        self.reps = reps
        self.setType = setType
    }
}

@Model
public final class PersonalRecord {
    public var id: UUID = UUID()
    public var recordType: String // "volume", "weight", "1rm"
    public var value: Double
    public var date: Date
    
    public var exercise: Exercise?
    
    public init(recordType: String, value: Double, date: Date = Date()) {
        self.recordType = recordType
        self.value = value
        self.date = date
    }
}

@Model
public final class BodyMeasurement {
    public var id: UUID = UUID()
    public var date: Date
    public var type: String // "weight", "chest", "arms", etc.
    public var value: Double
    public var unit: String
    
    // HealthKit
    public var hkMeasurementID: String?
    
    public var user: User?
    
    public init(date: Date, type: String, value: Double, unit: String) {
        self.date = date
        self.type = type
        self.value = value
        self.unit = unit
    }
}

@Model
public final class AIConversation {
    public var id: UUID = UUID()
    public var startDate: Date
    public var title: String
    
    @Relationship(deleteRule: .cascade) public var messages: [AIMessage] = []
    
    public init(startDate: Date = Date(), title: String) {
        self.startDate = startDate
        self.title = title
    }
}

@Model
public final class AIMessage {
    public var id: UUID = UUID()
    public var content: String
    public var role: String // "user" or "assistant"
    public var timestamp: Date
    
    public var conversation: AIConversation?
    
    public init(content: String, role: String, timestamp: Date = Date()) {
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}
