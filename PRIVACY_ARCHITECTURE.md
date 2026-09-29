# Privacy & Data Architecture

## Overview
This application tracks highly personal fitness and health data. Privacy and data minimization are core design principles.

## Data Inventory

### 1. Local Only (SwiftData)
- Workout History (Sets, Reps, Weight)
- Custom Routines
- Custom Exercises
- Personal Records (PRs)
- UI Preferences (Theme, Tab selection)

### 2. Synced with HealthKit (On-Device only)
- Completed Workouts (Start/End time, total energy burned if calculated).
- Body Measurements (Weight).
*HealthKit data never leaves the Apple ecosystem unless explicitly permitted by the user.*

### 3. Sent to Apple Watch (WatchConnectivity)
- Active Workout State (Current exercise, current set, rest timer).
- Active Routine definitions.
*Data flows over Bluetooth/Wi-Fi securely via WCSession.*

### 4. Sent to Backend (AI Provider)
Only strictly necessary context is sent to the backend for AI processing.
- **Workout Generation**: Target muscles, equipment, duration, difficulty.
- **Workout Analysis**: Summarized workout metrics (volume, PRs hit, exercise names).
- **Progression**: Exercise history (last 3-5 sessions of a specific exercise).
- **Natural Language**: Raw user string (e.g., "Bench 60x10") and active exercise context.
*No raw HealthKit data, identifying user names, or unrelated history is sent in any single request.*

### 5. Never Collected
- Precise Location Data
- Background Audio
- Passwords (delegated to Sign in with Apple / Authentication Provider)
- Advertising Identifiers (IDFA)

## Minimization Strategies
- AI features are opt-in and require backend authentication.
- HealthKit permissions fail gracefully; the app functions entirely offline without them.
- SwiftData is the single source of truth; network operations are treated as transient transformations.
