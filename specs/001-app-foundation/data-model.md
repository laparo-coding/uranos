# Data Model: App Foundation

**Status**: [TBD]

## Core Entities

### UranosCore Models

[Models defined in UranosCore module]

### GlenchAction

```swift
struct GlenchAction {
  let timestamp: UInt32  // Unix timestamp in seconds
  let actionType: String // "glench"
  let deviceId: String   // Watch device identifier
}
```

### TimestampPayload

```swift
struct TimestampPayload: Codable {
  let unixTimestamp: UInt32       // Current system time (seconds)
  let format: String = "unix-utc" // Fixed format identifier
  let actionId: UUID              // Unique identifier for retry tracking
  let createdAt: Date             // When payload was created
  
  // For retry logic
  var retryCount: Int = 0
  var lastRetryAt: Date?
}
```

### Watch Connectivity Payloads

Data structures for Watch-iPhone communication for future expansion.

## Serialization Strategy

- **TimestampPayload**: JSON encoding for Aither API transmission
- **GlenchAction**: Structured representation for internal processing
- **RetryMetadata**: Tracked in OfflineTimestampQueue for recovery

## Persistence

Offline queue is **in-memory only** (no persistence across app launches):
- Queue maintained in RAM as `[TimestampPayload]` array
- Queue cleared when app terminates (by design)
- Active transmissions tracked in-memory
- No UserDefaults or SQLite storage
- **Memory Footprint**: ~500 entries × ~500 bytes = ~250KB worst-case (acceptable for watchOS)

**Implication**: Timestamps lost if app force-closes or crashes; acceptable for transient offline scenarios.

## Sync Protocol

Watch-iPhone synchronization protocol for future features.

## Aither API Integration

### Endpoint

```
POST https://api.aither.dev/v1/timestamps
Authentication: Bearer {token}  // Gaia-compatible auth
Content-Type: application/json

Request body:
{
  "unixTimestamp": 1720380913,
  "format": "unix-utc",
  "actionId": "550e8400-e29b-41d4-a716-446655440000",
  "createdAt": "2026-07-13T10:15:13Z"
}
```

**Base URL**: `https://api.aither.dev/v1`  
**Request Timeout**: 15 seconds (watchOS network conditions)  
**Retry Strategy**: Exponential backoff [1, 2, 4, 8, 16] seconds (5 retries max)

### Response

- **200 OK**: Timestamp received and logged
- **401 Unauthorized**: Authentication failed
- **429 Too Many Requests**: Retry with exponential backoff
- **5xx Server Error**: Retry with exponential backoff
