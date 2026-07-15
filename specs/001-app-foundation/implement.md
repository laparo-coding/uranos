# Implementation Guidance: App Foundation

**Status**: [TBD]

## Quick Start

[Implementation quick start steps]

## Code Organization

[Code organization guidelines for UranosCore, UranosWatchKit, UranosCLI]

## Glench Action Implementation

### Gesture Detection

- **Gesture Type**: Glench (native watchOS wrist clenching gesture)
- **API**: Register via `UIAccessibility` notifications or `WKGestureRecognizer` subclass
- **Implementation Location**: UranosWatchKit module
- **Hardware**: Detected via accelerometer + gyroscope sensor fusion (no polling required)
- **Handler Pattern**:
  ```swift
  // Register for glench gesture events in UranosWatchKit
  // When glench detected: map to GlenchAction domain model
  // Trigger haptic immediately
  // Queue transmission to Aither
  ```
- **Debounce**: Inherent 500ms minimum duration of wrist clenching prevents rapid spamming
- **Ensure gesture handler is non-blocking and low-latency**

### Timestamp Capture

- Use `Date()` or `Foundation.Date` to capture current system time
- Convert to Unix timestamp (seconds) using `Int(Date().timeIntervalSince1970)`
- Create `TimestampPayload` with unique `actionId` (UUID) for tracking

### Haptic Feedback

- **Timing**: Trigger **immediately** when glench is detected (before transmission)
- **Pattern**: Use `WKInterfaceDevice.current().play(.click)` (tactile click feedback)
- **Placement**: Call haptic in gesture handler BEFORE `AitherAPIClient.transmit()`
- **Graceful Degradation**: Haptic failure does not block transmission
- **Ensure haptic plays regardless of network or API success**
- **No retry on haptic failure**: Single play attempt per glench

## Aither API Integration

### Endpoint

- **Base URL**: `https://api.aither.dev/v1`
- **Endpoint**: `POST /timestamps`
- **Timeout**: 15 seconds (watchOS network conditions)

### Authentication

- Reuse Gaia's authentication pattern (retrieve token from secure storage)
- Token must be injected into `AitherAPIClient` on initialization
- Header: `Authorization: Bearer {token}`
- Handle `401 Unauthorized` responses by clearing auth and requiring re-initialization

### HTTP Client

- Implement `AitherAPIClient` in UranosCore as reusable component
- Use `URLSession` with 15-second timeout
- Serialize `TimestampPayload` to JSON before transmission
- Content-Type header: `application/json`

### Offline Queue

- **Storage**: In-memory FIFO array (`[TimestampPayload]`) in UranosCore
- **Max Size**: 500 entries (enforce during append; drop oldest on overflow)
- **TTL**: No expiry (queue cleared on app termination)
- **Implement `OfflineTimestampQueue` in UranosCore** as simple array-based FIFO
- **Queue Triggers**: Network errors, 5xx responses, timeouts, 429 rate limits
- **Do NOT Queue**: 401/403 (auth failures), 400-404 (client errors)
- **Retry Strategy**: Exponential backoff with intervals [1, 2, 4, 8, 16] seconds (5 retries max)
- **Retry Trigger**: Event-driven on connectivity restoration (via `URLSession` reachability or polling)
- **Total Retry Window**: ~31 seconds per payload before removal
- **Memory Footprint**: ~500 entries × ~500 bytes = ~250KB worst-case (acceptable for watchOS RAM budget)

### Error Handling

- **Log all transmission attempts** with status (pending, sent, failed, retried)
- **Distinguish failure types**:
  - Recoverable: network errors, 429, 5xx → queue for exponential backoff retry
  - Non-recoverable: 401/403 (auth failure) → clear queue, require re-auth
  - Client errors: 400-404 → drop payload immediately
- **For auth failures**: Clear entire offline queue and require re-authentication
- **For transient errors**: Queue for retry with bounded retry count (max 5)
- **Logging details**: timestamp, payload size, HTTP status, retry count, error message

## Testing Strategy

### Unit Tests

- [ ] Test `GlenchAction` creation and validation
- [ ] Test `TimestampPayload` JSON serialization/deserialization
- [ ] Test `AitherAPIClient` with mocked URLSession
- [ ] Test `OfflineTimestampQueue` add, retry, and clear operations
- [ ] Test haptic feedback trigger (mocked in tests)

### Integration Tests

- [ ] Test glench gesture detection → timestamp capture → haptic → queue flow
- [ ] Test offline queue retry when connectivity is simulated
- [ ] Test authentication failure handling
- [ ] Test concurrent glench actions (debouncing)

## Validation Checkpoints

- [ ] Glench gesture detected reliably on Watch (wrist clenching)
- [ ] Timestamp is within ±1 second of actual time
- [ ] Haptic feedback (click) plays immediately on glench (before transmission)
- [ ] Payload transmits successfully to `https://api.aither.dev/v1/timestamps`
- [ ] Failed transmissions queue per retry strategy (exponential backoff [1,2,4,8,16]s)
- [ ] Offline queue in-memory with max 500 entries (oldest dropped on overflow)
- [ ] Queue clears on app termination
- [ ] Queue processes retries on connectivity restoration
- [ ] Authentication errors (401) clear queue and require re-auth
- [ ] Non-retryable errors (400-404) dropped immediately

## Known Limitations

- **Rapid glench debounce**: 500ms minimum between actions (prevent app resource exhaustion)
- **Watch network latency**: 15-second timeout may need tuning based on field testing
- **Queue size limits**: Max 500 entries per watch device (enforced at append time)
- **Battery impact**: Retry polling must use event-driven approach (not background timer)
- **Token lifecycle**: Re-auth required if token expires; cleared payloads cannot be resent
