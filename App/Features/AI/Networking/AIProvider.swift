import Foundation

public protocol AIProvider {
    func sendChat(request: AIChatRequest) async throws -> AIChatResponse
    func getInsight(request: AIInsightRequest) async throws -> AIInsightResponse
    func generateWorkout(request: AIWorkoutGenerationRequest) async throws -> AIGeneratedWorkout
    func recommendProgression(context: AIProgressionContext) async throws -> AIProgressionRecommendation
    func analyzeWorkout(context: AIWorkoutAnalysisContext) async throws -> AIWorkoutAnalysis
    func parseWorkoutCommand(request: AINaturalLanguageWorkoutRequest) async throws -> AIWorkoutCommand
    func suggestExerciseSubstitutions(request: AIExerciseSubstitutionRequest) async throws -> AIExerciseSubstitutionResponse
}

// In production, this would point to your secure backend API,
// which holds the Google Gemini API Key and executes the heavy lifting.
public final class AIAPIClient: AIProvider {
    public static let shared = AIAPIClient()
    
    private init() {}
    
    public func sendChat(request: AIChatRequest) async throws -> AIChatResponse {
        // Dummy implementation simulating a network request to the secure backend.
        // Replace with URLSession logic pointing to e.g., https://api.yourbackend.com/v1/ai/chat
        try await Task.sleep(nanoseconds: 1_500_000_000)
        throw AIError.networkUnavailable
    }
    
    public func getInsight(request: AIInsightRequest) async throws -> AIInsightResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw AIError.networkUnavailable
    }
    
    public func generateWorkout(request: AIWorkoutGenerationRequest) async throws -> AIGeneratedWorkout {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        throw AIError.networkUnavailable
    }
    
    public func recommendProgression(context: AIProgressionContext) async throws -> AIProgressionRecommendation {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw AIError.networkUnavailable
    }
    
    public func analyzeWorkout(context: AIWorkoutAnalysisContext) async throws -> AIWorkoutAnalysis {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        throw AIError.networkUnavailable
    }
    
    public func parseWorkoutCommand(request: AINaturalLanguageWorkoutRequest) async throws -> AIWorkoutCommand {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw AIError.networkUnavailable
    }
    
    public func suggestExerciseSubstitutions(request: AIExerciseSubstitutionRequest) async throws -> AIExerciseSubstitutionResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw AIError.networkUnavailable
    }
}

public enum AIProviderFactory {
    public static var shared: AIProvider {
        #if DEBUG
        return AIProviderFactory.shared
        #else
        return AIAPIClient.shared
        #endif
    }
}
