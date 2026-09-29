import Foundation
import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif
#if canImport(HealthKit)
import HealthKit
#endif

#if os(watchOS)
public final class WatchWorkoutManager: NSObject, ObservableObject {
    public static let shared = WatchWorkoutManager()
    
    @Published public var activeWorkout: SyncWorkoutMessage?
    @Published public var currentExerciseIndex: Int = 0
    @Published public var isReachable: Bool = false
    @Published public var timerRemaining: TimeInterval? = nil
    
    private var timerTask: Task<Void, Never>?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        WatchConnectivityManager.shared.onWorkoutReceived = { [weak self] message in
            DispatchQueue.main.async {
                // If it's a new workout, reset index
                if self?.activeWorkout?.workoutID != message.workoutID {
                    self?.currentExerciseIndex = 0
                }
                
                self?.activeWorkout = message
                self?.recalculateTimer()
            }
        }
        
        // Initial reachability check
        isReachable = WatchConnectivityManager.shared.isReachable
    }
    
    public func completeSet(exerciseID: String, setID: String, weight: Double, reps: Int, restDuration: Int?) {
        guard let workout = activeWorkout else { return }
        
        let event = SyncSetCompletionEvent(
            setID: setID,
            exerciseID: exerciseID,
            workoutID: workout.workoutID,
            weight: weight,
            reps: reps,
            timestamp: Date(),
            restDuration: restDuration
        )
        
        // Optimistically update local state so watch feels responsive immediately
        if let exIndex = activeWorkout?.exercises.firstIndex(where: { $0.exerciseID == exerciseID }),
           let setIndex = activeWorkout?.exercises[exIndex].sets.firstIndex(where: { $0.setID == setID }) {
            activeWorkout?.exercises[exIndex].sets[setIndex].isCompleted = true
            activeWorkout?.exercises[exIndex].sets[setIndex].weight = weight
            activeWorkout?.exercises[exIndex].sets[setIndex].reps = reps
            
            // Start local watch timer optimistically
            if let rest = restDuration, rest > 0 {
                let endDate = Date().addingTimeInterval(TimeInterval(rest))
                activeWorkout = SyncWorkoutMessage(
                    workoutID: workout.workoutID,
                    workoutName: workout.workoutName,
                    startTime: workout.startTime,
                    isPaused: workout.isPaused,
                    exercises: activeWorkout!.exercises,
                    restEndDate: endDate
                )
                recalculateTimer()
            }
        }
        
        WatchConnectivityManager.shared.sendSetCompletion(event)
    }
    
    private func recalculateTimer() {
        timerTask?.cancel()
        
        guard let endDate = activeWorkout?.restEndDate, endDate > Date() else {
            timerRemaining = nil
            return
        }
        
        timerRemaining = endDate.timeIntervalSince(Date())
        
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let remaining = endDate.timeIntervalSince(Date())
                if remaining <= 0 {
                    self.timerRemaining = nil
                    #if os(watchOS)
                    WKInterfaceDevice.current().play(.stop)
                    #endif
                    break
                }
                self.timerRemaining = remaining
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}
#endif
