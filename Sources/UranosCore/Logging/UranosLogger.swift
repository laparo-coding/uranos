import Foundation

/// Centralized logging for Uranos.
///
/// Provides a simple logging interface that can route to Rollbar in production
/// or to stdout in development. All critical paths (transmission attempts,
/// authentication errors, queue state) should be logged for observability.
public enum UranosLogger {

  /// Log level for filtering.
  public enum Level: Int, Sendable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: Level, rhs: Level) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  /// Whether logging is enabled.
  public nonisolated(unsafe) static var isEnabled: Bool = true

  /// The minimum log level to output.
  public nonisolated(unsafe) static var minimumLevel: Level = .info

  // MARK: - Logging Methods

  /// Logs a debug message.
  public static func debug(_ message: String, extra: [String: Any] = [:]) {
    log(.debug, message, extra: extra)
  }

  /// Logs an info message.
  public static func info(_ message: String, extra: [String: Any] = [:]) {
    log(.info, message, extra: extra)
  }

  /// Logs a warning message.
  public static func warning(_ message: String, extra: [String: Any] = [:]) {
    log(.warning, message, extra: extra)
  }

  /// Logs an error message.
  public static func error(_ message: String, extra: [String: Any] = [:]) {
    log(.error, message, extra: extra)
  }

  // MARK: - Domain-Specific Logging

  /// Logs a transmission attempt.
  public static func logTransmissionStart(payload: TimestampPayload) {
    info(
      "Aither transmission started",
      extra: [
        "actionId": payload.actionId.uuidString,
        "unixTimestamp": payload.unixTimestamp,
      ]
    )
  }

  /// Logs a successful transmission.
  public static func logTransmissionSuccess(payload: TimestampPayload, statusCode: Int) {
    info(
      "Aither transmission succeeded",
      extra: [
        "actionId": payload.actionId.uuidString,
        "statusCode": statusCode,
      ]
    )
  }

  /// Logs a failed transmission.
  public static func logTransmissionFailure(
    payload: TimestampPayload,
    error: AitherError,
    retryCount: Int
  ) {
    warning(
      "Aither transmission failed",
      extra: [
        "actionId": payload.actionId.uuidString,
        "error": String(describing: error),
        "retryCount": retryCount,
      ]
    )
  }

  /// Logs an authentication error.
  public static func logAuthFailure() {
    error("Aither authentication failed — queue cleared")
  }

  /// Logs the current queue state.
  public static func logQueueState(queue: OfflineTimestampQueue) {
    info(
      "Offline queue state",
      extra: [
        "queueSize": queue.count,
        "maxSize": OfflineTimestampQueue.maxSize,
      ]
    )
  }

  // MARK: - Internal

  private static func log(_ level: Level, _ message: String, extra: [String: Any]) {
    guard isEnabled, level >= minimumLevel else { return }

    let prefix: String
    switch level {
    case .debug:
      prefix = "[DEBUG]"
    case .info:
      prefix = "[INFO]"
    case .warning:
      prefix = "[WARN]"
    case .error:
      prefix = "[ERROR]"
    }

    if extra.isEmpty {
      print("\(prefix) \(message)")
    } else {
      print("\(prefix) \(message) \(extra)")
    }
  }
}
