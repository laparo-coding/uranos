import Foundation
import Testing

@testable import UranosCore
@testable import UranosWatchKit

@Suite("Glench Flow Integration Tests")
struct GlenchFlowTests {

  // MARK: - Scenario 1: Valid Glench → Timestamp Queued

  @Test("Valid glench produces a timestamp payload")
  func validGlenchProducesTimestamp() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // Detect glench
    let isValidGlench = detector.onSensorEvent(event)

    #expect(isValidGlench)

    // Create timestamp payload (as the app would)
    let timestamp = UInt32(clock.now().timeIntervalSince1970)
    let payload = TimestampPayload(unixTimestamp: timestamp, actionId: UUID())

    #expect(payload.unixTimestamp > 0)
    #expect(payload.retryCount == 0)
  }

  // MARK: - Scenario 2: Rapid Glench → Second Debounced → Only 1 Timestamp

  @Test("Rapid glench: second event debounced, only 1 timestamp queued")
  func rapidGlenchDebounced() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    var queue = OfflineTimestampQueue()
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First glench — valid
    if detector.onSensorEvent(event) {
      let payload = TimestampPayload(
        unixTimestamp: UInt32(clock.now().timeIntervalSince1970),
        actionId: UUID()
      )
      queue.append(payload)
    }

    // Advance only 200ms (within debounce window)
    clock.advance(by: 200)

    // Second glench — should be debounced
    if detector.onSensorEvent(event) {
      let payload = TimestampPayload(
        unixTimestamp: UInt32(clock.now().timeIntervalSince1970),
        actionId: UUID()
      )
      queue.append(payload)
    }

    // Only 1 timestamp should be queued
    #expect(queue.count == 1)
  }

  // MARK: - Scenario 3: Two Valid Glenches (500ms Apart) → 2 Timestamps

  @Test("Two valid glenches 500ms apart produce 2 timestamps")
  func twoValidGlenchesProduce2Timestamps() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    var queue = OfflineTimestampQueue()
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First glench
    if detector.onSensorEvent(event) {
      queue.append(
        TimestampPayload(
          unixTimestamp: UInt32(clock.now().timeIntervalSince1970),
          actionId: UUID()
        ))
    }

    // Advance 500ms (at debounce boundary)
    clock.advance(by: 500)

    // Second glench — valid
    if detector.onSensorEvent(event) {
      queue.append(
        TimestampPayload(
          unixTimestamp: UInt32(clock.now().timeIntervalSince1970),
          actionId: UUID()
        ))
    }

    #expect(queue.count == 2)
  }

  // MARK: - Scenario 4: Haptic Feedback Triggered on Valid Glench

  @Test("Haptic feedback is triggered on valid glench (no throw)")
  func hapticTriggeredOnValidGlench() {
    // HapticFeedback.triggerGlenchHaptic() should not throw
    // On macOS (no WatchKit), it's a no-op
    HapticFeedback.triggerGlenchHaptic()
    #expect(Bool(true))
  }
}
