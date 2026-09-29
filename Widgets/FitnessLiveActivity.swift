import SwiftUI
#if canImport(ActivityKit) && canImport(WidgetKit)
import ActivityKit
import WidgetKit

public struct FitnessLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FitnessLiveActivityAttributes.self) { context in
            // Lock Screen & Notification Center UI
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.workoutName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("REST")
                        .font(.headline)
                        .foregroundColor(.blue) // Using system blue fallback if AppColors isn't available to Widget target
                    
                    Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Up Next:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(context.state.nextExerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("REST")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.nextExerciseName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Placeholders for interactive buttons if supported later (iOS 17 AppIntents)
                    // We keep it minimal for now based on requirements
                    HStack {
                        Spacer()
                    }
                }
            } compactLeading: {
                Text("REST")
                    .foregroundColor(.blue)
                    .font(.caption2)
                    .fontWeight(.bold)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.restEndDate, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 40)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
        }
    }
}
#endif
