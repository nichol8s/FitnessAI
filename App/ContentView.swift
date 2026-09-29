import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) private var workoutManager
    
    @State private var selectedTab: Tab = .history
    
    enum Tab {
        case history
        case workout
        case exercises
        case progress
        case ai
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)
            
            RoutinesListView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(Tab.workout)
            
            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }
                .tag(Tab.exercises)
            
            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(Tab.progress)
            
            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
                .tag(Tab.ai)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.profile)
        }
        .tint(AppColors.primary)
        .onAppear {
            workoutManager.checkForActiveWorkout(context: modelContext)
        }
        .confirmationDialog(
            "Resume Workout?",
            isPresented: Bindable(workoutManager).showingRecoveryDialog,
            titleVisibility: .visible
        ) {
            Button("Resume Workout") {
                workoutManager.resumeRecoveredWorkout()
            }
            Button("Discard", role: .destructive) {
                workoutManager.discardRecoveredWorkout(context: modelContext)
            }
        } message: {
            if let workout = workoutManager.recoveredWorkout {
                Text("\(workout.name) is currently in progress.")
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { workoutManager.activeWorkout != nil && !workoutManager.showingRecoveryDialog },
            set: { _ in }
        )) {
            ActiveWorkoutView()
        }
    }
}
