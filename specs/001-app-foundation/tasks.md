# Tasks: App Foundation (001-app-foundation)

**Feature Branch**: `001-app-foundation`  
**Task Version**: 1.0  
**Last Updated**: 2026-07-13  
**Status**: Ready for Implementation (Test-First)

---

## Task Overview

Total: **22 tasks** across 4 implementation phases + infrastructure setup
- **Phase 0** (Infrastructure): 6 tasks
- **Phase 1** (Domain Models & API): 9 tasks
- **Phase 2** (Glench & Haptic): 4 tasks
- **Phase 3** (Aither Integration): 2 tasks
- **Phase 4** (Observability): 1 task

---

## Dependency Graph

```
Phase 0 (Infrastructure)
├─ T0-1: Verify Package.swift targets
├─ T0-2: Configure VS Code tasks
├─ T0-3: Document platform requirements
└─ T0-4: Setup CI gates

Phase 1 (Domain Models) [depends on Phase 0]
├─ T1-1: Create TimestampPayload struct (Codable)
├─ T1-2: Unit tests: TimestampPayload serialization
├─ T1-3: Create AitherAPIClient
├─ T1-4: Unit tests: AitherAPIClient success (200)
├─ T1-5: Unit tests: AitherAPIClient failures (401/429/5xx/timeout)
├─ T1-6: Create OfflineTimestampQueue struct
├─ T1-7: Unit tests: Queue FIFO overflow
├─ T1-8: Unit tests: Retry backoff calculation
└─ T1-9: Integration test: Queue + mock server end-to-end

Phase 2 (Glench & Haptic) [depends on Phase 0, Phase 1]
├─ T2-1: Create GlenchDetector (accelerometer/gyroscope handler)
├─ T2-2: Unit test: Debounce logic (500ms window)
├─ T2-3: Create HapticFeedback handler
├─ T2-4: Integration test: Glench → Haptic → Queue flow

Phase 3 (Aither Integration) [depends on Phase 1, Phase 2]
├─ T3-1: Create authentication setup (Bearer token from environment)
├─ T3-2: Create connectivity observer + retry coordinator
└─ T3-3: Integration test: Full flow (glench → transmission → success/offline/error)

Phase 4 (Observability) [depends on Phase 3]
└─ T4-1: Add Rollbar logging + CLI diagnostics tools
```

---

## Phase 0: Infrastructure Setup (Prerequisite)

### T0-1: Verify Package.swift Targets

**Status**: [X] Complete
**Dependencies**: None  
**Effort**: 0.5 day  
**Acceptance**:
- [ ] Package.swift lists 3 targets: UranosCore, UranosWatchKit, UranosCLI
- [ ] Each target has correct dependencies (Foundation, WatchKit where needed)
- [ ] `swift build` succeeds for all targets
- [ ] `swift test` runs without errors

**Tasks**:
1. Open Package.swift in VS Code
2. Verify target structure matches architecture (see plan.md D1)
3. Run `swift build` locally
4. Run `swift test` locally
5. Document any build issues in docs/BUILD.md

---

### T0-2: Configure VS Code Tasks

**Status**: [X] Complete
**Dependencies**: T0-1  
**Effort**: 1 day  
**Acceptance**:
- [ ] `.vscode/tasks.json` defines 4 tasks: build, test, format, lint
- [ ] `Cmd+Shift+B` runs build task
- [ ] `swift test` task appears in task list
- [ ] `swift format` and `swift format lint` both work
- [ ] Debug launch configurations for Watch simulator included

**Tasks**:
1. Create `.vscode/tasks.json` with tasks:
   - `swift-build`: `swift build -c debug`
   - `swift-test`: `swift test`
   - `swift-format`: `swift format format -i -r Sources Tests`
   - `swift-lint`: `swift format lint -r Sources Tests`
2. Create `.vscode/launch.json` with Watch simulator debug config
3. Document in docs/DEVELOPMENT.md

---

### T0-3: Document Platform Requirements

**Status**: [X] Complete
**Dependencies**: T0-1  
**Effort**: 0.5 day  
**Acceptance**:
- [ ] README.md includes platform requirements section
- [ ] Requirements list: Xcode 16+, Swift 6.1+, watchOS 11+, iOS 18+
- [ ] Quick start section covers `.env` setup for `AITHER_BEARER_TOKEN`
- [ ] Deployment notes for provisioning profiles + team ID

**Tasks**:
1. Update README.md > Platform Requirements
2. Add .env.example file with AITHER_BEARER_TOKEN placeholder
3. Create docs/WATCHOS-DEPLOYMENT.md with code signing setup

---

### T0-4: Setup CI Gates

**Status**: [X] Complete
**Dependencies**: T0-1, T0-2  
**Effort**: 0.5 day  
**Acceptance**:
- [ ] GitHub Actions workflow or CI config defined
- [ ] Runs `swift build`, `swift test`, `swift format lint`
- [ ] Fails if any gate does not pass
- [ ] Tested locally first

**Tasks**:
1. Create `.github/workflows/swift-ci.yml` with:
   - Build step: `swift build`
   - Test step: `swift test`
   - Lint step: `swift format lint -r Sources Tests`
2. Verify workflow triggers on push to 001-app-foundation branch

---

## Phase 1: Domain Models & API Contracts (Test-First)

### T1-1: Create TimestampPayload Struct

**Status**: [X] Complete  
**Dependencies**: T0-1  
**Effort**: 0.5 day  
**Type**: Implementation (after failing tests)  
**Acceptance**:
- [ ] Struct defined in UranosCore/Models/TimestampPayload.swift
- [ ] Fields: `unixTimestamp: UInt32`, `actionId: UUID`
- [ ] Conforms to `Codable`
- [ ] Includes `retryCount: Int = 0`, `lastRetryAt: Date?` for internal tracking
- [ ] JSON serialization matches Aither contract (unixTimestamp, actionId only in body)

**Test First** (T1-2 → implement this):
- Write failing test: TimestampPayload serializes to JSON with correct fields
- Write failing test: TimestampPayload deserializes from JSON

---

### T1-2: Unit Tests — TimestampPayload Serialization

**Status**: [X] Complete  
**Dependencies**: T0-1  
**Effort**: 0.5 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Test file: `Tests/UranosCoreTests/Models/TimestampPayloadTests.swift`
- [ ] Test case: `testJSONEncoding()` — validates serialized JSON structure
- [ ] Test case: `testJSONDecoding()` — validates deserialization round-trip
- [ ] Tests pass after T1-1 implementation

**Test Code Outline**:
```swift
func testJSONEncoding() {
  let payload = TimestampPayload(unixTimestamp: 1720380913, actionId: UUID())
  let data = try JSONEncoder().encode(payload)
  let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
  XCTAssertEqual(dict?["unixTimestamp"] as? Int, 1720380913)
  XCTAssertNotNil(dict?["actionId"])
}
```

---

### T1-3: Create AitherAPIClient

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-1  
**Effort**: 1.5 days  
**Type**: Implementation (after failing tests T1-4, T1-5)  
**Acceptance**:
- [ ] Class defined: UranosCore/API/AitherAPIClient.swift
- [ ] Initializer: `init(bearerToken: String, timeout: TimeInterval = 15)`
- [ ] Method: `async func transmit(_ payload: TimestampPayload) throws -> AitherResponse`
- [ ] Uses URLSession with Bearer auth header
- [ ] Handles response codes: 200 (success), 401 (auth fail), 429 (rate limit), 5xx (server error)
- [ ] Throws appropriate errors for non-200 responses

**Error Handling**:
- 200 → return success
- 401 → throw AitherError.authenticationFailed
- 429 → throw AitherError.rateLimited
- 5xx → throw AitherError.serverError
- Network timeout → throw AitherError.timeout

---

### T1-4: Unit Tests — AitherAPIClient Success (200)

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-1  
**Effort**: 0.5 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Test file: `Tests/UranosCoreTests/API/AitherAPIClientTests.swift`
- [ ] Test case: `testTransmitSuccess_200OK()` — mocks URLSession, validates request + response
- [ ] Mocked response: HTTP 200 with empty body
- [ ] Validates: Bearer token in Authorization header, JSON payload, Content-Type

**Test Code Outline**:
```swift
func testTransmitSuccess_200OK() async throws {
  let mockSession = MockURLSession(mockResponse: (data: Data(), response: HTTPURLResponse(..., statusCode: 200, ...)))
  let client = AitherAPIClient(bearerToken: "test-token", urlSession: mockSession)
  let payload = TimestampPayload(unixTimestamp: 1720380913, actionId: UUID())
  
  let result = try await client.transmit(payload)
  
  XCTAssertTrue(mockSession.lastRequest?.value.hasPrefix("Bearer test-token") ?? false)
  XCTAssertEqual(result.statusCode, 200)
}
```

---

### T1-5: Unit Tests — AitherAPIClient Failures (401/429/5xx/timeout)

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-1  
**Effort**: 1 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Test cases for each failure mode:
  - `testTransmitFailure_401Unauthorized()`
  - `testTransmitFailure_429RateLimit()`
  - `testTransmitFailure_500ServerError()`
  - `testTransmitFailure_RequestTimeout()`
- [ ] Each throws appropriate AitherError subtype
- [ ] Timeout simulates URLError.timedOut

**Test Coverage**: ≥ 90% of AitherAPIClient code paths

---

### T1-6: Create OfflineTimestampQueue

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-1  
**Effort**: 1 day  
**Type**: Implementation (after failing tests T1-7, T1-8)  
**Acceptance**:
- [ ] Struct defined: UranosCore/Queue/OfflineTimestampQueue.swift
- [ ] Storage: `private var queue: [TimestampPayload]`
- [ ] Method: `mutating func append(_ payload: TimestampPayload)` — enforces max 500 entries (FIFO drop)
- [ ] Method: `mutating func removeFirst() -> TimestampPayload?`
- [ ] Method: `func allPending() -> [TimestampPayload]` — returns current queue snapshot
- [ ] Method: `mutating func clearQueue()` — empties on auth failure
- [ ] Thread-safe (use lock for concurrent access in real code; not required in Phase 1 spike)

---

### T1-7: Unit Tests — Queue FIFO Overflow

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-1, T1-6  
**Effort**: 0.5 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Test file: `Tests/UranosCoreTests/Queue/OfflineTimestampQueueTests.swift`
- [ ] Test case: `testFIFOOverflow_DropOldestAt500Limit()` — add 501 entries, oldest is dropped
- [ ] Validates: new entry added, queue size = 500, oldest entry removed

**Test Code Outline**:
```swift
func testFIFOOverflow_DropOldestAt500Limit() {
  var queue = OfflineTimestampQueue()
  let timestamps = (0..<501).map { _ in TimestampPayload(...) }
  timestamps.forEach { queue.append($0) }
  
  XCTAssertEqual(queue.allPending().count, 500)
  XCTAssertNotEqual(queue.allPending().first?.actionId, timestamps.first?.actionId) // oldest dropped
  XCTAssertEqual(queue.allPending().last?.actionId, timestamps.last?.actionId) // newest added
}
```

---

### T1-8: Unit Tests — Retry Backoff Calculation

**Status**: [X] Complete  
**Dependencies**: T0-1  
**Effort**: 0.5 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Helper function: `func exponentialBackoffInterval(_ retryCount: Int) -> TimeInterval`
- [ ] Returns: 1s, 2s, 4s, 8s, 16s for retryCount 0-4
- [ ] Retrycount ≥ 5 returns error or final value
- [ ] Test validates all 5 intervals

**Test Code Outline**:
```swift
func testExponentialBackoffIntervals() {
  let intervals = [1.0, 2.0, 4.0, 8.0, 16.0]
  for (index, expected) in intervals.enumerated() {
    let actual = exponentialBackoffInterval(index)
    XCTAssertEqual(actual, expected)
  }
}
```

---

### T1-9: Integration Test — Queue + Mock Server End-to-End

**Status**: [X] Complete  
**Dependencies**: T1-3, T1-4, T1-5, T1-6, T1-7, T1-8  
**Effort**: 1 day  
**Type**: Integration Test  
**Acceptance**:
- [ ] Test file: `Tests/UranosCoreTests/Integration/OfflineQueueIntegrationTests.swift`
- [ ] Scenario 1: Transmit success (200) — payload removed from queue
- [ ] Scenario 2: Transmit failure (429) → retry with backoff → success
- [ ] Scenario 3: Auth failure (401) — clears entire queue
- [ ] All scenarios verified via mock URLSession

**Test Outcome**: ≥ 85% coverage of Phase 1 units

---

## Phase 2: Glench Detection & Haptic Feedback (Test-First)

### T2-1: Create GlenchDetector

**Status**: [X] Complete  
**Dependencies**: T0-1  
**Effort**: 1 day  
**Type**: Implementation (after failing tests T2-2)  
**Acceptance**:
- [ ] Class defined: UranosWatchKit/Gestures/GlenchDetector.swift
- [ ] Uses UIAccessibility or WKGestureRecognizer
- [ ] Detects wrist clenching pattern (accelerometer + gyroscope)
- [ ] Maintains state: `lastValidGlenchTime: Date?`
- [ ] Method: `func onSensorEvent(_ event: SensorData) → Bool` — returns true if valid glench (outside debounce window)
- [ ] Debounce: 500ms window (ignore events within 500ms of last valid)

---

### T2-2: Unit Tests — Debounce Logic

**Status**: [X] Complete  
**Dependencies**: T0-1, T2-1  
**Effort**: 0.5 day  
**Type**: Test-First  
**Acceptance**:
- [ ] Test file: `Tests/UranosWatchKitTests/Gestures/GlenchDetectorTests.swift`
- [ ] Test case: `testDebounce_IgnoreWithin500ms()` — second event within 500ms rejected
- [ ] Test case: `testDebounce_AcceptAfter500ms()` — third event after 500ms accepted
- [ ] Uses mock time (or waits with expectation in real test)

**Test Code Outline**:
```swift
func testDebounce_IgnoreWithin500ms() {
  let detector = GlenchDetector()
  let event1 = SensorData(...) // valid glench
  let event2 = SensorData(...) // within 500ms
  
  XCTAssertTrue(detector.onSensorEvent(event1))  // first accepted
  XCTAssertFalse(detector.onSensorEvent(event2)) // second rejected (debounced)
}
```

---

### T2-3: Create HapticFeedback Handler

**Status**: [X] Complete  
**Dependencies**: T0-1  
**Effort**: 0.5 day  
**Type**: Implementation (no test-first complexity)  
**Acceptance**:
- [ ] Function: `func triggerGlenchHaptic()`
- [ ] Uses `WKInterfaceDevice.current().play(.click)`
- [ ] Called immediately on valid glench (before transmission)
- [ ] Handles gracefully if haptic unavailable (no error thrown)

---

### T2-4: Integration Test — Glench → Haptic → Queue Flow

**Status**: [X] Complete  
**Dependencies**: T2-1, T2-2, T2-3, T1-6  
**Effort**: 1 day  
**Type**: Integration Test (Watch simulator)  
**Acceptance**:
- [ ] Test file: `Tests/UranosWatchKitTests/Integration/GlenchFlowTests.swift`
- [ ] Scenario 1: Valid glench → haptic triggered → timestamp queued
- [ ] Scenario 2: Rapid glench (500ms apart) → second debounced → only 1 timestamp queued
- [ ] Mocks: haptic device, gesture detector, queue
- [ ] Validates: queue contains exactly 1 entry after scenario 1 + 2

---

## Phase 3: Aither Integration (End-to-End)

### T3-1: Create Authentication Setup

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-3  
**Effort**: 0.5 day  
**Type**: Implementation  
**Acceptance**:
- [ ] Function: `func loadBearerToken() throws → String`
- [ ] Reads from environment variable `AITHER_BEARER_TOKEN`
- [ ] Throws error if not present: `AitherError.missingAuthToken`
- [ ] Called at app startup
- [ ] Token passed to AitherAPIClient initializer
- [ ] Logged at startup (via Rollbar, Phase 4)

**Error Handling**: Fail-fast if token missing; provide clear error message.

---

### T3-2: Create Connectivity Observer + Retry Coordinator

**Status**: [X] Complete  
**Dependencies**: T0-1, T1-3, T1-6  
**Effort**: 1.5 days  
**Type**: Implementation  
**Acceptance**:
- [ ] Class: UranosCore/Connectivity/ConnectivityObserver.swift
- [ ] Monitors network status changes (uses NWPathMonitor or similar)
- [ ] On connectivity restoration, triggers queue retry
- [ ] Method: `func onConnectivityRestored()` → retry all pending payloads with backoff
- [ ] Method: `func retryQueue()` — iterates queue, transmits each payload
- [ ] Respects exponential backoff intervals from T1-8

**Logic**:
```
For each pending payload in queue:
  - Calculate delay based on retryCount and backoff intervals
  - Schedule transmission after delay
  - On success (200): remove from queue, log
  - On 401: clear entire queue, stop retry
  - On 429/5xx: increment retryCount, reschedule
  - On 5+ retries: remove from queue
```

---

### T3-3: Integration Test — Full End-to-End Flow

**Status**: [X] Complete  
**Dependencies**: T3-1, T3-2, T2-4  
**Effort**: 1.5 days  
**Type**: Integration Test (Watch simulator + mock Aither server)  
**Acceptance**:
- [ ] Test file: `Tests/Integration/EndToEndTests.swift`
- [ ] Scenario 1 (Happy Path): Glench → haptic → transmit → 200 OK → queue empty
- [ ] Scenario 2 (Offline): Glench → no connectivity → queued → connectivity restored → retry succeeds
- [ ] Scenario 3 (Auth Fail): Glench → transmit → 401 → queue cleared → require re-auth
- [ ] Scenario 4 (Rate Limit): Glench → 429 → queued → retry after backoff → success
- [ ] Scenario 5 (Timeout): Glench → 15s timeout → queued → retry → success

**Mock Server**: MockURLSession with configurable responses per scenario

**Coverage**: ≥ 85% of end-to-end logic

---

## Phase 4: Observability & Diagnostics

### T4-1: Add Rollbar Logging + CLI Diagnostics Tools

**Status**: [X] Complete  
**Dependencies**: T3-3  
**Effort**: 1 day  
**Type**: Implementation + CLI  
**Acceptance**:
- [ ] Import Rollbar SDK (if available in Package.swift dependencies)
- [ ] Log all transmission attempts: start, success, failure, retry
- [ ] Log authentication errors with context
- [ ] Log queue state at startup/shutdown
- [ ] CLI commands implemented in UranosCLI target:
  - `swift run UranosCLI queue-inspect` → display pending payloads
  - `swift run UranosCLI queue-clear` → force-clear queue (dev-only)
  - `swift run UranosCLI show-config` → verify AITHER_BEARER_TOKEN present

**Rollbar Integration**:
```swift
serverInstance.error(
  "Aither transmission failed",
  extra: ["statusCode": 429, "retryCount": 2, "queueSize": 25]
)
```

---

## Task Dependency Matrix

| Task | Depends On | Blocks | Phase | Effort |
|------|-----------|--------|-------|--------|
| T0-1 | None | T0-2, T0-4, T1-1...T1-9 | 0 | 0.5d |
| T0-2 | T0-1 | T0-4 | 0 | 1d |
| T0-3 | T0-1 | None | 0 | 0.5d |
| T0-4 | T0-1, T0-2 | None | 0 | 0.5d |
| T1-1 | T0-1 | T1-2 | 1 | 0.5d |
| T1-2 | T0-1 | T1-1 | 1 | 0.5d |
| T1-3 | T0-1, T1-1 | T1-4, T1-5, T1-9 | 1 | 1.5d |
| T1-4 | T0-1, T1-1 | T1-9 | 1 | 0.5d |
| T1-5 | T0-1, T1-1 | T1-9 | 1 | 1d |
| T1-6 | T0-1, T1-1 | T1-7, T1-8, T1-9 | 1 | 1d |
| T1-7 | T0-1, T1-1, T1-6 | T1-9 | 1 | 0.5d |
| T1-8 | T0-1 | T1-9 | 1 | 0.5d |
| T1-9 | T1-3...T1-8 | T3-3 | 1 | 1d |
| T2-1 | T0-1 | T2-2 | 2 | 1d |
| T2-2 | T0-1, T2-1 | T2-4 | 2 | 0.5d |
| T2-3 | T0-1 | T2-4 | 2 | 0.5d |
| T2-4 | T2-1, T2-2, T2-3, T1-6 | T3-3 | 2 | 1d |
| T3-1 | T0-1, T1-3 | T3-2, T3-3 | 3 | 0.5d |
| T3-2 | T0-1, T1-3, T1-6 | T3-3 | 3 | 1.5d |
| T3-3 | T3-1, T3-2, T2-4 | T4-1 | 3 | 1.5d |
| T4-1 | T3-3 | None | 4 | 1d |

---

## Implementation Schedule (Critical Path)

**Critical Path (longest dependency chain)**:
- T0-1 (0.5d) → T1-1 (0.5d) → T1-2 (0.5d) → T1-3 (1.5d) → T1-9 (1d) → T3-3 (1.5d) → T4-1 (1d)
- **Critical path total: ~7 days**

**Parallelizable tasks** (non-blocking):
- T0-2, T0-3, T0-4 can start after T0-1
- T1-4, T1-5 can start after T1-3 (not blocked by T1-2, T1-6, T1-7, T1-8)
- T2-1, T2-3 can start early (Phase 2 after Phase 0)

**Optimized Schedule** (with parallelization):
- **Day 1**: T0-1, T0-2, T0-3 (parallel)
- **Day 2**: T0-4, T1-1, T1-2, T2-1 (parallel)
- **Days 3-4**: T1-3, T1-4, T1-5 (parallel); T2-2, T2-3 (parallel)
- **Days 5-6**: T1-6, T1-7, T1-8 (mostly sequential); T2-4
- **Day 7**: T1-9, T3-1
- **Days 8-9**: T3-2, T3-3 (parallel possible)
- **Day 10**: T4-1

**Total: ~8-10 days** (vs. 16+ days sequential)

---

## Acceptance Criteria by Phase

### Phase 0 Acceptance
- ✅ `swift build && swift test && swift format lint` all pass
- ✅ VS Code tasks functional (Cmd+Shift+B builds, task list shows test/format/lint)
- ✅ README and CI gates documented

### Phase 1 Acceptance
- ✅ All unit tests pass (T1-2, T1-4, T1-5, T1-7, T1-8)
- ✅ Integration test passes (T1-9)
- ✅ Code coverage ≥ 85% for UranosCore models/API/queue
- ✅ No TODO markers in code

### Phase 2 Acceptance
- ✅ Glench detection tests pass (T2-2, T2-4)
- ✅ Haptic feedback functional
- ✅ Debounce working (no duplicate timestamps in 500ms window)

### Phase 3 Acceptance
- ✅ End-to-end integration test passes (T3-3, all 5 scenarios)
- ✅ Auth token loaded correctly at startup
- ✅ Connectivity observer triggers retries
- ✅ All error codes (200/401/429/5xx) handled correctly

### Phase 4 Acceptance
- ✅ Rollbar logging functional (errors appear in Rollbar dashboard)
- ✅ CLI tools work (`swift run UranosCLI queue-inspect`, etc.)
- ✅ No console.error calls (Rollbar only, per constitution)

---

## Constitution Alignment Checklist

- ✅ **Spec-First**: Specification complete (spec.md) before any code
- ✅ **Test-First**: All tasks follow "write failing test → implement → pass"
- ✅ **VS Code-First**: Tasks use VS Code, swift build, swift test (no Xcode IDE required)
- ✅ **Swift 6.1+**: All code targets Swift 6.x (package targets)
- ✅ **SwiftPM**: Package.swift is authoritative (no Xcode project files)
- ✅ **Rollbar over console.error**: Logging via Rollbar serverInstance (T4-1)

---

## Next Steps

1. ✅ Spec complete (5 clarifications resolved)
2. ✅ Plan complete (design decisions, phases, risks)
3. ✅ **Tasks complete** (this document — 22 dependency-ordered tasks)
4. 🚀 **Implementation ready** — Follow tasks.md, test-first discipline

**To begin implementation**:
```bash
cd /Users/Andreas/GitHub/uranos
# Start with Phase 0 (Infrastructure)
swift build    # Verify builds
swift test     # Verify tests run
# Then proceed to T0-1 → T0-2 → ... → T4-1 following task list
```

**Suggested editor commands**:
- Use VS Code with swiftlang.swift-vscode extension
- Run `swift build` and `swift test` via VS Code terminal or tasks (Cmd+Shift+B)
- Keep tasks.md open for checklist tracking
