# Feature Specification: App Foundation

**Feature Branch**: `001-app-foundation`  
**Created**: 2026-07-13  
**Status**: Draft  
**Input**: Establish Uranos as a VS Code Swift Watch companion app baseline with Speckit artifacts and clear structure.

## Clarifications

### Session 2026-07-13

- Q1: Should network timeout and retry strategy be part of formal spec or left to research/implementation? → A1: Promote to formal requirement. FR-009 adds: "Request timeout is 15 seconds. On network error/429/5xx, retry with exponential backoff [1,2,4,8,16]s (5 retries max). On 401/4xx, clear queue immediately."
- Q2: What fields should the TimestampPayload contain for Aither API? → A2: Minimal payload with `unixTimestamp` (Unix seconds) and `actionId` (UUID string). No deviceId, retryCount, or createdAt in payload.
- Q3: When offline queue reaches 500 entries, what happens to new timestamps? → A3: FIFO overflow—drop oldest entry, add new timestamp to end. Acceptable for transient Watch events; newest captures prioritized.
- Q4: Should rapid consecutive glench actions be debounced? → A4: Yes, 500ms debounce window. Ignore glench events within 500ms of previous valid capture. Single action = single timestamp queued. Prevents accidental double-captures.
- Q5: How should authentication credentials be provided to the app? → A5: Configuration file (.env, gitignored) or Xcode build configuration, matching Gaia pattern. Developer must set token before running app.

## User Scenarios & Testing

### Primary User Story

As a developer working in VS Code, I want Uranos to behave like a clear SwiftPM
workspace with Watch connectivity support, so I can plan features, build locally
for Watch, and run consistent quality gates without ambiguity.

### Acceptance Scenarios: Infrastructure

1. **Given** a fresh checkout of Uranos, **When** a developer opens the workspace,
   **Then** the active root-level project structure is clearly Watch-focused with
   UranosCore (shared logic), UranosWatchKit (Watch UI), and UranosCLI (development
   tools) clearly separated.
2. **Given** a developer starts a new feature, **When** they inspect `specs/`
   and the repository templates, **Then** they find Speckit-compatible Watch/
   VS Code guidance for `spec.md`, `plan.md`, and `tasks.md`.
3. **Given** the Swift Watch baseline is in place, **When** local validation runs,
   **Then** `swift build`, `swift format lint`, and `swift test` succeed for all
   targets.
4. **Given** a developer builds for watchOS, **When** they run the build command,
   **Then** they see clear diagnostics about platform requirements and debugging setup.

### Secondary User Story: Glench Timestamp Action

As a Watch user, I want to perform a "glench" (assistive action) to instantly send
my current timestamp to Aither, so I can capture precise event moments with haptic
confirmation, without needing to open an app or navigate menus.

### Acceptance Scenarios: Glench & Aither Integration

5. **Given** the user performs a glench gesture on the Watch, **When** the action
   is detected, **Then** the Watch sends the current Unix timestamp (seconds precision)
   to Aither's API via HTTP, and the user receives immediate haptic feedback.
6. **Given** a glench action is sent to Aither, **When** the API response is received,
   **Then** the Watch logs the transmission status (success, retry, or failure) and
   updates an in-memory cache with the timestamp state.
7. **Given** the Watch has no connectivity to Aither, **When** a glench is performed,
   **Then** the Watch provides haptic feedback, logs the offline event, and queues
   the timestamp for retry when connectivity is restored.
8. **Given** authentication is required for Aither API access, **When** the app initializes,
   **Then** it uses the same authentication mechanism as Gaia (configured credentials/tokens),
   and authentication failures are reported with clear error messages.

### Edge Cases

- What happens when local macOS machines have different Xcode versions?
- How does the repo handle Watch Connectivity during testing and development?
- What if Watch deployment requires code signing or provisioning profiles?

## Requirements

### Functional Requirements

- **FR-001**: The repository MUST expose a root-level Swift Package Manager
  project as the canonical Uranos implementation surface with watchOS 11+ and
  iOS 18+ targets.
- **FR-002**: The repository MUST provide three clearly separated module targets:
  - `UranosCore`: Shared business logic, domain models, and Watch Connectivity
    coordination logic
  - `UranosWatchKit`: watchOS-specific extensions and UI layer (future SwiftUI views)
  - `UranosCLI`: Development and diagnostic CLI tools
- **FR-003**: The repository MUST provide Speckit-compatible constitution and
  template guidance aligned with a VS Code-first Swift workflow for Watch.
- **FR-004**: The repository MUST provide shared VS Code tasks and CI quality
  gates for Swift build, lint, test, and platform-specific validation.
- **FR-005**: The repository MUST include clear documentation for Watch-specific
  constraints (memory, battery, connectivity, background limits).
- **FR-006**: The repository MUST document the toolchain requirements: Xcode with
  watchOS SDK, Swift 6.1+, and VS Code with swiftlang.swift-vscode extension.
- **FR-007**: The repository MUST establish Watch Connectivity communication
  patterns with clear error handling and data versioning strategy.
- **FR-008**: The app MUST detect the assistive action "glench" (wrist clenching
  via accelerometer/gyroscope) and immediately capture the current Unix timestamp
  in seconds. Implement a 500ms debounce window: ignore glench events that occur
  within 500ms of a previous valid glench capture to prevent accidental double-captures.
- **FR-009**: The app MUST send the captured timestamp to Aither's API endpoint
  via HTTPS with proper authentication (same mechanism as Gaia; Bearer token via
  .env file or Xcode build configuration). Request timeout is 15 seconds. On network
  errors, 429 (rate limit), or 5xx responses, retry with exponential backoff [1, 2, 4, 8, 16]
  seconds (5 retries maximum). On 401 (authentication failure) or 4xx client errors,
  clear the offline queue immediately and do not retry.
- **FR-010**: The app MUST provide immediate haptic feedback to the user when
  a glench action is triggered, before transmission completes.
- **FR-011**: The app MUST implement an in-memory offline queue (max 500 entries)
  for timestamps when Aither is unreachable. When a new timestamp arrives and the
  queue is at capacity, drop the oldest entry (FIFO) and add the new one. When
  connectivity is restored, retry transmission for all queued timestamps using the
  exponential backoff strategy defined in FR-009 (5 retries max, intervals [1, 2, 4, 8, 16]s).
  Queue entries that fail all 5 retries or receive 401/4xx responses are removed immediately.
  Queue is in-memory only and clears on app termination.
- **FR-012**: The app MUST include observable state tracking for timestamp
  transmissions (pending, sent, failed) accessible via logging and diagnostics.

### Key Entities & Patterns

- **ModuleArchitecture**: Describes the separation between UranosCore, UranosWatchKit,
  and UranosCLI, with clear public surface boundaries.
- **WatchConnectivityCoordinator**: Represents the in-memory cache and message
  routing for Watch-iPhone communication (implemented in UranosCore).
- **PlatformConstraints**: Documents watchOS memory limits, battery expectations,
  and background task quotas that govern design decisions.
- **GlenchAction**: Represents the assistive action gesture detected on the Watch;
  captures timestamp and triggers haptic feedback response.
- **TimestampPayload**: Data structure for Aither API transmission containing
  `unixTimestamp` (integer, Unix seconds) and `actionId` (UUID string). Includes
  internal metadata for retry tracking (retryCount, lastRetryAt) but only
  unixTimestamp and actionId are sent in the HTTP POST body.
- **AitherAPIClient**: HTTP client for secure communication with Aither's timestamp
  endpoint; handles authentication (Gaia-compatible), request/response serialization,
  and error recovery.
- **OfflineTimestampQueue**: In-memory queue for timestamps that failed to transmit;
  persists across app lifecycle and retries on connectivity restoration.

## Review & Acceptance Checklist

### Content Quality

- [ ] No implementation details that are irrelevant to user value
- [ ] Focused on developer workflow value and repository clarity
- [ ] Written for repo stakeholders and maintainers
- [ ] All mandatory sections completed

### Requirement Completeness

- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified
- [ ] Security, observability, and failure-state expectations are captured when relevant

## Execution Status

- [ ] User description parsed
- [ ] Spec created
- [ ] Plan created
- [ ] Tasks created
- [ ] Implementation started
- [ ] Implementation completed
- [ ] Acceptance validation passed
