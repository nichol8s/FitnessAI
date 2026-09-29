import SwiftUI

public enum AppAnimations {
    /// Fast, snappy transitions (e.g., toggles, active states)
    public static let snap = Animation.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0)
    
    /// Smooth, elegant transitions (e.g., sheet presentations, layout changes)
    public static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    
    /// Bouncy transitions (e.g., PR celebrations, completion success)
    public static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)
    
    /// Standard ease-in-out for basic fades
    public static let fade = Animation.easeInOut(duration: 0.2)
}
