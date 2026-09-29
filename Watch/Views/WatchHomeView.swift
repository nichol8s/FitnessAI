import SwiftUI

#if os(watchOS)
public struct WatchHomeView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            if let workout = workoutManager.activeWorkout {
                WatchWorkoutView(workout: workout)
            } else {
                VStack(spacing: 12) {
                    Text("TODAY")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("No workout planned")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Start a workout on your iPhone to sync it here.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .navigationTitle("Fitness")
            }
        }
    }
}
#endif
