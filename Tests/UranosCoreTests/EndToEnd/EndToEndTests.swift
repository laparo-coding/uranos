import Foundation
import Testing

@testable import UranosCore

// MARK: - Helpers

private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
  let response = HTTPURLResponse(
    url: AitherAPIClient.endpointURL,
    statusCode: statusCode,
    httpVersion: "HTTP/1.1",
    headerFields: nil
  )
  return response ?? HTTPURLResponse()
}

private func makePayload(timestamp: UInt32 = 1_720_380_913) -> TimestampPayload {
  TimestampPayload(unixTimestamp: timestamp, actionId: UUID())
}

// MARK: - End-to-End Tests

@Suite("End-to-End Integration Tests")
struct EndToEndTests {

  // MARK: - Scenario 1: Happy Path

  @Test("Happy path: glench → transmit → 200 OK → queue empty")
  func scenario1HappyPath() async throws {
    var queue = OfflineTimestampQueue()
    let payload = makePayload()
    queue.append(payload)

    let mockSession = ConfigurableMockURLSession(
      responses: [(Data(), httpResponse(200))]
    )
    let client = AitherAPIClient(bearerToken: "valid-token", urlSession: mockSession)
    let coordinator = RetryCoordinator(client: client)

    let successCount = await coordinator.retryQueue(&queue)

    #expect(successCount == 1)
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 2: Offline → Queue → Connectivity Restored → Retry Succeeds

  @Test("Offline: queue → connectivity restored → retry succeeds")
  func scenario2OfflineThenRetry() async throws {
    var queue = OfflineTimestampQueue()
    queue.append(makePayload(timestamp: 1_000))
    queue.append(makePayload(timestamp: 2_000))

    // First call: network error, second and third: success
    let mockSession = ConfigurableMockURLSession(
      responses: [
        (Data(), httpResponse(200)),
        (Data(), httpResponse(200)),
        (Data(), httpResponse(200)),
      ],
      errors: [URLError(.notConnectedToInternet), nil, nil]
    )
    let client = AitherAPIClient(bearerToken: "valid-token", urlSession: mockSession)
    let coordinator = RetryCoordinator(client: client)

    // First pass: payload1 fails (network), payload2 succeeds
    let firstPassCount = await coordinator.retryQueue(&queue)

    #expect(firstPassCount == 1)
    #expect(queue.count == 1)

    // Second pass: retry payload1 succeeds
    let secondPassCount = await coordinator.retryQueue(&queue)

    #expect(secondPassCount == 1)
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 3: Auth Failure → Queue Cleared

  @Test("Auth failure: 401 → queue cleared")
  func scenario3AuthFailureClearsQueue() async throws {
    var queue = OfflineTimestampQueue()
    queue.append(makePayload(timestamp: 1_000))
    queue.append(makePayload(timestamp: 2_000))
    queue.append(makePayload(timestamp: 3_000))

    let mockSession = ConfigurableMockURLSession(
      responses: [(Data(), httpResponse(401))]
    )
    let client = AitherAPIClient(bearerToken: "invalid-token", urlSession: mockSession)
    let coordinator = RetryCoordinator(client: client)

    _ = await coordinator.retryQueue(&queue)

    // Queue should be cleared on 401
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 4: Rate Limit → Retry → Success

  @Test("Rate limit: 429 → retry → success")
  func scenario4RateLimitThenSuccess() async throws {
    var queue = OfflineTimestampQueue()
    queue.append(makePayload())

    // First: 429, second: 200
    let mockSession = ConfigurableMockURLSession(
      responses: [
        (Data(), httpResponse(429)),
        (Data(), httpResponse(200)),
      ]
    )
    let client = AitherAPIClient(bearerToken: "valid-token", urlSession: mockSession)
    let coordinator = RetryCoordinator(client: client)

    // First pass: 429 fails, re-queued
    let firstPassCount = await coordinator.retryQueue(&queue)

    #expect(firstPassCount == 0)
    #expect(queue.count == 1)

    // Second pass: succeeds
    let secondPassCount = await coordinator.retryQueue(&queue)

    #expect(secondPassCount == 1)
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 5: Timeout → Retry → Success

  @Test("Timeout: 15s timeout → retry → success")
  func scenario5TimeoutThenSuccess() async throws {
    var queue = OfflineTimestampQueue()
    queue.append(makePayload())

    // First: timeout, second: success
    let mockSession = ConfigurableMockURLSession(
      responses: [
        (Data(), httpResponse(200)),
        (Data(), httpResponse(200)),
      ],
      errors: [URLError(.timedOut), nil]
    )
    let client = AitherAPIClient(bearerToken: "valid-token", urlSession: mockSession)
    let coordinator = RetryCoordinator(client: client)

    // First pass: timeout, re-queued
    let firstPassCount = await coordinator.retryQueue(&queue)

    #expect(firstPassCount == 0)
    #expect(queue.count == 1)

    // Second pass: succeeds
    let secondPassCount = await coordinator.retryQueue(&queue)

    #expect(secondPassCount == 1)
    #expect(queue.isEmpty)
  }

  // MARK: - Auth Config Tests

  @Test("Auth config loads token from environment")
  func authConfigLoadsToken() throws {
    let env = ["AITHER_BEARER_TOKEN": "test-token-123"]
    let token = try AuthConfig.loadBearerToken(from: env)
    #expect(token == "test-token-123")
  }

  @Test("Auth config throws missingAuthToken when token absent")
  func authConfigThrowsWhenMissing() async throws {
    let env: [String: String] = [:]
    await #expect(throws: AitherError.missingAuthToken) {
      _ = try AuthConfig.loadBearerToken(from: env)
    }
  }

  @Test("Auth config throws missingAuthToken when token empty")
  func authConfigThrowsWhenEmpty() async throws {
    let env = ["AITHER_BEARER_TOKEN": ""]
    await #expect(throws: AitherError.missingAuthToken) {
      _ = try AuthConfig.loadBearerToken(from: env)
    }
  }
}
