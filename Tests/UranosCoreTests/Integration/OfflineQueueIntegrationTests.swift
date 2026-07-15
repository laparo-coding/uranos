import Foundation
import Testing

@testable import UranosCore

// MARK: - Mock URLSession for Integration Tests

/// Mock URL session that can be configured with different responses per call.
final class ConfigurableMockURLSession: URLSessionProtocol, @unchecked Sendable {

  private var responses: [(Data, URLResponse)]
  private var errors: [Error?]
  private(set) var requestCount = 0
  private(set) var lastRequest: URLRequest?

  init(responses: [(Data, URLResponse)], errors: [Error?] = []) {
    self.responses = responses
    self.errors = errors
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    lastRequest = request
    let index = requestCount
    requestCount += 1

    if index < errors.count, let err = errors[index] {
      throw err
    }

    guard index < responses.count else {
      let fallbackURL = request.url ?? AitherAPIClient.endpointURL
      let response = HTTPURLResponse(
        url: fallbackURL,
        statusCode: 500,
        httpVersion: "HTTP/1.1",
        headerFields: nil
      )
      return (Data(), response ?? HTTPURLResponse())
    }

    return responses[index]
  }
}

private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
  let response = HTTPURLResponse(
    url: AitherAPIClient.endpointURL,
    statusCode: statusCode,
    httpVersion: "HTTP/1.1",
    headerFields: nil
  )
  return response ?? HTTPURLResponse()
}

// MARK: - Integration Tests

@Suite("Offline Queue Integration Tests")
struct OfflineQueueIntegrationTests {

  // MARK: - Scenario 1: Transmit Success (200) — Payload Removed from Queue

  @Test("Scenario 1: Successful transmission removes payload from queue")
  func scenario1SuccessRemovesFromQueue() async throws {
    var queue = OfflineTimestampQueue()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())
    queue.append(payload)

    let mockSession = ConfigurableMockURLSession(
      responses: [(Data(), httpResponse(200))]
    )
    let client = AitherAPIClient(bearerToken: "test-token", urlSession: mockSession)

    // Transmit the payload
    let pendingPayload = queue.removeFirst()!
    let statusCode = try await client.transmit(pendingPayload)

    #expect(statusCode == 200)
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 2: Transmit Failure (429) → Retry with Backoff → Success

  @Test("Scenario 2: 429 failure queues for retry, then succeeds")
  func scenario2RateLimitThenSuccess() async throws {
    var queue = OfflineTimestampQueue()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())
    queue.append(payload)

    // First call returns 429, second call returns 200
    let mockSession = ConfigurableMockURLSession(
      responses: [
        (Data(), httpResponse(429)),
        (Data(), httpResponse(200)),
      ]
    )
    let client = AitherAPIClient(bearerToken: "test-token", urlSession: mockSession)

    // First attempt fails with 429
    let firstPayload = queue.removeFirst()!
    await #expect(throws: AitherError.rateLimited) {
      _ = try await client.transmit(firstPayload)
    }

    // Re-queue for retry
    var retryPayload = firstPayload
    retryPayload.retryCount += 1
    queue.append(retryPayload)

    // Verify backoff delay for retry 1 is 2 seconds
    let delay = RetryBackoff.delay(forRetryCount: retryPayload.retryCount)
    #expect(delay == 2)

    // Second attempt succeeds
    let retryPayloadFromQueue = queue.removeFirst()!
    let statusCode = try await client.transmit(retryPayloadFromQueue)

    #expect(statusCode == 200)
    #expect(queue.isEmpty)
  }

  // MARK: - Scenario 3: Auth Failure (401) — Clears Entire Queue

  @Test("Scenario 3: 401 auth failure clears entire queue")
  func scenario3AuthFailureClearsQueue() async throws {
    var queue = OfflineTimestampQueue()
    queue.append(TimestampPayload(unixTimestamp: 1_000, actionId: UUID()))
    queue.append(TimestampPayload(unixTimestamp: 2_000, actionId: UUID()))
    queue.append(TimestampPayload(unixTimestamp: 3_000, actionId: UUID()))

    #expect(queue.count == 3)

    let mockSession = ConfigurableMockURLSession(
      responses: [(Data(), httpResponse(401))]
    )
    let client = AitherAPIClient(bearerToken: "invalid-token", urlSession: mockSession)

    // Attempt transmission fails with 401
    let payload = queue.removeFirst()!
    await #expect(throws: AitherError.authenticationFailed) {
      _ = try await client.transmit(payload)
    }

    // On 401, clear the entire queue
    queue.clearQueue()

    #expect(queue.isEmpty)
    #expect(queue.count == 0)
  }

  // MARK: - Scenario 4: Server Error (5xx) → Queue for Retry

  @Test("Scenario 4: 500 server error queues for retry")
  func scenario4ServerErrorQueuesForRetry() async throws {
    var queue = OfflineTimestampQueue()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())
    queue.append(payload)

    let mockSession = ConfigurableMockURLSession(
      responses: [(Data(), httpResponse(500))]
    )
    let client = AitherAPIClient(bearerToken: "test-token", urlSession: mockSession)

    // Attempt fails with 500
    let firstPayload = queue.removeFirst()!
    await #expect(throws: AitherError.serverError(statusCode: 500)) {
      _ = try await client.transmit(firstPayload)
    }

    // Re-queue for retry
    var retryPayload = firstPayload
    retryPayload.retryCount += 1
    queue.append(retryPayload)

    #expect(queue.count == 1)
    #expect(queue.allPending().first?.retryCount == 1)
  }

  // MARK: - Scenario 5: Max Retries Exceeded — Payload Dropped

  @Test("Scenario 5: Payload dropped after max retries exceeded")
  func scenario5MaxRetriesExceeded() async throws {
    var queue = OfflineTimestampQueue()
    var payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())
    queue.append(payload)

    // Simulate 5 failed retries
    for attempt in 0..<RetryBackoff.maxRetries {
      let mockSession = ConfigurableMockURLSession(
        responses: [(Data(), httpResponse(503))]
      )
      let client = AitherAPIClient(bearerToken: "test-token", urlSession: mockSession)

      let currentPayload = queue.removeFirst()!
      await #expect(throws: AitherError.serverError(statusCode: 503)) {
        _ = try await client.transmit(currentPayload)
      }

      payload.retryCount = attempt + 1

      // Check if we should continue retrying
      if RetryBackoff.delay(forRetryCount: payload.retryCount) != nil {
        queue.append(payload)
      }
    }

    // After 5 retries, payload should be dropped (not re-queued)
    #expect(queue.isEmpty)
  }
}
