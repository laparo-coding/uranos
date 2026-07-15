import Foundation
import Testing

@testable import UranosCore

@Suite("TransmissionState Tests")
struct TransmissionStateTests {

  @Test("TransmissionState contains pending/sent/failed")
  func containsAllStates() {
    let states = Set(TransmissionState.allCases)
    #expect(states == Set([.pending, .sent, .failed]))
  }

  @Test("TransmissionState raw values are stable")
  func rawValuesStable() {
    #expect(TransmissionState.pending.rawValue == "pending")
    #expect(TransmissionState.sent.rawValue == "sent")
    #expect(TransmissionState.failed.rawValue == "failed")
  }

  @Test("TransmissionState Codable roundtrip")
  func codableRoundtrip() throws {
    let original = TransmissionState.sent
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(TransmissionState.self, from: data)

    #expect(decoded == original)
  }

  @Test("TransmissionEvent initializes with defaults")
  func eventInitializationDefaults() {
    let actionId = UUID()
    let event = TransmissionEvent(
      actionId: actionId,
      state: .pending,
      recordedAtUnixSeconds: 1_720_380_913
    )

    #expect(event.actionId == actionId)
    #expect(event.state == .pending)
    #expect(event.recordedAtUnixSeconds == 1_720_380_913)
    #expect(event.metadata.isEmpty)
  }

  @Test("TransmissionEvent supports metadata")
  func eventMetadata() {
    let event = TransmissionEvent(
      actionId: UUID(),
      state: .failed,
      recordedAtUnixSeconds: 1_720_380_913,
      metadata: [
        "statusCode": "429",
        "retryCount": "2",
      ]
    )

    #expect(event.metadata["statusCode"] == "429")
    #expect(event.metadata["retryCount"] == "2")
  }

  @Test("TransmissionEvent Codable roundtrip")
  func transmissionEventCodableRoundtrip() throws {
    let original = TransmissionEvent(
      actionId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000") ?? UUID(),
      state: .sent,
      recordedAtUnixSeconds: 1_720_380_913,
      metadata: ["statusCode": "200"]
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(TransmissionEvent.self, from: data)

    #expect(decoded.actionId == original.actionId)
    #expect(decoded.state == original.state)
    #expect(decoded.recordedAtUnixSeconds == original.recordedAtUnixSeconds)
    #expect(decoded.metadata == original.metadata)
  }
}
