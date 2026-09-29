import SwiftUI

#if os(watchOS)
public struct WatchExerciseView: View {
    let exercise: SyncExerciseMessage
    
    public init(exercise: SyncExerciseMessage) {
        self.exercise = exercise
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if exercise.supersetID != nil {
                    Text("SUPERSET")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Sets
                let sortedSets = exercise.sets.sorted(by: { $0.setOrder < $1.setOrder })
                ForEach(sortedSets, id: \.setID) { set in
                    NavigationLink(destination: WatchSetView(exercise: exercise, set: set)) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(set.isCompleted ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                
                                Text(setTypeLabel(for: set))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("\(formatWeight(set.weight)) kg × \(set.reps)")
                                    .font(.body)
                                    .strikethrough(set.isCompleted)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func setTypeLabel(for set: SyncSetMessage) -> String {
        switch set.setType {
        case "warmup": return "W"
        case "drop": return "D"
        case "failure": return "F"
        default: return "\(set.setOrder + 1)"
        }
    }
    
    private func formatWeight(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
#endif
