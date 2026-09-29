import UIKit

public final class Haptics {
    public static let shared = Haptics()
    
    private init() {}
    
    public func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    public func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // Semantic haptic helpers
    public func setCompleted() {
        play(.medium)
    }
    
    public func workoutFinished() {
        playNotification(.success)
    }
    
    public func prAchieved() {
        play(.rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.play(.heavy)
        }
    }
    
    public func timerFinished() {
        playNotification(.warning)
    }
}
