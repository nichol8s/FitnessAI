import SwiftUI
import SwiftData

public struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String? = nil
    @State private var showingCreateCustom = false
    
    let muscleGroups = ["All", "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Core"]
    
    public init() {}
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup == nil || selectedMuscleGroup == "All" || exercise.primaryMuscle == selectedMuscleGroup
            return matchesSearch && matchesMuscle
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    muscleGroupFilter
                    
                    List {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRow(exercise: exercise)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateCustom = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateCustom) {
                CreateCustomExerciseView()
            }
        }
    }
    
    private var muscleGroupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                ForEach(muscleGroups, id: \.self) { group in
                    let isSelected = (selectedMuscleGroup == group) || (selectedMuscleGroup == nil && group == "All")
                    
                    Text(group)
                        .font(AppTypography.caption)
                        .fontWeight(isSelected ? .bold : .medium)
                        .padding(.horizontal, AppSpacing.m)
                        .padding(.vertical, AppSpacing.s)
                        .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                        .clipShape(Capsule())
                        .onTapGesture {
                            withAnimation(AppAnimations.snap) {
                                selectedMuscleGroup = group == "All" ? nil : group
                                Haptics.shared.playSelection()
                            }
                        }
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
        }
    }
}

public struct ExerciseRow: View {
    let exercise: Exercise
    
    public var body: some View {
        HStack(spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(exercise.name)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.s) {
                    Text(exercise.primaryMuscle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Circle()
                        .fill(AppColors.textTertiary)
                        .frame(width: 4, height: 4)
                    
                    Text(exercise.equipment)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            if exercise.isFavorite {
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
