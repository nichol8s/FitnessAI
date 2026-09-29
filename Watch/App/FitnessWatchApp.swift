import SwiftUI
#if os(watchOS)
import WatchKit

@main
struct FitnessWatchApp: App {
    @StateObject private var watchWorkoutManager = WatchWorkoutManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(watchWorkoutManager)
        }
    }
}
#endif
