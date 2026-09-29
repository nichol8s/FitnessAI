import Foundation

public final class AIWorkoutAnalysisValidator {
    
    public init() {}
    
    public func validate(analysis: AIWorkoutAnalysis, context: AIWorkoutAnalysisContext) -> AIValidationResult {
        // 1. Core existence checks
        guard !analysis.headline.isEmpty else { return .invalid(reason: "Empty headline.") }
        guard !analysis.summary.isEmpty else { return .invalid(reason: "Empty summary.") }
        
        // 2. Bound constraints
        if analysis.summary.count > 500 {
            return .invalid(reason: "Summary exceeds reasonable length.")
        }
        
        // 3. Highlight Validation
        let validTypes = ["personalRecord", "volumeIncrease", "consistency", "strengthIncrease", "notableSet", "volumeDecrease", "strengthDecrease"]
        for highlight in analysis.highlights {
            guard validTypes.contains(highlight.type) else {
                return .invalid(reason: "Invalid highlight type generated: \(highlight.type)")
            }
        }
        
        // 4. Deterministic Fact Consistency
        // The AI shouldn't hallucinate PRs if there were none.
        if context.prCount == 0 {
            if analysis.highlights.contains(where: { $0.type == "personalRecord" }) {
                return .invalid(reason: "AI generated a PR highlight when no PRs were achieved.")
            }
        }
        
        return .valid
    }
}
