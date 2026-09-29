# App Store Checklist

Ensure the following items are complete before submitting the app for review:

## 1. Metadata and App Store Presence
- [ ] **App Name**: Finalized and localized if needed.
- [ ] **Subtitle**: Catchy, describing the core AI/Workout tracking value.
- [ ] **Description**: Clear explanation of features, subscription details, and Terms of Use.
- [ ] **Keywords**: Relevant fitness, AI, and workout tracking keywords.
- [ ] **Screenshots**: High-quality screenshots demonstrating iOS, watchOS, and Widget features.
- [ ] **Promotional Text**: Optional text for marketing.

## 2. Privacy & Legal
- [ ] **Privacy Policy URL**: Must explicitly mention AI usage and HealthKit data handling.
- [ ] **Support URL**: Functional contact page or email.
- [ ] **Terms of Use**: Apple's Standard EULA or a custom one covering subscription terms.
- [ ] **App Privacy Details**: Correctly filled out in App Store Connect (Data Linked to You, Data Used to Track You, etc.).

## 3. Reviewer Information
- [ ] Provide clear login credentials if the app requires an account.
- [ ] Provide a demo video or detailed notes on how to test HealthKit and Watch integration if the reviewer cannot easily replicate it.
- [ ] Explain the subscription model clearly in the reviewer notes.

## 4. Subscriptions & In-App Purchases
- [ ] All products (Free/Pro) are approved or submitted with the app.
- [ ] Restore Purchases functionality is implemented and visible.
- [ ] Paywall clearly displays terms, price, and duration.

## 5. Final Code Checks
- [ ] Debug logging removed or conditionally compiled out.
- [ ] `MockAIProvider` is completely unreachable in the Release build.
- [ ] No hardcoded API keys or secrets in the codebase.
