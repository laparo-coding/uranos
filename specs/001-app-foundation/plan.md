# Implementation Plan: App Foundation (001-app-foundation)

**Feature Branch**: `001-app-foundation`  
**Plan Version**: 1.0  
**Last Updated**: 2026-07-13  
**Status**: Ready for Task Decomposition

---

## Executive Summary

Uranos 001-app-foundation establishes a Swift watchOS 11+ companion app with:
1. **Infrastructure baseline** (SwiftPM, modules, VS Code tasks, CI gates)
2. **Glench gesture detection** (wrist clenching via accelerometer/gyroscope)
3. **Timestamp capture** (Unix seconds, immediate, 500ms debounce)
4. **Aither integration** (HTTPS POST, Bearer auth, 15s timeout, retry backoff)
5. **Offline queue** (in-memory FIFO, max 500 entries, exponential backoff [1,2,4,8,16]s)

**Key Constraint**: In-memory queue only; no SQLite/UserDefaults persistence. Queue clears on app termination.

---

## Design Decisions

### D1: Module Architecture (SwiftPM 3-module structure)

**Decision**: Three separate targets (UranosCore, UranosWatchKit, UranosCLI)

**Rationale**:
- **UranosCore**: Shared business logic, domain models, offline queue, API clients, Watch Connectivity coordination
- **UranosWatchKit**: watchOS UI extensions, glench gesture detection, haptic feedback
- **UranosCLI**: Development tools, diagnostics, queue introspection
- Allows independent testing and future iOS companion app reuse

**Trade-offs**: Slightly more build complexity; enforces boundaries that prevent tight coupling.

---

### D2: Glench Gesture Detection (Accelerometer + Gyroscope)

**Decision**: Use UIAccessibility or WKGestureRecognizer to detect wrist clenching pattern

**Rationale**:
- Wrist clenching is natural assistive action on Watch
- Built-in ~500ms debounce at hardware level (accelerometer/gyroscope sampling)
- Works foreground, background, locked screen (within watchOS limits)
- More reliable than Digital Crown long-press

**Implementation Detail**: 
- Add 500ms software debounce in UranosWatchKit to prevent accidental double-captures
- Timestamp captured synchronously at gesture trigger point

---

### D3: Offline Queue Design (In-Memory FIFO)

**Decision**: Simple `[TimestampPayload]` array in RAM, no persistence

**Rationale**:
- Glench captures are transient events (timestamps, not critical data)
- Queue persists across retries within single app session
- Loss on app force-close acceptable for assistive actions
- Reduces complexity (no SQLite, no UserDefaults layer)
- ~250KB worst-case memory (500 entries × ~500 bytes)

**Trade-off**: Timestamps lost on app crash. User can re-perform glench if needed.

**Overflow Behavior**: FIFO—drop oldest entry when new timestamp arrives at 500-entry limit.

---

### D4: Authentication via Environment/Build Config

**Decision**: Bearer token from `.env` file (gitignored) or Xcode build settings

**Rationale**:
- Matches Gaia pattern (Clerk credentials via environment)
- Prevents accidental token commits
- Works for local development + CI/CD automation
- Developer responsibility to configure before running

**Implementation**: 
- Read `AITHER_BEARER_TOKEN` at app startup
- Store in memory (not persisted to UserDefaults)
- Clear on 401 response (authentication failure)

---

### D5: Retry Strategy with Exponential Backoff

**Decision**: 5 retries max, intervals [1, 2, 4, 8, 16] seconds (~31s total)

**Rationale**:
- Bounded retries prevent resource exhaustion
- Exponential backoff reduces thundering herd on connectivity recovery
- Differentiates retry-worthy (5xx, 429) vs. non-retry (401, 4xx)
- 401 auth failures clear entire queue (require re-auth)

**Network Edge Cases**:
- 15s timeout per request (watchOS network conditions)
- 5xx/429: queue and retry
- 4xx/401: drop payload or clear queue
- No retry on network unreachable (relies on connectivity observer)

---

## Architecture Overview

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ watchOS App (UranosWatchKit)                            │
│                                                         │
│  User Glench                                            │
│       │                                                 │
│       ▼                                                 │
│  ┌─ Gesture Detection (500ms debounce)                  │
│  │                                                     │
│  ├─ Capture Unix Timestamp (Date)                       │
│  │                                                     │
│  ├─ Haptic Feedback (immediate)                         │
│  │                                                     │
│  └─ Pass to UranosCore (AitherAPIClient)                │
│                                                         │
└─────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│ UranosCore (Business Logic)                             │
│                                                         │
│  AitherAPIClient                                        │
│  ├─ Prepare TimestampPayload                            │
│  │  (unixTimestamp, actionId)                           │
│  │                                                     │
│  ├─ POST https://api.aither.dev/v1/timestamps           │
│  │  (Bearer auth, 15s timeout)                          │
│  │                                                     │
│  └─ Response Handler                                    │
│     ├─ 200 OK  → Log, remove from queue                 │
│     ├─ 401/4xx → Clear queue, require re-auth           │
│     └─ 429/5xx → Queue for retry                        │
│                                                         │
│  OfflineTimestampQueue                                  │
│  ├─ Maintain FIFO array (max 500)                       │
│  ├─ Retry on connectivity restoration                   │
│  │  (exponential backoff [1,2,4,8,16]s, max 5)          │
│  │                                                     │
│  └─ Clear on app termination                            │
│                                                         │
│  WatchConnectivityCoordinator                           │
│  └─ (In-memory cache for Watch-iPhone sync)             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Module Dependencies

```
UranosWatchKit
  ├─ depends on UranosCore
  └─ uses WatchKit, UIAccessibility, Foundation

UranosCore
  └─ uses Foundation (URLSession, Date, UUID)

UranosCLI
  └─ depends on UranosCore
```

---

## Implementation Phases

### Phase 0: Infrastructure Setup (Prerequisite)

**Outcome**: Buildable Swift package with 3 targets, VS Code tasks, CI gates

**Tasks**:
- [ ] Verify Package.swift has UranosCore, UranosWatchKit, UranosCLI targets
- [ ] Verify `swift build` succeeds for all targets
- [ ] Verify `swift test` runs for all targets
- [ ] Configure VS Code tasks: build, test, format, lint
- [ ] Document watchOS deployment prerequisites (provisioning profiles, team ID)
- [ ] Document platform requirements in README (Xcode 16+, Swift 6.1+, watchOS 11+, iOS 18+)

**Acceptance**: `swift build && swift test && swift format lint` all pass.

---

### Phase 1: Domain Model & API Contracts (Test-First)

**Outcome**: Testable data structures and Aither API contract

**Units**:
1. **TimestampPayload** (Codable struct)
   - Fields: unixTimestamp (UInt32), actionId (UUID)
   - JSON serialization for Aither API

2. **AitherAPIClient** (HTTP client)
   - Endpoint: `https://api.aither.dev/v1/timestamps`
   - Authentication: Bearer token (from environment)
   - Request timeout: 15 seconds
   - Response handling: 200/401/4xx/5xx cases

3. **OfflineTimestampQueue** (FIFO array)
   - append(payload) with 500-entry overflow (FIFO drop)
   - retry logic with exponential backoff [1,2,4,8,16]s (5 max)
   - clearQueue() on auth failure

**Tests**:
- [ ] Unit: TimestampPayload serialization (JSON round-trip)
- [ ] Unit: AitherAPIClient mock success (200 response)
- [ ] Unit: AitherAPIClient mock failures (401, 429, 5xx, timeout)
- [ ] Unit: OfflineTimestampQueue FIFO overflow (500+ entries)
- [ ] Unit: Retry backoff calculation (exponential sequence)
- [ ] Integration: End-to-end offline queue with mock server

**Acceptance**: All unit + integration tests pass; coverage ≥ 85%.

---

### Phase 2: Glench Detection & Haptic Feedback (Test-First)

**Outcome**: Watchable glench gesture detection with debounce + haptic

**Units**:
1. **GlenchDetector** (accelerometer/gyroscope handler)
   - Detects wrist clenching pattern
   - 500ms debounce window (ignore rapid re-triggers)
   - Passes valid glench events to callback

2. **HapticFeedback** (immediate feedback)
   - Trigger `.click` haptic on valid glench
   - Called before network transmission

**Tests**:
- [ ] Unit: Debounce logic (rapid events within 500ms filtered)
- [ ] Unit: Single glench event (timestamp captured correctly)
- [ ] Unit: Haptic feedback trigger (WKInterfaceDevice mock)
- [ ] Integration: Glench → Haptic → Queue flow (simulator)

**Acceptance**: Glench detected reliably; haptic plays immediately; debounce works.

---

### Phase 3: Aither Integration (End-to-End)

**Outcome**: Working glench → timestamp → Aither transmission

**Units**:
1. **GlenchAction Handler** (orchestrator)
   - On glench: capture timestamp, trigger haptic, queue payload, transmit
   - On success: log, remove from queue
   - On failure: retry per strategy

2. **Authentication Setup**
   - Read AITHER_BEARER_TOKEN from environment
   - Validate token present at startup
   - Include in every Aither request header

3. **Connectivity Observer**
   - Monitor network status changes
   - Trigger queue retry processing on connectivity restoration

**Tests**:
- [ ] Integration: Full flow (glench → haptic → transmission → success)
- [ ] Integration: Offline scenario (queue → connectivity restore → retry)
- [ ] Integration: Auth failure (401 → clear queue)
- [ ] Integration: Rate limit (429 → retry with backoff)
- [ ] Integration: Timeout (15s exceeded → retry)

**Acceptance**: End-to-end happy path + offline + error paths all working.

---

### Phase 4: Observability & Diagnostics

**Outcome**: Logging, queue inspection, debug CLI

**Units**:
1. **Rollbar Integration** (serverInstance.error pattern)
   - Log transmission attempts (start, success, failure, retry)
   - Log authentication errors with context
   - Log offline queue state on startup/shutdown

2. **Queue Diagnostics**
   - CLI command: `swift run UranosCLI queue-inspect` → show pending payloads
   - CLI command: `swift run UranosCLI queue-clear` → force-clear queue
   - CLI command: `swift run UranosCLI show-config` → verify auth token present

**Tests**:
- [ ] Unit: Logging format + Rollbar serialization
- [ ] Unit: CLI commands parse arguments correctly
- [ ] Integration: CLI reads live queue state

**Acceptance**: Logs appear in Rollbar; CLI tools functional.

---

## Implementation Schedule

| Phase | Duration | Effort | Start | End | Blocking Dependencies |
|-------|----------|--------|-------|-----|----------------------|
| 0 | 1 day | Low | 2026-07-14 | 2026-07-14 | None |
| 1 | 2 days | Medium | 2026-07-15 | 2026-07-16 | Phase 0 |
| 2 | 2 days | Medium | 2026-07-17 | 2026-07-18 | Phase 0 |
| 3 | 2 days | High | 2026-07-19 | 2026-07-20 | Phase 1, 2 |
| 4 | 1 day | Low | 2026-07-21 | 2026-07-21 | Phase 3 |
| **Total** | **8 days** | **Medium** | **2026-07-14** | **2026-07-21** | — |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Glench detection unreliable** | Medium | High | Early spike with accelerometer/gyroscope; test on real Watch device early |
| **Aither API endpoint changed** | Low | High | Verify endpoint + schema with Aither team before Phase 3 |
| **Network timeout too aggressive** | Medium | Medium | Test on slow networks; consider 20s timeout if 15s fails consistently |
| **Auth token missing at runtime** | Low | High | Fail-fast at app startup; log clearly; document `.env` setup in quickstart |
| **Queue memory exhaustion** | Low | Medium | Set limit to 250 entries if 500 causes issues; monitor with CLI |
| **Offline queue lost on force-close** | Low | Low | Document known limitation; acceptable for assistive action use case |
| **Retry backoff intervals too fast** | Low | Medium | Adjust [1,2,4,8,16] if Aither rate-limits observed |

---

## Success Criteria

### Functional

- ✅ Glench detected reliably on Watch (watchOS 11+ simulator + device)
- ✅ Timestamp sent to Aither API within 1s of glench (happy path)
- ✅ Haptic feedback plays immediately (before network response)
- ✅ Offline queue queues + retries on connectivity loss/restoration
- ✅ 401 auth failure clears queue without retry
- ✅ Max 500 queue entries enforced (FIFO overflow)
- ✅ 500ms debounce prevents duplicate captures

### Non-Functional

- ✅ Build passes: `swift build`, `swift test`, `swift format lint`
- ✅ Test coverage ≥ 85% (domain logic + API clients)
- ✅ Memory footprint: offline queue ≤ 250KB (worst-case)
- ✅ Battery: no polling (event-driven retry only)
- ✅ Logging: all critical paths logged to Rollbar

### Documentation

- ✅ Constitution alignment verified (Spec-First, Test-First, VS Code-First)
- ✅ README includes platform requirements and watchOS deployment notes
- ✅ Quickstart guide covers authentication token setup
- ✅ API contracts documented (Aither endpoint, payload schema)

---

## Dependencies & Assumptions

### External Dependencies

- **Aither API** (`https://api.aither.dev/v1/timestamps`)
  - Assumes endpoint exists and accepts JSON POST with Bearer auth
  - Expected response: 200 (success), 401 (auth fail), 429 (rate limit), 5xx (server error)

### Assumptions

- Developers have Xcode 16+ with watchOS 11+ SDK
- `AITHER_BEARER_TOKEN` environment variable or build config available
- watchOS simulator supports accelerometer/gyroscope event simulation
- Gaia authentication pattern (Bearer tokens) applicable to Aither

### Not In Scope (Future)

- iOS companion app (Uranos Watch app only in Phase 1)
- Watch Connectivity (WatchConnectivityCoordinator in UranosCore for future use)
- SQLite persistence (in-memory only, by design)
- Event batching or aggregation
- Analytics or custom metrics beyond Rollbar

---

## Next Steps

1. ✅ **Spec complete** (5 clarifications resolved)
2. ✅ **Plan complete** (this document)
3. 📋 **Task decomposition** → Generate `tasks.md` with dependency-ordered implementation tasks
4. 🚀 **Implementation** → Follow tasks.md, test-first discipline per constitution
5. ✅ **Acceptance** → Validate against acceptance criteria

**Suggested command**: `@speckit.tasks` to generate task.md
