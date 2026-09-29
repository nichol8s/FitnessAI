import SwiftUI

public enum AppColors {
    // Primary Accents
    public static let primary = Color("AccentColor") // Assuming an accent color is set in assets
    public static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Backgrounds
    public static let background = Color("Background") // Dark mode default
    public static let secondaryBackground = Color("SecondaryBackground")
    public static let tertiaryBackground = Color("TertiaryBackground")
    
    // Text
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // Semantic
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red
    public static let info = Color.blue
    
    // Charts
    public static let chartPrimary = primary
    public static let chartSecondary = primary.opacity(0.5)
}

// Helper for Glassmorphism
public struct GlassmorphicBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark) // Enforce dark elegant look
    }
}

extension View {
    public func glassBackground() -> some View {
        modifier(GlassmorphicBackground())
    }
}
