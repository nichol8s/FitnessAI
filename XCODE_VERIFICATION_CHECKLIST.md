# Xcode Verification Checklist

This project was developed on Windows. Before claiming that any feature is "production ready," "fully tested," or "works on an iPhone/Apple Watch," the following checklist MUST be executed in Xcode on macOS using actual hardware or a simulator.

## 1. Project Configuration & Target Membership
- [ ] Open the Xcode project (`.xcodeproj` or `Package.swift`).
- [ ] Verify iOS target membership for all views, models, and iOS-specific managers.
- [ ] Verify watchOS target membership for all Watch views and `WatchWorkoutManager`.
- [ ] Verify Widget Extension target membership for `FitnessLiveActivity.swift` and `FitnessLiveActivityAttributes.swift`.
- [ ] Ensure shared files (e.g., `WatchConnectivityManager`, `Models`) are included in both iOS and watchOS targets.
- [ ] Check deployment targets (iOS 17+, watchOS 10+).

## 2. Capability Verification
- [ ] **HealthKit**: Ensure the HealthKit capability is added to both iOS and watchOS targets.
- [ ] **Background Modes**: Verify that the necessary background modes are enabled only where appropriate (e.g., Watch workouts).
- [ ] **Live Activities**: Verify `NSSupportsLiveActivities` is set to `YES` in `Info.plist`.
- [ ] **In-App Purchases**: Ensure In-App Purchases capability is added to the iOS target for StoreKit 2.

## 3. SwiftData & Concurrency
- [ ] Run the app with Main Thread Checker enabled.
- [ ] Run the app with Strict Concurrency Checking to catch any actor isolation issues.
- [ ] Verify SwiftData models create, update, and delete properly across launches.

## 4. Hardware/OS Integration
- [ ] **HealthKit**: Authorize HealthKit permissions and verify workout and body measurement syncing.
- [ ] **WatchConnectivity**: Pair an Apple Watch simulator (or physical device) and verify real-time sync of sets and workouts.
- [ ] **Live Activities**: Start a workout and verify the Live Activity updates and appears in the Dynamic Island.

## 5. Build Configurations
- [ ] Build the app in **Debug** mode and verify `MockAIProvider` is used.
- [ ] Build the app in **Release** mode and verify `AIAPIClient` is used (this will throw `networkUnavailable` errors until the backend is integrated).

## 6. UI & Accessibility
- [ ] Run the app on devices with different screen sizes.
- [ ] Test with Dynamic Type enabled.
- [ ] Test with VoiceOver to ensure accessibility labels are functional.
- [ ] Verify Dark Mode and Light Mode styling using the Design System colors.
