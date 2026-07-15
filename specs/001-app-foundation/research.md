# Research: App Foundation

**Status**: [TBD]

## Research Topics

### watchOS Platform Constraints

[Research findings on watchOS memory, battery, background limits]

### Watch Connectivity Framework

[Research on WatchConnectivity API, data serialization, error handling]

### SwiftPM Watch Targets

[Research on SwiftPM support for watchOS 11+]

### Glench Assistive Action

Research questions:
- [ ] What is the exact gesture mapping for "glench" in watchOS 11+?
- [ ] What UIKit or SwiftUI API is used to detect glench in Watch apps?
- [ ] Are there rate limiting or debouncing requirements for rapid glench actions?
- [ ] Can glench trigger background tasks or only foreground actions?

### Haptic Feedback on Watch

Research questions:
- [ ] What haptic patterns are available on watchOS 11+?
- [ ] What is the latency between gesture detection and haptic playback?
- [ ] Can haptic play independent of network availability?
- [ ] What battery cost does haptic feedback incur?

### Unix Timestamp Accuracy

Research questions:
- [ ] What is the precision of `Date()` on watchOS (seconds, milliseconds)?
- [ ] How to convert `Date` to Unix timestamp reliably (avoid TZ issues)?
- [ ] Are there NTP sync issues on isolated Watch devices?

### Aither API Integration

Research questions:
- [ ] What is the exact endpoint URL and API version for Aither timestamps?
- [ ] What authentication scheme does Aither use (Bearer tokens, API keys)?
- [ ] Does Aither provide API documentation or OpenAPI spec?
- [ ] What rate limits apply to timestamp submissions?
- [ ] What is the expected response time for timestamp API?

## Findings & Decisions

### Q1: Glench Assistive Action Gesture (CLARIFIED)
- **Decision**: Glench gesture (native watchOS wrist clenching with Digital Crown held stationary)
- **Rationale**: Native assistive action in watchOS 10+, hardware-accelerated via accelerometer, natural debounce (~500ms), user-intentional, works in background
- **Implementation**: Register glench gesture via `UIAccessibility` notifications or `WKGestureRecognizer` subclass for glench events
- **Implications**:
  - Users clench wrist (intentional muscle tensing) to trigger timestamp capture
  - Haptic feedback confirms gesture recognition
  - Minimum 500ms between actions: built-in debounce prevents accidental repeated triggers
  - Works with app in foreground, background, or screen locked

### Q2: Aither API Endpoint & Authentication (CLARIFIED)
- **Decision**: Base URL is `https://api.aither.dev/v1/timestamps`, Bearer token authentication
- **Rationale**: Matches Gaia/Hemera ecosystem patterns, consistent token management
- **Implementation**: 
  - POST endpoint: `https://api.aither.dev/v1/timestamps`
  - Header: `Authorization: Bearer {token}` (token from Gaia secure storage)
  - Content-Type: `application/json`
- **Implications**:
  - No dynamic endpoint discovery needed
  - Token lifecycle managed by Gaia authentication provider
  - API version pinned to v1 in URL path

### Q3: Offline Queue Persistence (CLARIFIED)
- **Decision**: In-memory queue (no persistence across app launches)
- **Rationale**: Simplicity, minimal memory footprint, acceptable for transient offline scenarios; timestamps lost on app force-close/crash
- **Implementation**:
  - In-memory FIFO array: `[TimestampPayload]` in UranosCore
  - Metadata (queue size, last activity) tracked in-memory only
  - No database or UserDefaults persistence
  - Queue cleared on app termination (by design)
- **Recovery**: Queue clears on app termination; user may need to re-perform glench for lost events
  - Max queue size: 500 entries (enforced during append)
- **Implications**:
  - Timestamps lost on app force-close/crash (acceptable for transient scenarios)
  - No database or persistent storage overhead
  - ~250KB worst-case memory footprint (acceptable for watchOS RAM)

### Q4: Haptic Feedback Timing (CLARIFIED)
- **Decision**: Immediate (before transmission attempt)
- **Rationale**: Provides instant tactile confirmation of gesture, independent of network success
- **Implementation**:
  - Trigger haptic in glench handler before calling `AitherAPIClient.transmit()`
  - Use `WKInterfaceDevice.current().play(.click)` or Watch equivalent
  - No retry on haptic failure (graceful degradation)
- **Implications**:
  - Users receive feedback even if transmission fails
  - Haptic plays during network errors, maintaining responsiveness
  - No dependency on API status for UX confirmation

### Q5: Retry Strategy (CLARIFIED)
- **Decision**: 5 retries with exponential backoff: 2^n seconds (1s, 2s, 4s, 8s, 16s)
- **Rationale**: Bounded retries prevent resource exhaustion; exponential backoff reduces thundering herd on recovery
- **Implementation**:
  - Retry intervals: [1, 2, 4, 8, 16] seconds (total ~31s)
  - Retry on: network errors, 429 (rate limit), 5xx (server errors)
  - Do NOT retry on: 401 (auth failure), 400-404 (client errors)
  - Queue entry removed after 5 failed attempts
- **Implications**:
  - Max retry window ~31 seconds per payload
  - Auth failures require user intervention (re-authentication)
  - Failed payloads cleaned up automatically (no TTL)

## Rejected Alternatives

### Q1 Alternatives
- **Finger double-tap**: Rejected (difficult for users with limited dexterity)
- **Wrist flick**: Rejected (unreliable detection, battery-intensive)
- **Voice command**: Rejected (accessibility concern in shared spaces)

### Q3 Alternatives
- **UserDefaults only**: Rejected (size limits, unreliable persistence)
- **SQLite only**: Rejected (slower access for metadata queries)
- **In-memory cache**: Selected — acceptable for transient Watch events; newest captures prioritized over persistence across restarts.

### Q5 Alternatives
- **Linear backoff**: Rejected (higher thundering herd risk)
- **10+ retries**: Rejected (excessive resource usage, poor UX latency)
- **No retries**: Rejected (poor reliability on flaky Watch networks)
