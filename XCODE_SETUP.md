# Xcode Setup Requirements

Follow these steps to fully configure the project in Xcode.

## 1. Project Initialization
- [ ] Open the project folder in Xcode.
- [ ] Set up the iOS Application target (`FitnessApp`).
- [ ] Set up the watchOS Application target (`FitnessWatchApp`).
- [ ] Set up the Widget Extension target (`FitnessWidgetExtension`).

## 2. Capability Configuration

### iOS Target
- **HealthKit**: 
  - Add HealthKit capability. 
  - Enable "Clinical Health Records" if required (not currently required).
- **Background Modes**:
  - Add if required for Live Activities background updates.
- **In-App Purchase**:
  - Add capability to support StoreKit 2.
- **Push Notifications**:
  - Add capability if implementing backend-driven AI notifications.

### watchOS Target
- **HealthKit**: Add capability.
- **Background Modes**:
  - Enable "Workout Processing" to allow the app to remain active during a workout session.

## 3. Info.plist Additions

**iOS `Info.plist`**:
```xml
<key>NSHealthUpdateUsageDescription</key>
<string>We need access to HealthKit to save your workouts and body measurements.</string>
<key>NSHealthShareUsageDescription</key>
<string>We need access to HealthKit to read your body measurements and sync your workout data.</string>
<key>NSSupportsLiveActivities</key>
<true/>
```

**watchOS `Info.plist`**:
```xml
<key>NSHealthUpdateUsageDescription</key>
<string>We need access to HealthKit to save your workouts.</string>
<key>NSHealthShareUsageDescription</key>
<string>We need access to HealthKit to read your workout data.</string>
```

## 4. Dependencies
- Ensure all Swift Packages (if any) are resolved. Currently, the project uses native SwiftUI, SwiftData, and standard Apple frameworks.

## 5. Build and Run
- Select a physical device or simulator and press `Cmd+R`.
