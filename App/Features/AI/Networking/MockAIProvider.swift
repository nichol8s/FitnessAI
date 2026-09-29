import Foundation

public final class MockAIProvider: AIProvider {
    public static let shared = MockAIProvider()
    
    public var shouldSimulateError = false
    
    private init() {}
    
    public func sendChat(request: AIChatRequest) async throws -> AIChatResponse {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        if shouldSimulateError {
            throw AIError.serverError
        }
        
        // Deterministic mock responses based on context length or request
        let reply: String
        if request.message.lowercased().contains("squat") {
            reply = "To increase your squat, focus on progressive overload and ensure your depth is consistent. Your recent volume shows you've been consistent. Try adding a pause at the bottom of your reps next session."
        } else {
            reply = "You're doing great! Your training streak is currently \(request.context.trainingStreakDays) days. Keep up the momentum!"
        }
        
        return AIChatResponse(
            reply: reply,
            suggestedActions: ["Analyze today's workout", "Plan next workout"]
        )
    }
    
    public func getInsight(request: AIInsightRequest) async throws -> AIInsightResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldSimulateError {
            throw AIError.serverError
        }
        
        let insight = "Your pulling volume increased 12% this week. Consider keeping today's back work at the current load and adding 1–2 reps before increasing weight."
        return AIInsightResponse(insightText: insight, confidenceScore: 0.88)
    }
    
    public func generateWorkout(request: AIWorkoutGenerationRequest) async throws -> AIGeneratedWorkout {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        if shouldSimulateError { throw AIError.serverError }
        
        // Grab real UUIDs from the request to ensure validity
        var exercisesToUse: [AIGeneratedExercise] = []
        let maxEx = min(5, request.availableExercises.count)
        
        for i in 0..<maxEx {
            let ref = request.availableExercises[i]
            let ex = AIGeneratedExercise(
                exerciseID: ref.id,
                order: i,
                targetSets: 3,
                repRangeMin: 8,
                repRangeMax: 12,
                restSeconds: 90,
                notes: "Focus on form and slow eccentric."
            )
            exercisesToUse.append(ex)
        }
        
        return AIGeneratedWorkout(
            name: "AI \(request.goal) Workout",
            description: "A tailored workout focusing on \(request.targetMuscleGroups.joined(separator: ", ")).",
            estimatedDurationMinutes: request.workoutDurationMinutes,
            exercises: exercisesToUse
        )
    }
    
    public func recommendProgression(context: AIProgressionContext) async throws -> AIProgressionRecommendation {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if shouldSimulateError { throw AIError.serverError }
        
        guard let lastSession = context.recentSessions.first else {
            return AIProgressionRecommendation(
                exerciseID: context.exerciseID,
                recommendationType: "insufficientData",
                recommendedWeight: 0,
                recommendedRepMin: 8,
                recommendedRepMax: 12,
                recommendedSets: 3,
                confidence: "low",
                reasoning: "Not enough history to suggest progression."
            )
        }
        
        // Mock a conservative jump
        return AIProgressionRecommendation(
            exerciseID: context.exerciseID,
            recommendationType: "increaseWeight",
            recommendedWeight: lastSession.weight + 2.5,
            recommendedRepMin: lastSession.reps,
            recommendedRepMax: lastSession.reps + 2,
            recommendedSets: lastSession.sets,
            confidence: "medium",
            reasoning: "You've been consistent at \(lastSession.weight)kg. It's time for a small jump.",
            caution: "If it feels too heavy, drop back and focus on reps."
        )
    }
    
    public func analyzeWorkout(context: AIWorkoutAnalysisContext) async throws -> AIWorkoutAnalysis {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        if shouldSimulateError { throw AIError.serverError }
        
        var highlights: [AIWorkoutHighlight] = []
        
        if context.prCount > 0 {
            highlights.append(AIWorkoutHighlight(
                type: "personalRecord",
                title: "\(context.prCount) New PRs",
                description: "You broke through previous plateaus today."
            ))
        }
        
        if let comp = context.comparison {
            if comp.volumeChangePercent > 0.05 {
                highlights.append(AIWorkoutHighlight(
                    type: "volumeIncrease",
                    title: "Volume Up \(Int(comp.volumeChangePercent * 100))%",
                    description: "You moved more total weight than your last similar session."
                ))
            }
        } else {
            highlights.append(AIWorkoutHighlight(
                type: "consistency",
                title: "Solid Execution",
                description: "Good adherence to the routine."
            ))
        }
        
        return AIWorkoutAnalysis(
            headline: "Strong Performance",
            summary: "You completed \(context.completedSets) sets across \(context.exerciseCount) exercises focusing on \(context.muscleGroups.joined(separator: ", ")). Overall volume was \(Int(context.totalVolume))kg.",
            highlights: highlights,
            observations: [
                "Your pressing movements were particularly strong today.",
                "You maintained good rest periods throughout the session."
            ],
            recommendations: [
                "Focus on recovery and hydration.",
                "Consider increasing load on secondary exercises next time."
            ]
        )
    }
    
    public func parseWorkoutCommand(request: AINaturalLanguageWorkoutRequest) async throws -> AIWorkoutCommand {
        try await Task.sleep(nanoseconds: 800_000_000)
        if shouldSimulateError { throw AIError.serverError }
        
        let text = request.text.lowercased()
        
        guard let currentExId = request.currentExerciseID else {
            return AIWorkoutCommand(status: .invalid, commandType: "unknown", clarificationMessage: "I need to know which exercise you are currently doing.")
        }
        
        if text.contains("rest") {
            return AIWorkoutCommand(status: .valid, commandType: "startRest", restDurationSeconds: 90)
        }
        
        if text.contains("bench") && !text.contains("kg") {
            return AIWorkoutCommand(status: .needsClarification, commandType: "unknown", clarificationMessage: "What weight did you use?")
        }
        
        // Mock a successful parse (e.g. "Bench 60kg x 10")
        let setCmd = AILogSetCommand(exerciseID: currentExId, weight: 60.0, reps: 10, setType: "working")
        return AIWorkoutCommand(status: .valid, commandType: "logSet", logSetCommand: setCmd)
    }
    
    public func suggestExerciseSubstitutions(request: AIExerciseSubstitutionRequest) async throws -> AIExerciseSubstitutionResponse {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        if shouldSimulateError { throw AIError.serverError }
        
        var suggestions: [AISubstitutionSuggestion] = []
        
        // Return up to 3 exercises that match the primary muscle group and aren't the original ID
        for ref in request.availableExercises where ref.primaryMuscleGroup == request.primaryMuscleGroup && ref.id != request.exerciseID {
            suggestions.append(AISubstitutionSuggestion(
                exerciseID: ref.id,
                reason: "Targets the \(request.primaryMuscleGroup) similarly.",
                similarityScore: 0.85
            ))
            if suggestions.count >= 3 { break }
        }
        
        return AIExerciseSubstitutionResponse(
            originalExerciseID: request.exerciseID,
            suggestions: suggestions
        )
    }
}
