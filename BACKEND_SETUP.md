# Backend Integration Contract

The iOS app uses an AI-powered fitness engine. The app does NOT communicate with the Gemini API directly. All AI requests route through an authenticated backend.

## Architecture

**iOS Client** $\rightarrow$ **Backend Service** $\rightarrow$ **Gemini / LLM**

### Required Endpoints

All endpoints expect an `Authorization: Bearer <token>` header to authenticate the user and enforce subscription entitlements.

### 1. `POST /v1/ai/chat`
Handles conversational AI coaching.
- **Request Schema**: `AIChatRequest` (messages, context).
- **Response Schema**: `AIChatResponse` (message, optional actions).

### 2. `POST /v1/ai/workout/generate`
Generates a custom workout routine based on user parameters.
- **Request Schema**: `AIWorkoutGenerationRequest` (goals, equipment, duration, difficulty).
- **Response Schema**: `AIGeneratedWorkout` (structured list of exercises, sets, reps).

### 3. `POST /v1/ai/progression`
Analyzes exercise history to recommend weight and rep progression.
- **Request Schema**: `AIProgressionContext` (exercise details, past performance, recent 1RM).
- **Response Schema**: `AIProgressionRecommendation` (suggested weight/reps, confidence, reasoning).

### 4. `POST /v1/ai/workout/analyze`
Analyzes a completed workout for insights.
- **Request Schema**: `AIWorkoutAnalysisContext` (workout summary, sets, PRs).
- **Response Schema**: `AIWorkoutAnalysis` (score, insights, volume metrics).

### 5. `POST /v1/ai/workout/parse`
Parses natural language input into structured workout commands.
- **Request Schema**: `AINaturalLanguageWorkoutRequest` (user text, active workout context).
- **Response Schema**: `AIWorkoutCommand` (addSet, updateWeight, etc.).

### 6. `POST /v1/ai/exercises/substitute`
Suggests exercise alternatives.
- **Request Schema**: `AIExerciseSubstitutionRequest` (original exercise, available equipment, target muscles).
- **Response Schema**: `AIExerciseSubstitutionResponse` (list of valid substitutes).

## Validation & Security
- The backend MUST validate subscription entitlement before routing requests to Gemini.
- The backend MUST strip any PII before forwarding to the LLM.
- The backend MUST enforce rate limits on AI endpoints to control costs.
- The backend should handle timeouts (Gemini API can be slow) and return clear errors (`networkUnavailable`, `timeout`, `quotaExceeded`).
