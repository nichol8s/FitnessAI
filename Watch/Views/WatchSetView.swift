import SwiftUI

#if os(watchOS)
public struct WatchSetView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    let exercise: SyncExerciseMessage
    let set: SyncSetMessage
    
    @State private var weight: Double
    @State private var reps: Int
    
    public init(exercise: SyncExerciseMessage, set: SyncSetMessage) {
        self.exercise = exercise
        self.set = set
        _weight = State(initialValue: set.weight)
        _reps = State(initialValue: set.reps)
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Weight Stepper
                VStack(spacing: 4) {
                    Text("WEIGHT (kg)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: { weight = max(0, weight - 2.5) }) {
                            Image(systemName: "minus")
                        }
                        .tint(.gray)
                        
                        Text(formatWeight(weight))
                            .font(.title2)
                            .monospacedDigit()
                            .frame(minWidth: 60)
                        
                        Button(action: { weight += 2.5 }) {
                            Image(systemName: "plus")
                        }
                        .tint(.gray)
                    }
                }
                
                // Reps Stepper
                VStack(spacing: 4) {
                    Text("REPS")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: { reps = max(0, reps - 1) }) {
                            Image(systemName: "minus")
                        }
                        .tint(.gray)
                        
                        Text("\(reps)")
                            .font(.title2)
                            .monospacedDigit()
                            .frame(minWidth: 60)
                        
                        Button(action: { reps += 1 }) {
                            Image(systemName: "plus")
                        }
                        .tint(.gray)
                    }
                }
                
                Button(action: {
                    // Start 90s default rest if working set. In production, read from exercise default.
                    workoutManager.completeSet(
                        exerciseID: exercise.exerciseID,
                        setID: set.setID,
                        weight: weight,
                        reps: reps,
                        restDuration: 90
                    )
                    dismiss()
                }) {
                    Text("COMPLETE")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .tint(.green)
            }
        }
        .navigationTitle("Set \(set.setOrder + 1)")
    }
    
    private func formatWeight(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
#endif
