import Foundation

/// Internal payload model representing a captured glench timestamp.
///
/// Stores the raw event data (`unixTimestamp` and `actionId`) along with
/// internal retry metadata. Note: the Aither API request body (`AitherRequestBody`)
/// only sends `timestamp` — this model is the internal representation used
/// for queueing, retry tracking, and diagnostics.
public struct TimestampPayload: Codable, Sendable, Equatable {

  /// Unix timestamp in seconds precision.
  public let unixTimestamp: UInt32

  /// Unique identifier for this timestamp action (used for retry tracking).
  public let actionId: UUID

  /// Number of retry attempts for this payload (internal, not serialized).
  public var retryCount: Int

  /// Timestamp of the last retry attempt (internal, not serialized).
  public var lastRetryAt: Date?

  /// Creates a payload with the given timestamp and action ID.
  ///
  /// - Parameters:
  ///   - unixTimestamp: Unix timestamp in seconds.
  ///   - actionId: Unique identifier for this action.
  ///   - retryCount: Initial retry count (defaults to 0).
  ///   - lastRetryAt: Last retry timestamp (defaults to nil).
  public init(
    unixTimestamp: UInt32,
    actionId: UUID,
    retryCount: Int = 0,
    lastRetryAt: Date? = nil
  ) {
    self.unixTimestamp = unixTimestamp
    self.actionId = actionId
    self.retryCount = retryCount
    self.lastRetryAt = lastRetryAt
  }

  // MARK: - Codable

  private enum CodingKeys: String, CodingKey {
    case unixTimestamp
    case actionId
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.unixTimestamp = try container.decode(UInt32.self, forKey: .unixTimestamp)
    self.actionId = try container.decode(UUID.self, forKey: .actionId)
    self.retryCount = 0
    self.lastRetryAt = nil
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(unixTimestamp, forKey: .unixTimestamp)
    try container.encode(actionId, forKey: .actionId)
  }
}
