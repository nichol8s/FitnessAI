import Foundation
import SwiftData

@Observable
public final class WorkoutManager {
    public var activeWorkout: Workout?
    public var currentTimer = WorkoutTimer()
    public var sessionPRCount: Int = 0
    public var showingRecoveryDialog = false
    public var recoveredWorkout: Workout?
    
    private var executedCommandIDs: Set<String> = []
    
    public init() {
        WatchConnectivityManager.shared.onSetCompleted = { [weak self] event in
            self?.handleIncomingWatchSet(event)
        }
    }
    
    @MainActor
    public func checkForActiveWorkout(context: ModelContext) {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted == false },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let incomplete = try? context.fetch(descriptor).first {
            recoveredWorkout = incomplete
            showingRecoveryDialog = true
        }
    }
    
    @MainActor
    public func resumeRecoveredWorkout() {
        if let workout = recoveredWorkout {
            activeWorkout = workout
            // Best effort timer reconstruction
            currentTimer.elapsedTime = Date().timeIntervalSince(workout.startTime)
            currentTimer.start()
        }
        recoveredWorkout = nil
        showingRecoveryDialog = false
    }
    
    @MainActor
    public func discardRecoveredWorkout(context: ModelContext) {
        if let workout = recoveredWorkout {
            context.delete(workout)
            try? context.save()
        }
        recoveredWorkout = nil
        showingRecoveryDialog = false
    }
    
    @MainActor
    public func startWorkout(from routine: Routine, context: ModelContext) {
        let workout = Workout(name: routine.name)
        workout.routine = routine
        context.insert(workout)
        
        for routineEx in routine.routineExercises {
            let workoutEx = WorkoutExercise(order: routineEx.order)
            workoutEx.supersetID = routineEx.supersetID
            workoutEx.exercise = routineEx.exercise
            workoutEx.workout = workout
            
            // Create target sets based on routine configuration
            for i in 0..<routineEx.targetSets {
                let weight = routineEx.targetWeight ?? 0
                let repTarget = Int(routineEx.targetRepRange.components(separatedBy: "-").first ?? "0") ?? 0
                let set = WorkoutSet(setOrder: i, weight: weight, reps: repTarget)
                set.restDuration = routineEx.restSeconds
                set.workoutExercise = workoutEx
            }
        }
        
        activeWorkout = workout
        try? context.save()
        currentTimer.start()
        
        broadcastWorkoutState()
    }
    
    @MainActor
    public func finishWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }
        
        workout.endTime = Date()
        workout.duration = currentTimer.elapsedTime
        workout.isCompleted = true
        
        // Calculate volume and stats
        var totalVol: Double = 0
        var completedSetCount = 0
        var totalSets = 0
        
        for workoutEx in workout.workoutExercises {
            for set in workoutEx.sets {
                totalSets += 1
                if set.isCompleted {
                    completedSetCount += 1
                    if set.setType == "working" || set.setType == "failure" || set.setType == "amrap" || set.setType == "drop" {
                        totalVol += (set.weight * Double(set.reps))
                    }
                }
            }
        }
        
        workout.totalVolume = totalVol
        workout.completedSets = completedSetCount
        workout.totalSets = totalSets
        
        let prCalculator = PRCalculator(context: context)
        sessionPRCount = prCalculator.detectAndSavePRs(for: workout)
        
        try? context.save()
        currentTimer.stop()
        LiveActivityManager.shared.endAllActivities()
        Haptics.shared.workoutFinished()
        
        Task {
            await HealthKitManager.shared.syncWorkout(workout, context: context)
        }
        // We will nil it out after showing summary or when explicitly dismissed
    }
    
    @MainActor
    public func toggleSetCompletion(_ set: WorkoutSet, context: ModelContext) {
        set.isCompleted.toggle()
        set.timestamp = set.isCompleted ? Date() : nil
        
        try? context.save() // Save immediately
        
        if set.isCompleted {
            Haptics.shared.setCompleted()
            if let rest = set.restDuration, rest > 0 {
                currentTimer.startRest(seconds: rest)
                if let targetDate = currentTimer.restTimerTarget, let activeWorkout = activeWorkout {
                    let nextEx = activeWorkout.workoutExercises.first(where: { !$0.sets.allSatisfy({ $0.isCompleted }) })?.exercise?.name ?? "Workout Complete"
                    LiveActivityManager.shared.startRestTimerActivity(workoutName: activeWorkout.name, nextExercise: nextEx, endDate: targetDate)
                }
            }
        }
        broadcastWorkoutState()
    }
    
    @MainActor
    public func duplicateSet(_ set: WorkoutSet, context: ModelContext) {
        guard let workoutEx = set.workoutExercise else { return }
        let newSetOrder = workoutEx.sets.count
        let newSet = WorkoutSet(setOrder: newSetOrder, weight: set.weight, reps: set.reps, setType: set.setType)
        newSet.restDuration = set.restDuration
        newSet.workoutExercise = workoutEx
        
        try? context.save()
        Haptics.shared.playSelection()
    }
    
    @MainActor
    public func deleteSet(_ set: WorkoutSet, context: ModelContext) {
        context.delete(set)
        try? context.save()
        Haptics.shared.playSelection()
    }
    
    public func discardWorkout(context: ModelContext) {
        if let workout = activeWorkout {
            context.delete(workout)
            try? context.save()
        }
        currentTimer.stop()
        LiveActivityManager.shared.endAllActivities()
        activeWorkout = nil
    }
    
    public func clearWorkout() {
        LiveActivityManager.shared.endAllActivities()
        activeWorkout = nil
    }
    
    // MARK: - Watch Synchronization
    
    private func broadcastWorkoutState() {
        guard let workout = activeWorkout else { return }
        
        let exercises = workout.workoutExercises.map { ex in
            SyncExerciseMessage(
                exerciseID: ex.id.uuidString,
                name: ex.exercise?.name ?? "Unknown",
                order: ex.order,
                supersetID: ex.supersetID?.uuidString,
                sets: ex.sets.map { set in
                    SyncSetMessage(
                        setID: set.id.uuidString,
                        setOrder: set.setOrder,
                        weight: set.weight,
                        reps: set.reps,
                        isCompleted: set.isCompleted,
                        setType: set.setType
                    )
                }
            )
        }
        
        let message = SyncWorkoutMessage(
            workoutID: workout.id.uuidString,
            workoutName: workout.name,
            startTime: workout.startTime,
            isPaused: currentTimer.isPaused,
            exercises: exercises,
            restEndDate: currentTimer.restTimerTarget
        )
        
        WatchConnectivityManager.shared.sendWorkoutState(message)
    }
    
    private func handleIncomingWatchSet(_ event: SyncSetCompletionEvent) {
        // Find matching active workout and set
        guard let workout = activeWorkout, workout.id.uuidString == event.workoutID else { return }
        
        for workoutEx in workout.workoutExercises {
            if workoutEx.id.uuidString == event.exerciseID {
                if let set = workoutEx.sets.first(where: { $0.id.uuidString == event.setID }) {
                    // Update state idempotently
                    set.weight = event.weight
                    set.reps = event.reps
                    set.isCompleted = true
                    set.timestamp = event.timestamp
                    
                    if let rest = event.restDuration, rest > 0 {
                        currentTimer.startRest(seconds: rest)
                        // Also trigger live activities if appropriate
                        if let targetDate = currentTimer.restTimerTarget {
                            let nextEx = workout.workoutExercises.first(where: { !$0.sets.allSatisfy({ $0.isCompleted }) })?.exercise?.name ?? "Workout Complete"
                            LiveActivityManager.shared.startRestTimerActivity(workoutName: workout.name, nextExercise: nextEx, endDate: targetDate)
                        }
                    }
                }
            }
        }
        
        // This is safe because SwiftData saves model changes automatically if context is valid,
        // but explicit save requires context. Assuming mainContext is used globally for UI updates.
        broadcastWorkoutState()
    }
    
    // MARK: - AI Command Execution
    
    @MainActor
    public func executeAICommand(_ command: AIWorkoutCommand, context: ModelContext) {
        guard !executedCommandIDs.contains(command.id) else { return } // Idempotency protection
        
        switch command.commandType {
        case "logSet":
            if let setCmd = command.logSetCommand {
                logSet(exerciseID: setCmd.exerciseID, weight: setCmd.weight, reps: setCmd.reps, setType: setCmd.setType, context: context)
            }
        case "logMultipleSets":
            if let multiCmd = command.logMultipleSetsCommand {
                for setCmd in multiCmd.sets {
                    logSet(exerciseID: setCmd.exerciseID, weight: setCmd.weight, reps: setCmd.reps, setType: setCmd.setType, context: context)
                }
            }
        case "startRest":
            if let duration = command.restDurationSeconds {
                currentTimer.startRest(seconds: duration)
                if let targetDate = currentTimer.restTimerTarget, let workout = activeWorkout {
                    let nextEx = workout.workoutExercises.first(where: { !$0.sets.allSatisfy({ $0.isCompleted }) })?.exercise?.name ?? "Rest"
                    LiveActivityManager.shared.startRestTimerActivity(workoutName: workout.name, nextExercise: nextEx, endDate: targetDate)
                }
                Haptics.shared.playSelection()
            }
        case "substituteExercise":
            // Not directly executing substitution here to prevent silent corruption, handled in UI.
            break
        default:
            break
        }
        
        executedCommandIDs.insert(command.id)
    }
    
    @MainActor
    private func logSet(exerciseID: String, weight: Double, reps: Int, setType: String, context: ModelContext) {
        guard let workout = activeWorkout else { return }
        guard let workoutEx = workout.workoutExercises.first(where: { $0.exercise?.id.uuidString == exerciseID }) else { return }
        
        // Find the first uncompleted set to overwrite, or append a new one
        if let uncompletedSet = workoutEx.sets.sorted(by: { $0.setOrder < $1.setOrder }).first(where: { !$0.isCompleted }) {
            uncompletedSet.weight = weight
            uncompletedSet.reps = reps
            uncompletedSet.setType = setType
            uncompletedSet.isCompleted = true
            uncompletedSet.timestamp = Date()
        } else {
            // Append new
            let newOrder = workoutEx.sets.count
            let newSet = WorkoutSet(setOrder: newOrder, weight: weight, reps: reps, setType: setType)
            newSet.isCompleted = true
            newSet.timestamp = Date()
            newSet.workoutExercise = workoutEx
            context.insert(newSet)
        }
        
        try? context.save()
        Haptics.shared.setCompleted()
        broadcastWorkoutState()
    }
}
