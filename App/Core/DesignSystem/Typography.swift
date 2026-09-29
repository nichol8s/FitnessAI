import SwiftUI

public enum AppTypography {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let title = Font.system(.title, design: .rounded, weight: .bold)
    public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    public static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
    
    public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    public static let subheadline = Font.system(.subheadline, design: .rounded, weight: .regular)
    
    public static let body = Font.system(.body, design: .rounded, weight: .regular)
    public static let callout = Font.system(.callout, design: .rounded, weight: .regular)
    
    public static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    public static let caption2 = Font.system(.caption2, design: .rounded, weight: .medium)
    
    // Custom Numeric Fonts for Timers and Weights
    public static let numericDisplay = Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit()
    public static let numericLarge = Font.system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
    public static let numericMedium = Font.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit()
}
