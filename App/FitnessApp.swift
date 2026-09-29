import SwiftUI
import SwiftData

@main
struct FitnessApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            UserGoal.self,
            Exercise.self,
            Routine.self,
            RoutineExercise.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            PersonalRecord.self,
            BodyMeasurement.self,
            AIConversation.self,
            AIMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var workoutManager = WorkoutManager()

    init() {
        let context = sharedModelContainer.mainContext
        SampleData.seedExercisesIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(workoutManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
