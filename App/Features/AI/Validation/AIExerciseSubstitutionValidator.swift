import Foundation
import SwiftData

public final class AIExerciseSubstitutionValidator {
    
    public init() {}
    
    public func validate(response: AIExerciseSubstitutionResponse, validExerciseIDs: Set<String>) -> AIValidationResult {
        guard validExerciseIDs.contains(response.originalExerciseID) else {
            return .invalid(reason: "Original exercise ID is unknown.")
        }
        
        guard !response.suggestions.isEmpty else {
            // It's technically valid to have no suggestions, but we might want to flag it for the UI.
            return .valid
        }
        
        for suggestion in response.suggestions {
            guard validExerciseIDs.contains(suggestion.exerciseID) else {
                return .invalid(reason: "AI suggested an unknown exercise ID: \(suggestion.exerciseID)")
            }
            
            guard suggestion.exerciseID != response.originalExerciseID else {
                return .invalid(reason: "AI suggested substituting the exercise with itself.")
            }
        }
        
        return .valid
    }
}
