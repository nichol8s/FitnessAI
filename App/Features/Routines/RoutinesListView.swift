import SwiftUI
import SwiftData

public struct RoutinesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    
    @State private var showingCreateRoutine = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if routines.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                RoutineRow(routine: routine)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateRoutine = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No routines yet.")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Your custom workouts will appear here.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateRoutine = true }) {
                Text("Create Routine")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.m)
                    .background(AppColors.primaryGradient)
                    .cornerRadius(AppRadius.large)
            }
            .padding(.top, AppSpacing.l)
        }
        .padding()
    }
    
    private func deleteRoutines(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(routines[index])
        }
        try? modelContext.save()
    }
}

public struct RoutineRow: View {
    let routine: Routine
    
    public var body: some View {
        HStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: routine.icon ?? "figure.strengthtraining.traditional")
                    .foregroundColor(AppColors.primary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(routine.name)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(routine.routineExercises.count) exercises")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if routine.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(AppColors.warning)
                    .font(.caption)
            }
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
}
