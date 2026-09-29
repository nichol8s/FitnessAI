import SwiftUI
import SwiftData

public struct SetRow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    
    @Bindable var set: WorkoutSet
    
    // We use local state during typing so we don't spam SwiftData on every keystroke
    @State private var weightString: String = ""
    @State private var repsString: String = ""
    
    public init(set: WorkoutSet) {
        self.set = set
    }
    
    public var body: some View {
        HStack(spacing: AppSpacing.s) {
            // Set indicator (e.g. 1, 2, W, D)
            ZStack {
                Circle()
                    .fill(set.setType == "warmup" ? AppColors.warning.opacity(0.2) : (set.setType == "drop" ? AppColors.error.opacity(0.2) : AppColors.tertiaryBackground))
                    .frame(width: 32, height: 32)
                
                Text(setTypeLabel)
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(set.setType == "warmup" ? AppColors.warning : (set.setType == "drop" ? AppColors.error : AppColors.textSecondary))
            }
            .frame(width: 40)
            
            // Weight Input
            TextField("kg", text: $weightString)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(AppTypography.numericMedium)
                .frame(height: 44)
                .background(set.isCompleted ? AppColors.success.opacity(0.1) : AppColors.tertiaryBackground)
                .cornerRadius(AppRadius.medium)
                .onChange(of: weightString) { _, newValue in
                    if let d = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                        set.weight = d
                    }
                }
            
            // Reps Input
            TextField("reps", text: $repsString)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(AppTypography.numericMedium)
                .frame(height: 44)
                .background(set.isCompleted ? AppColors.success.opacity(0.1) : AppColors.tertiaryBackground)
                .cornerRadius(AppRadius.medium)
                .onChange(of: repsString) { _, newValue in
                    if let r = Int(newValue) {
                        set.reps = r
                    }
                }
            
            // Checkmark
            Button(action: {
                workoutManager.toggleSetCompletion(set, context: modelContext)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(set.isCompleted ? AppColors.success : AppColors.tertiaryBackground)
                        .frame(width: 44, height: 44)
                    
                    if set.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .opacity(set.isCompleted ? 0.6 : 1.0)
        .onAppear {
            if set.weight > 0 { weightString = format(set.weight) }
            if set.reps > 0 { repsString = "\(set.reps)" }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: {
                workoutManager.deleteSet(set, context: modelContext)
            }) {
                Label("Delete", systemImage: "trash")
            }
            
            Button(action: {
                workoutManager.duplicateSet(set, context: modelContext)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(AppColors.info)
        }
        .contextMenu {
            Button("Working Set") { set.setType = "working"; try? modelContext.save() }
            Button("Warmup Set") { set.setType = "warmup"; try? modelContext.save() }
            Button("Drop Set") { set.setType = "drop"; try? modelContext.save() }
            Button("Failure") { set.setType = "failure"; try? modelContext.save() }
        }
    }
    
    private var setTypeLabel: String {
        switch set.setType {
        case "warmup": return "W"
        case "drop": return "D"
        case "failure": return "F"
        case "amrap": return "A"
        default: return "\(set.setOrder + 1)"
        }
    }
    
    private func format(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
