import Foundation

/// In-memory FIFO queue for timestamps that failed to transmit to Aither.
///
/// The queue is bounded at `maxSize` entries. When the queue is at capacity and
/// a new timestamp arrives, the oldest entry is dropped (FIFO overflow).
///
/// The queue is in-memory only and clears on app termination by design.
public struct OfflineTimestampQueue: Sendable {

  /// Maximum number of entries the queue can hold.
  public static let maxSize = 500

  private var queue: [TimestampPayload]

  /// Creates an empty queue.
  public init() {
    self.queue = []
  }

  /// The current number of entries in the queue.
  public var count: Int {
    queue.count
  }

  /// Whether the queue is empty.
  public var isEmpty: Bool {
    queue.isEmpty
  }

  /// Appends a payload to the queue.
  ///
  /// If the queue is at capacity, the oldest entry is dropped (FIFO overflow)
  /// before the new entry is added.
  public mutating func append(_ payload: TimestampPayload) {
    if queue.count >= Self.maxSize {
      queue.removeFirst()
    }
    queue.append(payload)
  }

  /// Removes and returns the first (oldest) payload in the queue.
  public mutating func removeFirst() -> TimestampPayload? {
    guard !queue.isEmpty else { return nil }
    return queue.removeFirst()
  }

  /// Removes and returns the payload with the given action ID, if present.
  public mutating func remove(_ actionId: UUID) -> TimestampPayload? {
    guard let index = queue.firstIndex(where: { $0.actionId == actionId }) else {
      return nil
    }
    return queue.remove(at: index)
  }

  /// Returns a snapshot of all pending payloads.
  public func allPending() -> [TimestampPayload] {
    queue
  }

  /// Clears all entries from the queue.
  ///
  /// Called on authentication failure (401) to prevent retrying with invalid credentials.
  public mutating func clearQueue() {
    queue.removeAll()
  }
}
