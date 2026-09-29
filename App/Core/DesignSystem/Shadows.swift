import SwiftUI

public enum AppShadows {
    public static let subtle = ShadowConfiguration(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    public static let medium = ShadowConfiguration(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    public static let strong = ShadowConfiguration(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
    
    // For glow effects around active components (e.g., active timer)
    public static let glow = ShadowConfiguration(color: AppColors.primary.opacity(0.5), radius: 12, x: 0, y: 0)
}

public struct ShadowConfiguration {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

public extension View {
    func appShadow(_ config: ShadowConfiguration) -> some View {
        self.shadow(color: config.color, radius: config.radius, x: config.x, y: config.y)
    }
}
