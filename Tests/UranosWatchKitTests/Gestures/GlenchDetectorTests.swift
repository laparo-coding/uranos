import Foundation
import Testing

@testable import UranosWatchKit

@Suite("GlenchDetector Tests")
struct GlenchDetectorTests {

  // MARK: - Debounce Logic

  @Test("First glench event is accepted")
  func firstGlenchAccepted() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    #expect(detector.onSensorEvent(event))
  }

  @Test("Second glench within 500ms is rejected (debounced)")
  func secondGlenchWithin500msRejected() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First event accepted
    #expect(detector.onSensorEvent(event))

    // Advance time by 300ms (within 500ms window)
    clock.advance(by: 300)

    // Second event rejected
    #expect(!detector.onSensorEvent(event))
  }

  @Test("Glench after 500ms is accepted")
  func glenchAfter500msAccepted() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First event accepted
    #expect(detector.onSensorEvent(event))

    // Advance time by exactly 500ms
    clock.advance(by: 500)

    // Second event accepted (at debounce boundary)
    #expect(detector.onSensorEvent(event))
  }

  @Test("Glench after 600ms is accepted")
  func glenchAfter600msAccepted() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    #expect(detector.onSensorEvent(event))

    clock.advance(by: 600)

    #expect(detector.onSensorEvent(event))
  }

  @Test("Multiple rapid glenches: only first accepted, rest debounced")
  func multipleRapidGlenchesDebounced() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First accepted
    #expect(detector.onSensorEvent(event))

    // 4 rapid events within 500ms — all rejected
    // Each advance is cumulative, so total stays under 500ms
    for ms in [50, 50, 50, 50] {
      clock.advance(by: ms)
      #expect(!detector.onSensorEvent(event))
    }
  }

  @Test("Debounce window is 500ms")
  func debounceWindowIs500ms() {
    #expect(GlenchDetector.debounceWindowMs == 500)
  }

  // MARK: - Reset

  @Test("Reset clears debounce state")
  func resetClearsDebounceState() {
    let clock = MockClock()
    let detector = GlenchDetector(clock: clock)
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    // First event accepted
    #expect(detector.onSensorEvent(event))

    // Reset
    detector.reset()

    // Next event immediately accepted (no debounce)
    #expect(detector.onSensorEvent(event))
  }
}
