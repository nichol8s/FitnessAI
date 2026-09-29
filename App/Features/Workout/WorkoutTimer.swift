import SwiftUI
import UserNotifications

@Observable
public final class WorkoutTimer {
    public var elapsedTime: TimeInterval = 0
    public var isPaused: Bool = false
    
    // Rest Timer Properties
    public var activeRestTimer: TimeInterval? = nil // Remaining time
    public var restTimerTarget: Date? = nil
    
    private var timerTask: Task<Void, Never>?
    private var lastTickDate: Date = Date()
    
    public init() {}
    
    public func start() {
        lastTickDate = Date()
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                tick()
            }
        }
    }
    
    public func pause() {
        isPaused = true
    }
    
    public func resume() {
        isPaused = false
        lastTickDate = Date()
    }
    
    public func stop() {
        timerTask?.cancel()
    }
    
    public func startRest(seconds: Int) {
        let duration = TimeInterval(seconds)
        restTimerTarget = Date().addingTimeInterval(duration)
        activeRestTimer = duration
        
        scheduleNotification(for: duration)
    }
    
    public func skipRest() {
        restTimerTarget = nil
        activeRestTimer = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        LiveActivityManager.shared.endAllActivities()
    }
    
    public func addRestTime(_ seconds: Int) {
        guard let target = restTimerTarget else { return }
        let newTarget = target.addingTimeInterval(TimeInterval(seconds))
        restTimerTarget = newTarget
        recalculateRestTimer()
        
        let remaining = newTarget.timeIntervalSince(Date())
        scheduleNotification(for: remaining)
        LiveActivityManager.shared.updateRestTimerActivity(nextExercise: "Up Next", endDate: newTarget)
    }
    
    public func subtractRestTime(_ seconds: Int) {
        guard let target = restTimerTarget else { return }
        let newTarget = target.addingTimeInterval(TimeInterval(-seconds))
        if newTarget.timeIntervalSince(Date()) <= 0 {
            skipRest()
        } else {
            restTimerTarget = newTarget
            recalculateRestTimer()
            
            let remaining = newTarget.timeIntervalSince(Date())
            scheduleNotification(for: remaining)
            LiveActivityManager.shared.updateRestTimerActivity(nextExercise: "Up Next", endDate: newTarget)
        }
    }
    
    @MainActor
    private func tick() {
        let now = Date()
        let delta = now.timeIntervalSince(lastTickDate)
        lastTickDate = now
        
        if !isPaused {
            elapsedTime += delta
        }
        
        recalculateRestTimer(now: now)
    }
    
    @MainActor
    private func recalculateRestTimer(now: Date = Date()) {
        if let target = restTimerTarget {
            let remaining = target.timeIntervalSince(now)
            if remaining <= 0 {
                restTimerTarget = nil
                activeRestTimer = nil
                Haptics.shared.timerFinished()
                LiveActivityManager.shared.endAllActivities()
            } else {
                activeRestTimer = remaining
            }
        }
    }
    
    private func scheduleNotification(for duration: TimeInterval) {
        guard duration > 0 else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Rest Complete"
            content.body = "Time for your next set."
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
            let request = UNNotificationRequest(identifier: "RestTimer", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    public var formattedElapsed: String {
        formatTime(elapsedTime)
    }
    
    public var formattedRest: String? {
        guard let rest = activeRestTimer else { return nil }
        return formatTime(rest)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
