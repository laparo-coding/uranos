import Foundation

/// Represents the lifecycle state of a timestamp transmission.
///
/// Used for observable tracking of payload progression through the offline queue
/// and Aither API delivery pipeline.
public enum TransmissionState: String, Codable, Sendable, CaseIterable, Equatable {

  /// Payload has been captured and is pending transmission.
  case pending

  /// Payload was successfully delivered to Aither.
  case sent

  /// Payload transmission failed (transient or terminal).
  case failed
}

/// Snapshot of a payload state transition for observability.
public struct TransmissionEvent: Sendable, Equatable, Codable {

  /// Correlation ID for a timestamp action.
  public let actionId: UUID

  /// The current transmission state.
  public let state: TransmissionState

  /// Unix timestamp (seconds) when this state was recorded.
  public let recordedAtUnixSeconds: UInt32

  /// Optional metadata (status code, retry count, message).
  public let metadata: [String: String]

  public init(
    actionId: UUID,
    state: TransmissionState,
    recordedAtUnixSeconds: UInt32,
    metadata: [String: String] = [:]
  ) {
    self.actionId = actionId
    self.state = state
    self.recordedAtUnixSeconds = recordedAtUnixSeconds
    self.metadata = metadata
  }
}
