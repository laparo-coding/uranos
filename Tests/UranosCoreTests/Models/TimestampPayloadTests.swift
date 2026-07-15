import Foundation
import Testing

@testable import UranosCore

@Suite("TimestampPayload Tests")
struct TimestampPayloadTests {

  // MARK: - Initialization

  @Test("TimestampPayload initializes with unixTimestamp and actionId")
  func initializationWithRequiredFields() {
    let actionId = UUID()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: actionId)

    #expect(payload.unixTimestamp == 1_720_380_913)
    #expect(payload.actionId == actionId)
    #expect(payload.retryCount == 0)
    #expect(payload.lastRetryAt == nil)
  }

  // MARK: - JSON Encoding

  @Test("JSON encoding includes unixTimestamp and actionId")
  func jsonEncodingIncludesRequiredFields() throws {
    let actionId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000") ?? UUID()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: actionId)

    let data = try JSONEncoder().encode(payload)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(dict != nil)
    #expect(dict?["unixTimestamp"] as? Int == 1_720_380_913)
    #expect(dict?["actionId"] as? String == "550E8400-E29B-41D4-A716-446655440000")
  }

  @Test("JSON encoding excludes internal retry metadata")
  func jsonEncodingExcludesInternalMetadata() throws {
    let payload = TimestampPayload(
      unixTimestamp: 1_720_380_913,
      actionId: UUID(),
      retryCount: 3,
      lastRetryAt: Date()
    )

    let data = try JSONEncoder().encode(payload)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(dict?["retryCount"] == nil)
    #expect(dict?["lastRetryAt"] == nil)
  }

  // MARK: - JSON Decoding

  @Test("JSON decoding round-trip preserves fields")
  func jsonDecodingRoundTrip() throws {
    let original = TimestampPayload(
      unixTimestamp: 1_720_380_913,
      actionId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000") ?? UUID()
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(TimestampPayload.self, from: data)

    #expect(decoded.unixTimestamp == original.unixTimestamp)
    #expect(decoded.actionId == original.actionId)
  }

  @Test("JSON decoding accepts minimal payload with unixTimestamp and actionId")
  func jsonDecodingAcceptsMinimalPayload() throws {
    let jsonString = """
      {
        "unixTimestamp": 1720380913,
        "actionId": "550e8400-e29b-41d4-a716-446655440000"
      }
      """
    let data = jsonString.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(TimestampPayload.self, from: data)

    #expect(decoded.unixTimestamp == 1_720_380_913)
    #expect(decoded.actionId.uuidString == "550E8400-E29B-41D4-A716-446655440000")
    #expect(decoded.retryCount == 0)
    #expect(decoded.lastRetryAt == nil)
  }

  // MARK: - Retry Tracking

  @Test("retryCount increments correctly")
  func retryCountIncrements() {
    var payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    #expect(payload.retryCount == 0)

    payload.retryCount += 1
    #expect(payload.retryCount == 1)

    payload.retryCount = 5
    #expect(payload.retryCount == 5)
  }

  @Test("lastRetryAt updates on retry")
  func lastRetryAtUpdates() {
    var payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())
    let retryTime = Date(timeIntervalSince1970: 1_720_380_920)

    payload.lastRetryAt = retryTime

    #expect(payload.lastRetryAt == retryTime)
  }
}
