# Documentation: App Foundation

**Status**: [TBD]

## Module Architecture

### UranosCore

Shared business logic and domain models for Watch and iPhone companion app.

Key components:
- `GlenchAction`: Assistive gesture detection and handling
- `TimestampPayload`: Data model for timestamp events
- `AitherAPIClient`: HTTP client for Aither API integration
- `OfflineTimestampQueue`: Offline queue management

### UranosWatchKit

watchOS-specific extensions and UI layer.

Key components:
- Glench gesture recognizer
- Haptic feedback triggers
- WatchKit UI state management

### UranosCLI

Development and diagnostic CLI tools.

## Watch Connectivity

[Watch Connectivity integration patterns for future features]

## Glench Action

### Overview

The "glench" is a native watchOS assistive action gesture where the user tenses/clenches
their wrist (with Digital Crown held stationary). This allows Watch users to quickly
send the current timestamp to Aither without navigating menus or using voice commands.

### Gesture Mechanics

- **Definition**: Intentional wrist clenching detected via accelerometer + gyroscope
- **Duration**: Natural wrist clenching takes approximately 500ms
- **Debounce**: Built-in minimum 500ms between actions prevents accidental repeated triggers
- **Accessibility**: Available in watchOS 10+ as native assistive action
- **Activation**: No app configuration needed; works with app in foreground, background, or screen locked

### User Flow

1. User clenches wrist (glench gesture) on Watch
2. Watch immediately plays haptic feedback (tactile "click")
3. App captures current Unix timestamp (seconds precision)
4. App transmits payload to Aither API via HTTPS
5. If transmission succeeds: timestamp logged with success
6. If transmission fails: timestamp queued in-memory for retry with exponential backoff

### Offline Queue Behavior

- **In-Memory Storage**: Queue maintained as FIFO array during app session
- **Queue Capacity**: Max 500 timestamps; oldest dropped on overflow
- **Persistence**: Queue cleared on app termination (not persistent across launches)
- **Retry Window**: ~31 seconds per payload with exponential backoff [1,2,4,8,16]s
- **User Impact**: If app force-closes before retries complete, timestamps in queue are lost
  - User can re-perform glench to retry capturing the same moment
  - Timestamps already sent to Aither are retained on server

### Authentication

Glench transmission requires authentication token configured at app startup.
Uses the same authentication mechanism as Gaia:
- Retrieve token from secure storage (Keychain on Watch)
- Include `Authorization: Bearer {token}` header in Aither API request
- Handle 401 responses by clearing cache and requiring re-authentication

### Timestamp Format

- **Format**: Unix Universal Time (UTC)
- **Precision**: Seconds (integer, no milliseconds)
- **Example**: `1720380913` for 2026-07-13T10:15:13Z
- **Implementation**: `Int(Date().timeIntervalSince1970)`

## Offline Persistence Strategy

### Overview

The offline queue allows timestamp payloads to be held in-memory when the Watch has no connectivity.
All pending payloads are automatically retried when connectivity is restored, using exponential
backoff. Queue is cleared when the app terminates (not persisted across launches).

### Architecture: In-Memory FIFO Queue

**In-Memory Queue Storage**:
- Simple FIFO array: `[TimestampPayload]`
- Maintained in UranosCore throughout app session
- Max 500 entries (oldest dropped on overflow)
- No database or file persistence
- ~250KB worst-case memory footprint (acceptable for watchOS)

### Queue Lifecycle

1. **On Glench**: 
   - Haptic feedback triggered immediately
   - `TimestampPayload` created with unique `actionId`
   - `AitherAPIClient.transmit()` called

2. **On Transmission Success (200 OK)**:
   - Entry logged to diagnostics
   - Removed from pending queue

3. **On Transmission Failure**:
   - Payload appended to in-memory queue
   - Retry count incremented
   - `lastRetryAt` timestamp recorded

4. **On Retry**:
   - Event-driven trigger on connectivity restoration
   - Payloads iterated in FIFO order
   - Exponential backoff: [1, 2, 4, 8, 16] seconds (5 retries max)
   - After 5 failed retries: entry removed from queue

5. **On Auth Failure (401)**:
   - Entire queue cleared (in-memory array reset to empty)
   - User requires re-authentication to resume

6. **On App Termination**:
   - Queue cleared (by design, not persisted)
   - Any pending timestamps lost

### Constraints & Limits

| Constraint | Value | Rationale |
|-----------|-------|-----------|
| Max queue size | 500 entries | Watch memory constraints |
| Persistence | None | In-memory only, cleared on app termination |
| Max retries | 5 attempts | Prevents resource exhaustion |
| Retry intervals | [1, 2, 4, 8, 16] seconds | Exponential backoff, ~31s total |
| Memory footprint | ~250KB worst-case | Acceptable for watchOS RAM budget |

### User Experience Impact

- **Happy path**: Timestamp sent immediately (no queuing)
- **Network failure**: Timestamp queued, retried on connectivity
- **App force-close before retries complete**: Timestamp lost (user can re-perform glench)
- **Timestamps already sent**: Retained on Aither server permanently

### Implementation Checklist

- [ ] Create `OfflineTimestampQueue` as simple `[TimestampPayload]` array
- [ ] Implement `append()` with 500-entry limit enforcement (drop oldest on overflow)
- [ ] Implement retry loop with exponential backoff [1, 2, 4, 8, 16]s
- [ ] Implement connectivity observer (trigger retries on WiFi/LTE restoration)
- [ ] Implement queue clearing on auth failure
- [ ] Verify queue is released on app termination (no memory leaks)
- [ ] Implement auth failure handler (clear queue, reset metadata)
- [ ] Test queue is cleared on app termination
- [ ] Test queue memory usage does not exceed ~250KB worst-case

## Performance Considerations

### Memory

- Keep OfflineTimestampQueue bounded (max 500 entries, ~250KB worst-case)
- Clear processed timestamps promptly
- Monitor memory usage to ensure queue does not grow unbounded

### Battery

- Avoid aggressive retry polling; use event-driven retry on connectivity change
- Debounce rapid glench actions (suggest 100-500ms debounce)
- Minimize network transmissions through batching (if desired in future)

### Background Limits

- Timestamp transmission fits within Watch background task limits
- Monitor battery impact of offline queue retries
- Consider pausing queue during extended offline (>24h)

## Debugging Guide

### Simulator

```bash
xcrun simctl openurl watchsimulator "glench://test"  # Simulate gesture
```

### Physical Device

- Enable Developer Mode on Watch
- Install via Xcode to physical device
- Monitor Xcode logs for authentication/transmission errors

### Diagnostic Output

Log statements to include in implementation:
- Glench action detected (timestamp)
- Transmission attempt (timestamp, payload size)
- Transmission success/failure (HTTP status, error)
- Offline queue state (pending count, next retry time)

## Platform Requirements

- **watchOS**: 11.0 or later
- **iOS**: 18.0 or later (for future iPhone companion app)
- **Swift**: 6.1+
- **Xcode**: 16+
