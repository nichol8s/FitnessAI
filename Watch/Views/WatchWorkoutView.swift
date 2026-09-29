import SwiftUI

#if os(watchOS)
public struct WatchWorkoutView: View {
    @EnvironmentObject private var workoutManager: WatchWorkoutManager
    let workout: SyncWorkoutMessage
    
    public init(workout: SyncWorkoutMessage) {
        self.workout = workout
    }
    
    public var body: some View {
        TabView(selection: $workoutManager.currentExerciseIndex) {
            // Paging through exercises
            ForEach(Array(workout.exercises.enumerated()), id: \.element.exerciseID) { index, exercise in
                WatchExerciseView(exercise: exercise)
                    .tag(index)
            }
            
            // Final page to finish workout
            VStack(spacing: 12) {
                Text(workout.workoutName)
                    .font(.headline)
                    .foregroundColor(.blue) // Safe system fallback
                
                Text(timerInterval: workout.startTime...Date(), countsDown: false)
                    .font(.title2)
                    .monospacedDigit()
                
                Button(action: {
                    // Send finish message to iPhone (implemented later if requested)
                    // Currently iPhone must finish, Watch logs sets.
                }) {
                    Text("FINISH ON IPHONE")
                        .font(.headline)
                }
                .tint(.green)
            }
            .tag(workout.exercises.count)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .navigationTitle(workout.workoutName)
        .overlay {
            if let remaining = workoutManager.timerRemaining, remaining > 0 {
                VStack {
                    Spacer()
                    WatchRestTimerView(remaining: remaining)
                }
                .ignoresSafeArea()
            }
        }
    }
}

public struct WatchRestTimerView: View {
    let remaining: TimeInterval
    
    public var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.orange)
            
            // We use simple String format since Date range timer is harder to mock dynamically from TimeInterval directly in watchOS SwiftUI sometimes
            Text(formatTime(remaining))
                .font(.title3)
                .monospacedDigit()
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: remaining)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
#endif
