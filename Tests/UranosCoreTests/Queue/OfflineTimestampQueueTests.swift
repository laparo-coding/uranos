import Foundation
import Testing

@testable import UranosCore

@Suite("OfflineTimestampQueue Tests")
struct OfflineTimestampQueueTests {

  // MARK: - Initialization

  @Test("Queue starts empty")
  func queueStartsEmpty() {
    let queue = OfflineTimestampQueue()

    #expect(queue.isEmpty)
    #expect(queue.count == 0)
    #expect(queue.allPending().isEmpty)
  }

  // MARK: - Append

  @Test("Append adds payload to queue")
  func appendAddsPayload() {
    var queue = OfflineTimestampQueue()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    queue.append(payload)

    #expect(queue.count == 1)
    #expect(!queue.isEmpty)
    #expect(queue.allPending().first?.actionId == payload.actionId)
  }

  @Test("Append preserves order (FIFO)")
  func appendPreservesOrder() {
    var queue = OfflineTimestampQueue()
    let payload1 = TimestampPayload(unixTimestamp: 1_000, actionId: UUID())
    let payload2 = TimestampPayload(unixTimestamp: 2_000, actionId: UUID())
    let payload3 = TimestampPayload(unixTimestamp: 3_000, actionId: UUID())

    queue.append(payload1)
    queue.append(payload2)
    queue.append(payload3)

    let pending = queue.allPending()
    #expect(pending.count == 3)
    #expect(pending[0].actionId == payload1.actionId)
    #expect(pending[1].actionId == payload2.actionId)
    #expect(pending[2].actionId == payload3.actionId)
  }

  // MARK: - FIFO Overflow

  @Test("FIFO overflow drops oldest at 500 limit")
  func fifoOverflowDropsOldest() {
    var queue = OfflineTimestampQueue()

    // Add exactly 500 entries
    let firstPayload = TimestampPayload(unixTimestamp: 1, actionId: UUID())
    queue.append(firstPayload)
    for i in 2...500 {
      queue.append(TimestampPayload(unixTimestamp: UInt32(i), actionId: UUID()))
    }
    #expect(queue.count == 500)

    // Add 501st entry — should drop the first (oldest)
    let newestPayload = TimestampPayload(unixTimestamp: 501, actionId: UUID())
    queue.append(newestPayload)

    #expect(queue.count == 500)
    #expect(queue.allPending().first?.actionId != firstPayload.actionId)
    #expect(queue.allPending().last?.actionId == newestPayload.actionId)
  }

  @Test("FIFO overflow drops entries in order")
  func fifoOverflowDropsInOrder() {
    var queue = OfflineTimestampQueue()

    // Fill to capacity
    for i in 1...500 {
      queue.append(TimestampPayload(unixTimestamp: UInt32(i), actionId: UUID()))
    }

    // Add 2 more — should drop the 2 oldest
    let payload501 = TimestampPayload(unixTimestamp: 501, actionId: UUID())
    let payload502 = TimestampPayload(unixTimestamp: 502, actionId: UUID())
    queue.append(payload501)
    queue.append(payload502)

    #expect(queue.count == 500)
    // First entry should now be timestamp=3 (1 and 2 were dropped)
    #expect(queue.allPending().first?.unixTimestamp == 3)
    #expect(queue.allPending().last?.actionId == payload502.actionId)
  }

  // MARK: - Remove First

  @Test("removeFirst returns and removes oldest entry")
  func removeFirstReturnsOldest() {
    var queue = OfflineTimestampQueue()
    let payload1 = TimestampPayload(unixTimestamp: 1, actionId: UUID())
    let payload2 = TimestampPayload(unixTimestamp: 2, actionId: UUID())
    queue.append(payload1)
    queue.append(payload2)

    let removed = queue.removeFirst()

    #expect(removed?.actionId == payload1.actionId)
    #expect(queue.count == 1)
    #expect(queue.allPending().first?.actionId == payload2.actionId)
  }

  @Test("removeFirst returns nil on empty queue")
  func removeFirstOnEmpty() {
    var queue = OfflineTimestampQueue()

    let removed = queue.removeFirst()

    #expect(removed == nil)
  }

  // MARK: - Remove by Action ID

  @Test("remove by actionId removes correct entry")
  func removeByActionId() {
    var queue = OfflineTimestampQueue()
    let targetId = UUID()
    let payload1 = TimestampPayload(unixTimestamp: 1, actionId: UUID())
    let payload2 = TimestampPayload(unixTimestamp: 2, actionId: targetId)
    let payload3 = TimestampPayload(unixTimestamp: 3, actionId: UUID())
    queue.append(payload1)
    queue.append(payload2)
    queue.append(payload3)

    let removed = queue.remove(targetId)

    #expect(removed?.actionId == targetId)
    #expect(queue.count == 2)
    #expect(queue.allPending().contains(where: { $0.actionId == targetId }) == false)
  }

  @Test("remove by unknown actionId returns nil")
  func removeByUnknownActionId() {
    var queue = OfflineTimestampQueue()
    queue.append(TimestampPayload(unixTimestamp: 1, actionId: UUID()))

    let removed = queue.remove(UUID())

    #expect(removed == nil)
    #expect(queue.count == 1)
  }

  // MARK: - Clear Queue

  @Test("clearQueue empties the queue")
  func clearQueueEmpties() {
    var queue = OfflineTimestampQueue()
    queue.append(TimestampPayload(unixTimestamp: 1, actionId: UUID()))
    queue.append(TimestampPayload(unixTimestamp: 2, actionId: UUID()))
    queue.append(TimestampPayload(unixTimestamp: 3, actionId: UUID()))

    queue.clearQueue()

    #expect(queue.isEmpty)
    #expect(queue.count == 0)
    #expect(queue.allPending().isEmpty)
  }

  // MARK: - Memory Footprint

  @Test("Queue at capacity has 500 entries")
  func queueAtCapacity() {
    var queue = OfflineTimestampQueue()

    for _ in 0..<500 {
      queue.append(TimestampPayload(unixTimestamp: 1, actionId: UUID()))
    }

    #expect(queue.count == 500)
    #expect(queue.count == OfflineTimestampQueue.maxSize)
  }
}
