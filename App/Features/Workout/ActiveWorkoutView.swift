import SwiftUI
import SwiftData

public struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFinishConfirmation = false
    @State private var showingSummary = false
    @State private var showingAILogger = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()
                
                if let workout = workoutManager.activeWorkout {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: AppSpacing.xl) {
                                // Workout header space
                                Spacer().frame(height: AppSpacing.s)
                                
                                let sortedExercises = workout.workoutExercises.sorted(by: { $0.order < $1.order })
                                
                                // Group by supersetID visually
                                ForEach(sortedExercises) { exercise in
                                    if exercise.supersetID != nil {
                                        // Simplified superset UI: In production, group these visually with a bracket or card.
                                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                            Text("SUPERSET")
                                                .font(AppTypography.caption)
                                                .foregroundColor(AppColors.primary)
                                                .padding(.horizontal, AppSpacing.l)
                                            ExerciseCard(workoutExercise: exercise)
                                        }
                                        .id(exercise.id)
                                    } else {
                                        ExerciseCard(workoutExercise: exercise)
                                            .id(exercise.id)
                                    }
                                }
                                
                                Button(action: {
                                    showingFinishConfirmation = true
                                }) {
                                    Text("FINISH WORKOUT")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.success)
                                        .cornerRadius(AppRadius.large)
                                        .padding(.horizontal, AppSpacing.m)
                                }
                                .padding(.top, AppSpacing.l)
                                
                                // Padding for bottom timer overlay
                                Spacer().frame(height: 120)
                            }
                        }
                    }
                    
                    // Floating Rest Timer and AI Logger
                    VStack(spacing: AppSpacing.s) {
                        Spacer()
                        
                        Button(action: {
                            showingAILogger = true
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Ask Coach or log a set...")
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.l)
                            .padding(.vertical, AppSpacing.s)
                            .background(AppColors.secondaryBackground)
                            .clipShape(Capsule())
                            .appShadow(AppShadows.subtle)
                        }
                        
                        RestTimerView()
                            .padding(.bottom, AppSpacing.m)
                    }
                } else {
                    Text("No active workout")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle(workoutManager.activeWorkout?.name ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        workoutManager.currentTimer.pause()
                    }) {
                        Text(workoutManager.currentTimer.formattedElapsed)
                            .font(AppTypography.numericMedium)
                            .foregroundColor(AppColors.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") {
                        showingFinishConfirmation = true
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.success)
                }
            }
            .confirmationDialog("Finish Workout?", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
                Button("Finish", action: finishWorkout)
                Button("Discard", role: .destructive, action: discardWorkout)
                Button("Keep Working", role: .cancel) { }
            } message: {
                if let workout = workoutManager.activeWorkout {
                    Text("You've completed \(workout.completedSets) sets.")
                }
            }
            .fullScreenCover(isPresented: $showingSummary, onDismiss: {
                workoutManager.clearWorkout()
                dismiss()
            }) {
                if let workout = workoutManager.activeWorkout {
                    WorkoutSummaryView(workout: workout)
                }
            }
            .sheet(isPresented: $showingAILogger) {
                // Pass current exercise if we could deduce it (omitted for brevity here, could track scroll position)
                AINaturalLanguageInputView(currentExerciseID: workoutManager.activeWorkout?.workoutExercises.first?.exercise?.id.uuidString)
                    .presentationDetents([.height(300), .medium])
                    .presentationDragIndicator(.visible)
            }
            .requiresProEntitlement(for: .aiNaturalLanguageLogging, isPresented: $showingAILogger)
        }
    }
    
    private func finishWorkout() {
        workoutManager.finishWorkout(context: modelContext)
        showingSummary = true
    }
    
    private func discardWorkout() {
        workoutManager.discardWorkout(context: modelContext)
        dismiss()
    }
}
