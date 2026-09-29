import Foundation

// MARK: - API Contract Models
// These models represent the strict data structures exchanged with the secure backend.
// The iOS app does not talk to Gemini directly.

public struct AIChatRequest: Codable {
    public let message: String
    public let context: AIFitnessContext
    
    public init(message: String, context: AIFitnessContext) {
        self.message = message
        self.context = context
    }
}

public struct AIChatResponse: Codable {
    public let reply: String
    public let suggestedActions: [String]?
    
    public init(reply: String, suggestedActions: [String]? = nil) {
        self.reply = reply
        self.suggestedActions = suggestedActions
    }
}

public struct AIInsightRequest: Codable {
    public let context: AIFitnessContext
    
    public init(context: AIFitnessContext) {
        self.context = context
    }
}

public struct AIInsightResponse: Codable {
    public let insightText: String
    public let confidenceScore: Double
    
    public init(insightText: String, confidenceScore: Double) {
        self.insightText = insightText
        self.confidenceScore = confidenceScore
    }
}

// MARK: - Context Models
// Sent to the backend to ground the AI generation. PII and raw HealthKit data are excluded.

public struct AIFitnessContext: Codable {
    public let userExperienceLevel: String
    public let trainingStreakDays: Int
    public let totalVolumePastWeek: Double
    public let recentWorkouts: [AIRecentWorkoutContext]
    public let recentPRs: [AIRecentPRContext]
    
    public init(userExperienceLevel: String, trainingStreakDays: Int, totalVolumePastWeek: Double, recentWorkouts: [AIRecentWorkoutContext], recentPRs: [AIRecentPRContext]) {
        self.userExperienceLevel = userExperienceLevel
        self.trainingStreakDays = trainingStreakDays
        self.totalVolumePastWeek = totalVolumePastWeek
        self.recentWorkouts = recentWorkouts
        self.recentPRs = recentPRs
    }
}

public struct AIRecentWorkoutContext: Codable {
    public let name: String
    public let durationMinutes: Int
    public let totalVolume: Double
    public let primaryMuscleGroups: [String]
    public let daysAgo: Int
    
    public init(name: String, durationMinutes: Int, totalVolume: Double, primaryMuscleGroups: [String], daysAgo: Int) {
        self.name = name
        self.durationMinutes = durationMinutes
        self.totalVolume = totalVolume
        self.primaryMuscleGroups = primaryMuscleGroups
        self.daysAgo = daysAgo
    }
}

public struct AIRecentPRContext: Codable {
    public let exerciseName: String
    public let recordType: String
    public let value: Double
    public let daysAgo: Int
    
    public init(exerciseName: String, recordType: String, value: Double, daysAgo: Int) {
        self.exerciseName = exerciseName
        self.recordType = recordType
        self.value = value
        self.daysAgo = daysAgo
    }
}

// MARK: - Workout Generation Models

public struct AIWorkoutGenerationRequest: Codable {
    public let goal: String
    public let experienceLevel: String
    public let workoutDurationMinutes: Int
    public let availableEquipment: [String]
    public let targetMuscleGroups: [String]
    public let notes: String?
    public let availableExercises: [ExerciseReference]
    
    public init(goal: String, experienceLevel: String, workoutDurationMinutes: Int, availableEquipment: [String], targetMuscleGroups: [String], notes: String?, availableExercises: [ExerciseReference]) {
        self.goal = goal
        self.experienceLevel = experienceLevel
        self.workoutDurationMinutes = workoutDurationMinutes
        self.availableEquipment = availableEquipment
        self.targetMuscleGroups = targetMuscleGroups
        self.notes = notes
        self.availableExercises = availableExercises
    }
}

public struct ExerciseReference: Codable {
    public let id: String
    public let name: String
    public let primaryMuscleGroup: String
    public let equipment: String
    
    public init(id: String, name: String, primaryMuscleGroup: String, equipment: String) {
        self.id = id
        self.name = name
        self.primaryMuscleGroup = primaryMuscleGroup
        self.equipment = equipment
    }
}

public struct AIGeneratedWorkout: Codable, Identifiable {
    public var id: UUID = UUID()
    public var name: String
    public var description: String
    public var estimatedDurationMinutes: Int
    public var exercises: [AIGeneratedExercise]
    
    public init(name: String, description: String, estimatedDurationMinutes: Int, exercises: [AIGeneratedExercise]) {
        self.name = name
        self.description = description
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.exercises = exercises
    }
}

public struct AIGeneratedExercise: Codable, Identifiable {
    public var id: UUID = UUID()
    public var exerciseID: String
    public var order: Int
    public var targetSets: Int
    public var repRangeMin: Int
    public var repRangeMax: Int
    public var restSeconds: Int
    public var notes: String?
    public var supersetGroupID: String?
    
    public init(exerciseID: String, order: Int, targetSets: Int, repRangeMin: Int, repRangeMax: Int, restSeconds: Int, notes: String? = nil, supersetGroupID: String? = nil) {
        self.exerciseID = exerciseID
        self.order = order
        self.targetSets = targetSets
        self.repRangeMin = repRangeMin
        self.repRangeMax = repRangeMax
        self.restSeconds = restSeconds
        self.notes = notes
        self.supersetGroupID = supersetGroupID
    }
}

// MARK: - Progression Analysis Models

public struct AIProgressionSession: Codable {
    public let date: Date
    public let weight: Double
    public let reps: Int
    public let sets: Int
    public let volume: Double
    public let estimated1RM: Double
    
    public init(date: Date, weight: Double, reps: Int, sets: Int, volume: Double, estimated1RM: Double) {
        self.date = date
        self.weight = weight
        self.reps = reps
        self.sets = sets
        self.volume = volume
        self.estimated1RM = estimated1RM
    }
}

public struct AIProgressionContext: Codable {
    public let exerciseID: String
    public let exerciseName: String
    public let primaryMuscleGroup: String
    public let recentSessions: [AIProgressionSession]
    public let progressionStatus: String // e.g. "progressing", "stable", "stalled", "regressing", "insufficientData"
    public let personalRecord: Double?
    public let daysSinceLastPerformed: Int?
    
    public init(exerciseID: String, exerciseName: String, primaryMuscleGroup: String, recentSessions: [AIProgressionSession], progressionStatus: String, personalRecord: Double?, daysSinceLastPerformed: Int?) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.primaryMuscleGroup = primaryMuscleGroup
        self.recentSessions = recentSessions
        self.progressionStatus = progressionStatus
        self.personalRecord = personalRecord
        self.daysSinceLastPerformed = daysSinceLastPerformed
    }
}

public struct AIProgressionRecommendation: Codable {
    public let exerciseID: String
    public let recommendationType: String // "increaseWeight", "increaseReps", "maintain", "reduceWeight", "addSet", "insufficientData"
    public let recommendedWeight: Double
    public let recommendedRepMin: Int
    public let recommendedRepMax: Int
    public let recommendedSets: Int
    public let confidence: String // "low", "medium", "high"
    public let reasoning: String
    public let caution: String?
    
    public init(exerciseID: String, recommendationType: String, recommendedWeight: Double, recommendedRepMin: Int, recommendedRepMax: Int, recommendedSets: Int, confidence: String, reasoning: String, caution: String? = nil) {
        self.exerciseID = exerciseID
        self.recommendationType = recommendationType
        self.recommendedWeight = recommendedWeight
        self.recommendedRepMin = recommendedRepMin
        self.recommendedRepMax = recommendedRepMax
        self.recommendedSets = recommendedSets
        self.confidence = confidence
        self.reasoning = reasoning
        self.caution = caution
    }
}

// MARK: - Post-Workout Analysis Models

public struct AIWorkoutAnalysisContext: Codable {
    public let workoutID: String
    public let workoutName: String
    public let durationSeconds: Int
    public let totalVolume: Double
    public let totalSets: Int
    public let completedSets: Int
    public let exerciseCount: Int
    public let muscleGroups: [String]
    public let prCount: Int
    
    // Condensed exercise stats
    public let exercises: [AIAnalysisExerciseContext]
    
    // Comparison to a previous similar workout, if any
    public let comparison: AIWorkoutComparisonContext?
    
    public init(workoutID: String, workoutName: String, durationSeconds: Int, totalVolume: Double, totalSets: Int, completedSets: Int, exerciseCount: Int, muscleGroups: [String], prCount: Int, exercises: [AIAnalysisExerciseContext], comparison: AIWorkoutComparisonContext?) {
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.durationSeconds = durationSeconds
        self.totalVolume = totalVolume
        self.totalSets = totalSets
        self.completedSets = completedSets
        self.exerciseCount = exerciseCount
        self.muscleGroups = muscleGroups
        self.prCount = prCount
        self.exercises = exercises
        self.comparison = comparison
    }
}

public struct AIAnalysisExerciseContext: Codable {
    public let exerciseID: String
    public let name: String
    public let setsCompleted: Int
    public let maxWeight: Double
    public let totalVolume: Double
    
    public init(exerciseID: String, name: String, setsCompleted: Int, maxWeight: Double, totalVolume: Double) {
        self.exerciseID = exerciseID
        self.name = name
        self.setsCompleted = setsCompleted
        self.maxWeight = maxWeight
        self.totalVolume = totalVolume
    }
}

public struct AIWorkoutComparisonContext: Codable {
    public let previousWorkoutDate: Date
    public let volumeChangePercent: Double
    public let durationChangeSeconds: Int
    
    public init(previousWorkoutDate: Date, volumeChangePercent: Double, durationChangeSeconds: Int) {
        self.previousWorkoutDate = previousWorkoutDate
        self.volumeChangePercent = volumeChangePercent
        self.durationChangeSeconds = durationChangeSeconds
    }
}

public struct AIWorkoutAnalysis: Codable, Equatable {
    public let headline: String
    public let summary: String
    public let highlights: [AIWorkoutHighlight]
    public let observations: [String]
    public let recommendations: [String]
    
    public init(headline: String, summary: String, highlights: [AIWorkoutHighlight], observations: [String], recommendations: [String]) {
        self.headline = headline
        self.summary = summary
        self.highlights = highlights
        self.observations = observations
        self.recommendations = recommendations
    }
}

public struct AIWorkoutHighlight: Codable, Equatable, Identifiable {
    public var id: String { title }
    public let type: String // "personalRecord", "volumeIncrease", "consistency", "strengthIncrease", "notableSet"
    public let title: String
    public let description: String
    
    public init(type: String, title: String, description: String) {
        self.type = type
        self.title = title
        self.description = description
    }
}

// MARK: - Natural Language Logging Models

public struct AINaturalLanguageWorkoutRequest: Codable {
    public let text: String
    public let workoutID: String
    public let currentExerciseID: String?
    public let availableExerciseReferences: [ExerciseReference]
    
    public init(text: String, workoutID: String, currentExerciseID: String?, availableExerciseReferences: [ExerciseReference]) {
        self.text = text
        self.workoutID = workoutID
        self.currentExerciseID = currentExerciseID
        self.availableExerciseReferences = availableExerciseReferences
    }
}

public enum AICommandStatus: String, Codable {
    case valid
    case needsClarification
    case invalid
}

public struct AIWorkoutCommand: Codable, Identifiable {
    public let id: String
    public let status: AICommandStatus
    public let commandType: String // "logSet", "logMultipleSets", "startRest", "substituteExercise", "unknown"
    public let clarificationMessage: String?
    
    public let logSetCommand: AILogSetCommand?
    public let logMultipleSetsCommand: AILogMultipleSetsCommand?
    public let restDurationSeconds: Int?
    public let substituteExerciseID: String?
    
    public init(id: String = UUID().uuidString, status: AICommandStatus, commandType: String, clarificationMessage: String? = nil, logSetCommand: AILogSetCommand? = nil, logMultipleSetsCommand: AILogMultipleSetsCommand? = nil, restDurationSeconds: Int? = nil, substituteExerciseID: String? = nil) {
        self.id = id
        self.status = status
        self.commandType = commandType
        self.clarificationMessage = clarificationMessage
        self.logSetCommand = logSetCommand
        self.logMultipleSetsCommand = logMultipleSetsCommand
        self.restDurationSeconds = restDurationSeconds
        self.substituteExerciseID = substituteExerciseID
    }
}

public struct AILogSetCommand: Codable {
    public let exerciseID: String
    public let weight: Double
    public let reps: Int
    public let setType: String // "working", "warmup", "drop", "failure"
    
    public init(exerciseID: String, weight: Double, reps: Int, setType: String) {
        self.exerciseID = exerciseID
        self.weight = weight
        self.reps = reps
        self.setType = setType
    }
}

public struct AILogMultipleSetsCommand: Codable {
    public let exerciseID: String
    public let sets: [AILogSetCommand]
    
    public init(exerciseID: String, sets: [AILogSetCommand]) {
        self.exerciseID = exerciseID
        self.sets = sets
    }
}

// MARK: - Exercise Substitution Models

public struct AIExerciseSubstitutionRequest: Codable {
    public let exerciseID: String
    public let exerciseName: String
    public let primaryMuscleGroup: String
    public let equipment: String
    public let reason: String?
    public let availableExercises: [ExerciseReference]
    
    public init(exerciseID: String, exerciseName: String, primaryMuscleGroup: String, equipment: String, reason: String? = nil, availableExercises: [ExerciseReference]) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.primaryMuscleGroup = primaryMuscleGroup
        self.equipment = equipment
        self.reason = reason
        self.availableExercises = availableExercises
    }
}

public struct AIExerciseSubstitutionResponse: Codable {
    public let originalExerciseID: String
    public let suggestions: [AISubstitutionSuggestion]
    
    public init(originalExerciseID: String, suggestions: [AISubstitutionSuggestion]) {
        self.originalExerciseID = originalExerciseID
        self.suggestions = suggestions
    }
}

public struct AISubstitutionSuggestion: Codable, Identifiable {
    public let exerciseID: String
    public let reason: String
    public let similarityScore: Double
    
    public var id: String { exerciseID }
    
    public init(exerciseID: String, reason: String, similarityScore: Double) {
        self.exerciseID = exerciseID
        self.reason = reason
        self.similarityScore = similarityScore
    }
}



