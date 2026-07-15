# Watch Connectivity Contract: App Foundation

## Protocol Overview

Watch-iPhone communication via WatchConnectivity framework with in-memory caching.

## Message Types

[Message types to be defined during implementation]

## Error Handling

[Error handling strategy for connection failures]

## Data Versioning

[Serialization versioning and backward compatibility]

## Sync Debouncing

[Batching and debouncing strategy to preserve battery]

## Implementation Requirements

- [ ] All sync operations are debounced
- [ ] Errors fail explicitly with clear diagnostics
- [ ] Data structures are versioned
- [ ] Cache gracefully handles connection loss

---

# Aither API Contract: App Foundation

## Endpoint Contract

**Base URL**: `https://api.aither.dev/v1`  
**Endpoint**: `POST /timestamps`

**Authentication**: Bearer token (Gaia-compatible)

**Request Header**:
```
Content-Type: application/json
Authorization: Bearer {auth_token}
```

**Request Body Schema**:
```json
{
  "timestamp": 1720380913
}
```

> **Note:** The internal `TimestampPayload` model tracks `unixTimestamp`, `actionId`,
> and retry metadata, but the API request body (`AitherRequestBody`) only sends
> `timestamp` (Unix seconds).

## Response Contract

**Success (200 OK)**:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "received": true,
  "timestamp": 1720380913
}
```

**Authentication Failure (401 Unauthorized)**:
```json
{
  "error": "invalid_token",
  "message": "Authentication failed"
}
```

**Rate Limit (429 Too Many Requests)**:
```json
{
  "error": "rate_limited",
  "retryAfter": 60
}
```

## Retry Strategy

**Exponential Backoff**: 5 retries with intervals [1, 2, 4, 8, 16] seconds

**Retry Conditions**:
- Network errors (timeout, connection refused)
- HTTP 429 (Too Many Requests)
- HTTP 5xx (server errors)

**No Retry (immediate failure)**:
- HTTP 401 (Unauthorized) → clear queue, require re-auth
- HTTP 400-404 (client errors) → drop payload
- HTTP 403 (Forbidden) → clear queue, require re-auth

**Queue Management**:
- Max 500 queue entries (in-memory FIFO)
- No TTL or expiry (queue cleared on app termination)
- Metadata tracked in-memory only

## Implementation Requirements

- [ ] Request serialization matches Aither API spec
- [ ] Authentication tokens are managed securely (matching Gaia pattern)
- [ ] HTTP status codes are handled with appropriate retry strategies
- [ ] Timestamp format is strictly Unix UTC (seconds, no milliseconds)
- [ ] Request timeout is 15 seconds (watchOS network conditions)
- [ ] Failed requests are queued for offline retry
- [ ] Exponential backoff intervals enforced: [1, 2, 4, 8, 16] seconds
