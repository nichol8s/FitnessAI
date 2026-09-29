import SwiftUI
import SwiftData

public struct AIWorkoutGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // UI State
    @State private var selectedGoal: String = "Build Muscle"
    @State private var selectedExperience: String = "Intermediate"
    @State private var selectedDuration: Int = 45
    @State private var selectedEquipment: Set<String> = ["Full Gym"]
    @State private var selectedMuscles: Set<String> = []
    @State private var extraNotes: String = ""
    
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    // Navigation state
    @State private var generatedWorkout: AIGeneratedWorkout?
    
    private let goals = ["Build Muscle", "Strength", "Fat Loss", "General Fitness", "Endurance"]
    private let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    private let durations = [20, 30, 45, 60, 90]
    private let equipmentOptions = ["Full Gym", "Dumbbells", "Barbell", "Machines", "Cable", "Bodyweight"]
    private let muscleOptions = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Glutes", "Core", "Full Body"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            Text("DESIGN YOUR WORKOUT")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.primary)
                                .kerning(1.2)
                            Text("Tell your AI coach exactly what you want to achieve today.")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // Goal
                        SectionView(title: "GOAL") {
                            SingleSelectChipGroup(options: goals, selection: $selectedGoal)
                        }
                        
                        // Experience
                        SectionView(title: "EXPERIENCE") {
                            SingleSelectChipGroup(options: experienceLevels, selection: $selectedExperience)
                        }
                        
                        // Duration
                        SectionView(title: "DURATION") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(durations, id: \.self) { min in
                                        let isSelected = selectedDuration == min
                                        Text("\(min) min")
                                            .font(AppTypography.caption)
                                            .padding(.horizontal, AppSpacing.m)
                                            .padding(.vertical, AppSpacing.s)
                                            .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                                            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                                            .clipShape(Capsule())
                                            .onTapGesture {
                                                withAnimation { selectedDuration = min }
                                            }
                                    }
                                }
                            }
                        }
                        
                        // Equipment
                        SectionView(title: "EQUIPMENT") {
                            MultiSelectChipGroup(options: equipmentOptions, selection: $selectedEquipment)
                        }
                        
                        // Muscle Groups
                        SectionView(title: "TARGET MUSCLES") {
                            MultiSelectChipGroup(options: muscleOptions, selection: $selectedMuscles)
                        }
                        
                        // Notes
                        SectionView(title: "OPTIONAL PREFERENCES") {
                            TextField("Anything else? (e.g. Avoid shoulder pressing)", text: $extraNotes)
                                .padding()
                                .background(AppColors.secondaryBackground)
                                .cornerRadius(AppRadius.large)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                        }
                        
                        // Generate Button
                        Button(action: generateWorkout) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("GENERATE WORKOUT")
                                }
                            }
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primaryGradient)
                            .cornerRadius(AppRadius.large)
                            .appShadow(AppShadows.medium)
                        }
                        .disabled(isGenerating)
                        .padding(.top, AppSpacing.l)
                    }
                    .padding(AppSpacing.l)
                }
            }
            .navigationTitle("AI Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $generatedWorkout) { workout in
                AIWorkoutPreviewView(generatedWorkout: workout)
            }
        }
    }
    
    private func generateWorkout() {
        // Local Validation
        guard !selectedEquipment.isEmpty else {
            errorMessage = "Please select at least one equipment type."
            return
        }
        guard !selectedMuscles.isEmpty else {
            errorMessage = "Please select target muscle groups."
            return
        }
        
        isGenerating = true
        errorMessage = nil
        Haptics.shared.playSelection()
        
        Task {
            // Build Exercise Catalog Reference
            let allExDescriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
            guard let exercises = try? modelContext.fetch(allExDescriptor) else {
                await MainActor.run {
                    self.errorMessage = "Failed to load local exercise database."
                    self.isGenerating = false
                }
                return
            }
            
            let catalog = exercises.map { ex in
                ExerciseReference(
                    id: ex.id.uuidString,
                    name: ex.name,
                    primaryMuscleGroup: ex.primaryMuscle,
                    equipment: ex.equipment
                )
            }
            
            let request = AIWorkoutGenerationRequest(
                goal: selectedGoal,
                experienceLevel: selectedExperience,
                workoutDurationMinutes: selectedDuration,
                availableEquipment: Array(selectedEquipment),
                targetMuscleGroups: Array(selectedMuscles),
                notes: extraNotes.isEmpty ? nil : extraNotes,
                availableExercises: catalog
            )
            
            do {
                let workout = try await AIProviderFactory.shared.generateWorkout(request: request)
                
                await MainActor.run {
                    // Strict Validation Before Showing Preview
                    let validator = AIWorkoutValidator(context: modelContext)
                    let result = validator.validate(workout)
                    
                    switch result {
                    case .valid:
                        self.generatedWorkout = workout
                        Haptics.shared.success()
                    case .invalid(let reason):
                        self.errorMessage = "The AI generated an invalid workout: \(reason)"
                    }
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Reusable UI Components

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .kerning(1.2)
            content
        }
    }
}

struct SingleSelectChipGroup: View {
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        FlowLayout(spacing: AppSpacing.s) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Text(option)
                    .font(AppTypography.caption)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                    .clipShape(Capsule())
                    .onTapGesture {
                        withAnimation { selection = option }
                    }
            }
        }
    }
}

struct MultiSelectChipGroup: View {
    let options: [String]
    @Binding var selection: Set<String>
    
    var body: some View {
        FlowLayout(spacing: AppSpacing.s) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.contains(option)
                Text(option)
                    .font(AppTypography.caption)
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                    .clipShape(Capsule())
                    .onTapGesture {
                        withAnimation {
                            if isSelected {
                                selection.remove(option)
                            } else {
                                selection.insert(option)
                            }
                        }
                    }
            }
        }
    }
}

// Helper to wrap chips to the next line dynamically
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.frames[index].origin
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += rowHeight + spacing
                    rowHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: viewSize.width, height: viewSize.height))
                
                currentX += viewSize.width + spacing
                rowHeight = max(rowHeight, viewSize.height)
            }
            
            size = CGSize(width: maxWidth, height: currentY + rowHeight)
        }
    }
}
