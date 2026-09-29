import SwiftUI
import SwiftData

public struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: Exercise
    @State private var showingProgression = false
    
    public init(exercise: Exercise) {
        self.exercise = exercise
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.l) {
                    headerSection
                    detailsSection
                    
                    if let instructions = exercise.instructions, !instructions.isEmpty {
                        instructionsSection(instructions)
                    }
                    
                    Button(action: {
                        showingProgression = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Coach Progression Analysis")
                        }
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppRadius.large)
                    }
                    
                    if exercise.isCustom {
                        deleteButton
                    }
                }
                .padding()
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation {
                        exercise.isFavorite.toggle()
                        Haptics.shared.playSelection()
                    }
                }) {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                        .foregroundColor(exercise.isFavorite ? AppColors.warning : AppColors.primary)
                }
            }
        }
        .navigationDestination(isPresented: $showingProgression) {
            AIProgressionView(exercise: exercise)
        }
        .requiresProEntitlement(for: .aiProgressiveOverload, isPresented: $showingProgression)
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Rectangle()
                    .fill(AppColors.secondaryBackground)
                    .frame(height: 200)
                    .cornerRadius(AppRadius.large)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Text(exercise.name)
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 0) {
            detailRow(title: "Primary Muscle", value: exercise.primaryMuscle)
            Divider().background(AppColors.textTertiary.opacity(0.3))
            detailRow(title: "Equipment", value: exercise.equipment)
            Divider().background(AppColors.textTertiary.opacity(0.3))
            detailRow(title: "Movement Type", value: exercise.movementType)
        }
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppSpacing.m)
    }
    
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("INSTRUCTIONS")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .kerning(1.2)
            
            Text(instructions)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.m)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.large)
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive, action: {
            modelContext.delete(exercise)
            // Ideally pop back to list here
        }) {
            Text("Delete Custom Exercise")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.error)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.error.opacity(0.1))
                .cornerRadius(AppRadius.large)
        }
        .padding(.top, AppSpacing.xl)
    }
}
