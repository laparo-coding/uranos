# Acceptance Checklist: App Foundation

## Functional Requirements: Infrastructure

- [X] FR-001: Root-level SwiftPM project for watchOS 11+ and iOS 18+
- [X] FR-002: Three module targets (UranosCore, UranosWatchKit, UranosCLI) clearly separated
- [X] FR-003: Speckit-compatible constitution and templates
- [X] FR-004: VS Code tasks and CI quality gates
- [X] FR-005: Watch-specific constraints documentation
- [X] FR-006: Toolchain requirements documented
- [X] FR-007: Watch Connectivity communication patterns established

## Functional Requirements: Glench Action & Aither Integration

- [X] FR-008: Glench assistive action detected and captures Unix timestamp (seconds)
- [X] FR-009: Timestamp transmitted to Aither API via HTTPS with authentication
- [X] FR-010: Haptic feedback provided immediately on glench action
- [X] FR-011: Offline queue implemented for failed transmissions with retry logic
- [X] FR-012: Observable state tracking for all timestamp transmissions

## Non-Functional Requirements

- [X] All modules build without errors
- [X] All tests pass
- [X] Code formatting validates with swift-format
- [X] Linting passes
- [X] Documentation is complete
- [X] Memory and performance constraints are respected
- [X] Battery impact minimized (debounced retries, efficient queue)
- [X] Authentication tokens handled securely

## Testing: Glench Action

- [X] Glench gesture reliably detected on Watch
- [X] Timestamp captured within ±1 second of actual time
- [X] Haptic feedback plays immediately (not waiting for network)
- [X] Haptic plays even if transmission fails

## Testing: Aither API Integration

- [X] Payload successfully transmitted to Aither endpoint
- [X] Response parsed correctly (200 OK case)
- [X] Authentication token included in request header
- [X] 401 errors trigger re-authentication flow
- [X] 429 errors trigger exponential backoff retry
- [X] 5xx errors queued for retry

## Testing: Offline Queue

- [X] Failed transmissions queued in-memory
- [X] Queue processed when connectivity restored
- [X] Retry count bounded (max 5 attempts with exponential backoff)
- [X] Queue survives app suspension/resume (same session)
- [X] Queue cleared on app termination (verified)
- [X] Successful transmissions removed from queue immediately
- [X] Queue overflow: oldest entry dropped when max 500 reached

## Testing: Watch Device

- [X] Glench action works on physical Watch (watchOS 11+)
- [X] Glench action works on Watch simulator
- [X] Timestamp format verified (Unix UTC seconds, no milliseconds)
- [X] Haptic feedback audible/tactile on device
- [X] No memory leaks or excessive battery drain observed

## Documentation

- [X] Architecture documented
- [X] API contracts defined
- [X] Development guide complete
- [X] Quick start guide functional
- [X] Aither integration documented with examples
- [X] Authentication setup instructions included
