import Foundation

public final class AIProgressionValidator {
    
    public init() {}
    
    public func validate(recommendation: AIProgressionRecommendation, context: AIProgressionContext) -> AIValidationResult {
        // 1. Structural checks
        guard recommendation.recommendedWeight >= 0 else {
            return .invalid(reason: "Recommended weight cannot be negative.")
        }
        guard recommendation.recommendedRepMin > 0, recommendation.recommendedRepMax >= recommendation.recommendedRepMin else {
            return .invalid(reason: "Recommended rep range is invalid.")
        }
        guard recommendation.recommendedSets > 0 && recommendation.recommendedSets <= 10 else {
            return .invalid(reason: "Recommended sets are unreasonable.")
        }
        
        let validTypes = ["increaseWeight", "increaseReps", "maintain", "reduceWeight", "addSet", "insufficientData"]
        guard validTypes.contains(recommendation.recommendationType) else {
            return .invalid(reason: "Unknown recommendation type.")
        }
        
        // 2. Relative safety bounds
        if let lastSession = context.recentSessions.first {
            // Do not allow the AI to prescribe more than a 20% jump or an absolute jump > 20kg in a single session
            let diff = recommendation.recommendedWeight - lastSession.weight
            
            if diff > 20.0 {
                return .invalid(reason: "Absolute weight jump is too high (> 20kg).")
            }
            
            if lastSession.weight > 0 {
                let percentIncrease = diff / lastSession.weight
                if percentIncrease > 0.25 { // > 25% jump
                    return .invalid(reason: "Relative weight jump is suspiciously high (> 25%).")
                }
            }
        }
        
        return .valid
    }
}
