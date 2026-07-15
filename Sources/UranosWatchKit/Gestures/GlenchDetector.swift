import Foundation

/// Detects "glench" (wrist clenching) gestures from accelerometer/gyroscope data.
///
/// Implements a 500ms debounce window to prevent accidental double-captures.
/// A glench event is only considered valid if it occurs at least 500ms after
/// the previous valid glench.
public final class GlenchDetector: @unchecked Sendable {

  /// The debounce window in milliseconds.
  public static let debounceWindowMs: Int = 500

  private var lastValidGlenchTime: Date?
  private let clock: ClockProtocol

  /// Creates a glench detector with the given clock.
  ///
  /// - Parameter clock: The clock to use for time measurements (defaults to system clock).
  public init(clock: ClockProtocol = SystemClock()) {
    self.clock = clock
  }

  /// Processes a sensor event and determines if it represents a valid glench.
  ///
  /// A glench is valid only if it occurs outside the debounce window (500ms)
  /// of the previous valid glench.
  ///
  /// - Parameter event: The sensor data from accelerometer/gyroscope.
  /// - Returns: `true` if the glench is valid (outside debounce window), `false` otherwise.
  public func onSensorEvent(_ event: SensorData) -> Bool {
    let now = clock.now()

    if let lastValidGlenchTime {
      let elapsedMs = Int(now.timeIntervalSince(lastValidGlenchTime) * 1000)
      if elapsedMs < Self.debounceWindowMs {
        return false
      }
    }

    lastValidGlenchTime = now
    return true
  }

  /// Resets the detector state, clearing the last valid glench time.
  public func reset() {
    lastValidGlenchTime = nil
  }
}

// MARK: - Sensor Data

/// Raw sensor data from accelerometer and gyroscope.
public struct SensorData: Sendable, Equatable {

  /// Accelerometer X-axis value (in g).
  public let accelerometerX: Double

  /// Accelerometer Y-axis value (in g).
  public let accelerometerY: Double

  /// Accelerometer Z-axis value (in g).
  public let accelerometerZ: Double

  /// Gyroscope X-axis value (in rad/s).
  public let gyroscopeX: Double

  /// Gyroscope Y-axis value (in rad/s).
  public let gyroscopeY: Double

  /// Gyroscope Z-axis value (in rad/s).
  public let gyroscopeZ: Double

  public init(
    accelerometerX: Double,
    accelerometerY: Double,
    accelerometerZ: Double,
    gyroscopeX: Double,
    gyroscopeY: Double,
    gyroscopeZ: Double
  ) {
    self.accelerometerX = accelerometerX
    self.accelerometerY = accelerometerY
    self.accelerometerZ = accelerometerZ
    self.gyroscopeX = gyroscopeX
    self.gyroscopeY = gyroscopeY
    self.gyroscopeZ = gyroscopeZ
  }
}

// MARK: - Clock Protocol

/// Protocol abstraction over time for testability.
public protocol ClockProtocol: Sendable {
  func now() -> Date
}

/// System clock implementation.
public struct SystemClock: ClockProtocol {
  public init() {}

  public func now() -> Date {
    Date()
  }
}

/// Mock clock for testing with controllable time.
public final class MockClock: ClockProtocol, @unchecked Sendable {
  private var currentTime: Date

  public init(startingAt time: Date = Date(timeIntervalSince1970: 1_720_380_913)) {
    self.currentTime = time
  }

  public func now() -> Date {
    currentTime
  }

  public func advance(by milliseconds: Int) {
    currentTime = currentTime.addingTimeInterval(TimeInterval(milliseconds) / 1000)
  }

  public func setTime(_ time: Date) {
    currentTime = time
  }
}
