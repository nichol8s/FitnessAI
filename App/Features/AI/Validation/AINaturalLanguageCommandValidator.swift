import Foundation
import SwiftData

public final class AINaturalLanguageCommandValidator {
    
    public init() {}
    
    public func validate(command: AIWorkoutCommand, activeWorkout: Workout) -> AIValidationResult {
        // If it's a clarification request, it's inherently "valid" as a UI state, but not an executable action
        guard command.status == .valid else {
            return .valid
        }
        
        // Ensure that the workout has the requested exercise
        let activeExIDs = Set(activeWorkout.workoutExercises.compactMap { $0.exercise?.id.uuidString })
        
        switch command.commandType {
        case "logSet":
            guard let setCmd = command.logSetCommand else {
                return .invalid(reason: "Missing logSetCommand payload.")
            }
            if let error = validateSet(setCmd, validIDs: activeExIDs) { return error }
            
        case "logMultipleSets":
            guard let multiCmd = command.logMultipleSetsCommand else {
                return .invalid(reason: "Missing logMultipleSetsCommand payload.")
            }
            guard !multiCmd.sets.isEmpty else { return .invalid(reason: "No sets provided.") }
            guard multiCmd.sets.count <= 20 else { return .invalid(reason: "Too many sets (max 20).") }
            for setCmd in multiCmd.sets {
                if let error = validateSet(setCmd, validIDs: activeExIDs) { return error }
            }
            
        case "startRest":
            guard let duration = command.restDurationSeconds else {
                return .invalid(reason: "Missing rest duration.")
            }
            guard duration >= 10 && duration <= 600 else {
                return .invalid(reason: "Rest duration must be between 10s and 10m.")
            }
            
        case "substituteExercise":
            guard let subID = command.substituteExerciseID else {
                return .invalid(reason: "Missing substitution ID.")
            }
            guard activeExIDs.contains(subID) else {
                return .invalid(reason: "Substitution target is not in the active workout.")
            }
            
        default:
            return .invalid(reason: "Unknown command type: \(command.commandType)")
        }
        
        return .valid
    }
    
    private func validateSet(_ cmd: AILogSetCommand, validIDs: Set<String>) -> AIValidationResult? {
        guard validIDs.contains(cmd.exerciseID) else {
            return .invalid(reason: "Exercise ID is not in the active workout.")
        }
        guard cmd.weight >= 0 && cmd.weight < 1000 else {
            return .invalid(reason: "Weight must be between 0 and 1000.")
        }
        guard cmd.reps > 0 && cmd.reps <= 100 else {
            return .invalid(reason: "Reps must be between 1 and 100.")
        }
        let validSetTypes = ["working", "warmup", "drop", "failure"]
        guard validSetTypes.contains(cmd.setType) else {
            return .invalid(reason: "Unknown set type: \(cmd.setType)")
        }
        return nil
    }
}
