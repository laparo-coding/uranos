import Foundation

/// Exponential backoff intervals for retrying failed Aither transmissions.
///
/// The intervals are [1, 2, 4, 8, 16] seconds, giving a total maximum delay
/// of 31 seconds across 5 retries.
public enum RetryBackoff: Sendable {

  /// Maximum number of retry attempts per payload.
  public static let maxRetries = 5

  /// The backoff intervals in seconds: [1, 2, 4, 8, 16].
  public static let intervals: [TimeInterval] = [1, 2, 4, 8, 16]

  /// Returns the backoff delay for the given retry count.
  ///
  /// - Parameter retryCount: The current retry count (0-based).
  /// - Returns: The delay in seconds, or `nil` if the maximum retries have been exceeded.
  public static func delay(forRetryCount retryCount: Int) -> TimeInterval? {
    guard retryCount >= 0 && retryCount < intervals.count else { return nil }
    return intervals[retryCount]
  }

  /// Returns the total maximum delay across all retries.
  public static var totalMaximumDelay: TimeInterval {
    intervals.reduce(0, +)
  }
}
