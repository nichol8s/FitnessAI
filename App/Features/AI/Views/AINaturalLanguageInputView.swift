import SwiftUI
import SwiftData

public struct AINaturalLanguageInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.dismiss) private var dismiss
    
    let currentExerciseID: String?
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    @State private var parsedCommand: AIWorkoutCommand?
    @AppStorage("quickAILoggingEnabled") private var quickAILoggingEnabled: Bool = false
    
    public init(currentExerciseID: String?) {
        self.currentExerciseID = currentExerciseID
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // Header
            HStack {
                Text(parsedCommand == nil ? "Ask Coach" : "Confirmation")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                        .font(.title2)
                }
            }
            .padding()
            
            if let command = parsedCommand {
                AINaturalLanguageConfirmationView(
                    command: command,
                    onConfirm: {
                        workoutManager.executeAICommand(command, context: modelContext)
                        dismiss()
                    },
                    onCancel: {
                        self.parsedCommand = nil
                        self.inputText = ""
                    }
                )
            } else {
                
                if let error = errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.error)
                        .padding(.horizontal)
                        .padding(.bottom, AppSpacing.s)
                }
                
                // Input Area
                HStack(alignment: .bottom, spacing: AppSpacing.m) {
                    TextField("E.g., 'Bench 60kg for 10'", text: $inputText)
                        .font(AppTypography.body)
                        .padding(AppSpacing.m)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppRadius.large)
                        .foregroundColor(AppColors.textPrimary)
                        .disabled(isProcessing)
                        .onSubmit { submitText() }
                    
                    Button(action: submitText) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(inputText.isEmpty ? AppColors.textTertiary : AppColors.primary)
                    .clipShape(Circle())
                    .disabled(inputText.isEmpty || isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, AppSpacing.l)
                
                // Examples
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Try saying:")
                        .font(AppTypography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            exampleChip("I did 3 sets of 50kg for 10")
                            exampleChip("Rest 90 seconds")
                            exampleChip("Mark this set as failure")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.background)
        .cornerRadius(AppRadius.extraLarge, corners: [.topLeft, .topRight])
    }
    
    private func exampleChip(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.secondaryBackground)
            .foregroundColor(AppColors.textSecondary)
            .clipShape(Capsule())
            .onTapGesture {
                inputText = text
            }
    }
    
    private func submitText() {
        guard !inputText.isEmpty, let activeWorkout = workoutManager.activeWorkout else { return }
        
        isProcessing = true
        errorMessage = nil
        Haptics.shared.playSelection()
        
        Task {
            let allExDescriptor = FetchDescriptor<Exercise>()
            guard let allExercises = try? modelContext.fetch(allExDescriptor) else {
                await MainActor.run {
                    self.errorMessage = "Failed to access exercise database."
                    self.isProcessing = false
                }
                return
            }
            
            let catalog = allExercises.map {
                ExerciseReference(id: $0.id.uuidString, name: $0.name, primaryMuscleGroup: $0.primaryMuscle, equipment: $0.equipment)
            }
            
            let request = AINaturalLanguageWorkoutRequest(
                text: inputText,
                workoutID: activeWorkout.id.uuidString,
                currentExerciseID: currentExerciseID,
                availableExerciseReferences: catalog
            )
            
            do {
                let cmd = try await AIProviderFactory.shared.parseWorkoutCommand(request: request)
                let validator = AINaturalLanguageCommandValidator()
                
                await MainActor.run {
                    if case .invalid(let reason) = validator.validate(command: cmd, activeWorkout: activeWorkout) {
                        self.errorMessage = "Could not validate command: \(reason)"
                    } else if cmd.status == .needsClarification {
                        self.errorMessage = cmd.clarificationMessage ?? "I didn't quite get that. Can you clarify?"
                    } else if cmd.status == .valid {
                        
                        // Fast log mode check
                        if quickAILoggingEnabled && (cmd.commandType == "logSet" || cmd.commandType == "startRest") {
                            workoutManager.executeAICommand(cmd, context: modelContext)
                            dismiss()
                        } else {
                            self.parsedCommand = cmd
                            Haptics.shared.success()
                        }
                    }
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "AI logging unavailable offline."
                    self.isProcessing = false
                }
            }
        }
    }
}

// Custom corner modifier for bottom sheets
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Confirmation View

struct AINaturalLanguageConfirmationView: View {
    let command: AIWorkoutCommand
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            
            Text("I understood:")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                switch command.commandType {
                case "logSet":
                    if let cmd = command.logSetCommand {
                        Text("Log Set")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("\(formatWeight(cmd.weight)) kg × \(cmd.reps) (\(cmd.setType))")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.primary)
                    }
                case "logMultipleSets":
                    if let cmd = command.logMultipleSetsCommand {
                        Text("Log \(cmd.sets.count) Sets")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(cmd.sets.indices, id: \.self) { i in
                            Text("\(i+1). \(formatWeight(cmd.sets[i].weight)) kg × \(cmd.sets[i].reps)")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.primary)
                        }
                    }
                case "startRest":
                    if let duration = command.restDurationSeconds {
                        Text("Start Rest")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Text("\(duration) seconds")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.primary)
                    }
                default:
                    Text("Unsupported Command")
                        .foregroundColor(AppColors.error)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppRadius.large)
            
            HStack(spacing: AppSpacing.m) {
                Button(action: onCancel) {
                    Text("CANCEL")
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppRadius.large)
                }
                
                Button(action: onConfirm) {
                    Text("CONFIRM")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGradient)
                        .cornerRadius(AppRadius.large)
                        .appShadow(AppShadows.medium)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, AppSpacing.xl)
    }
    
    private func formatWeight(_ num: Double) -> String {
        let isInteger = floor(num) == num
        return isInteger ? "\(Int(num))" : String(format: "%.1f", num)
    }
}
