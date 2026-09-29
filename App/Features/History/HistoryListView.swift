import SwiftUI
import SwiftData

public struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Workout> { $0.isCompleted == true }, sort: \Workout.startTime, order: .reverse) private var completedWorkouts: [Workout]
    
    @State private var searchText = ""
    
    public init() {}
    
    private var filteredWorkouts: [Workout] {
        if searchText.isEmpty { return completedWorkouts }
        return completedWorkouts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.routine?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private var groupedWorkouts: [(String, [Workout])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredWorkouts) { workout -> String in
            if calendar.isDateInToday(workout.startTime) { return "TODAY" }
            if calendar.isDateInYesterday(workout.startTime) { return "YESTERDAY" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: workout.startTime).uppercased()
        }
        
        // Sort groups properly based on date
        return groups.sorted { group1, group2 in
            guard let first1 = group1.value.first?.startTime,
                  let first2 = group2.value.first?.startTime else { return false }
            return first1 > first2
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if completedWorkouts.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedWorkouts, id: \.0) { group in
                            Section(header: Text(group.0).font(AppTypography.caption).foregroundColor(AppColors.textSecondary)) {
                                ForEach(group.1) { workout in
                                    NavigationLink(destination: HistoricalWorkoutDetailView(workout: workout)) {
                                        HistoryRow(workout: workout)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search history...")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
            
            Text("NO WORKOUTS YET")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Complete your first workout and your training history will appear here.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

public struct HistoryRow: View {
    let workout: Workout
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                Text(workout.name)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(formatTime(workout.duration ?? 0))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack(spacing: AppSpacing.m) {
                Label(String(format: "%.0f kg", workout.totalVolume), systemImage: "scalemass")
                Label("\(workout.completedSets) sets", systemImage: "repeat")
            }
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        return "\(minutes) min"
    }
}
