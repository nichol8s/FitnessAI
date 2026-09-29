# TestFlight Checklist

Before distributing to external testers via TestFlight, verify the following:

## 1. App Configuration
- [ ] Ensure the app builds successfully in **Release** configuration.
- [ ] Verify the App Icon is set for all required sizes.
- [ ] Verify the Launch Screen is configured and looks correct in Light/Dark mode.
- [ ] Verify the Display Name and Bundle Identifier are final.

## 2. Certificates & Profiles
- [ ] Generate and install an App Store Distribution Certificate.
- [ ] Create an App Store Distribution Provisioning Profile for the main app, watch app, and widget targets.
- [ ] Ensure capabilities in the Apple Developer Portal match the Xcode targets (HealthKit, In-App Purchase, etc.).

## 3. App Store Connect Setup
- [ ] Create a new app record in App Store Connect.
- [ ] Configure In-App Purchases (Product IDs must match `SubscriptionManager` values).
- [ ] Set up the TestFlight group.
- [ ] Add testing instructions for the reviewer (e.g., explaining HealthKit usage).

## 4. Archiving and Upload
- [ ] Set the active scheme destination to "Any iOS Device (arm64)".
- [ ] Product > Archive in Xcode.
- [ ] Validate the archive in the Organizer.
- [ ] Upload to App Store Connect.

## 5. Post-Upload Verification
- [ ] Wait for processing in App Store Connect.
- [ ] Resolve any automated ITMS warnings (e.g., missing usage descriptions).
- [ ] Distribute to internal testers first and verify successful installation.
