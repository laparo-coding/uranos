import Foundation
import Testing

@testable import UranosCore

// MARK: - Mock URLSession

/// Mock URL session for testing AitherAPIClient without real network calls.
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {

  private let mockResponse: (Data, URLResponse)
  private let mockError: Error?
  private(set) var lastRequest: URLRequest?

  init(response: (Data, URLResponse), error: Error? = nil) {
    self.mockResponse = response
    self.mockError = error
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    lastRequest = request
    if let mockError {
      throw mockError
    }
    return mockResponse
  }
}

// MARK: - Helper

private func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
  let response = HTTPURLResponse(
    url: AitherAPIClient.endpointURL,
    statusCode: statusCode,
    httpVersion: "HTTP/1.1",
    headerFields: nil
  )
  return response ?? HTTPURLResponse()
}

// MARK: - Tests

@Suite("AitherAPIClient Tests")
struct AitherAPIClientTests {

  // MARK: - Success

  @Test("Transmit succeeds with 200 OK")
  func transmitSuccess200OK() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    let statusCode = try await client.transmit(payload)

    #expect(statusCode == 200)
  }

  @Test("Transmit includes Bearer token in Authorization header")
  func transmitIncludesBearerToken() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200))
    )
    let client = AitherAPIClient(
      bearerToken: "my-secret-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    _ = try await client.transmit(payload)

    let authHeader = mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
    #expect(authHeader == "Bearer my-secret-token")
  }

  @Test("Transmit sets Content-Type to application/json")
  func transmitSetsContentType() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    _ = try await client.transmit(payload)

    let contentType = mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type")
    #expect(contentType == "application/json")
  }

  @Test("Transmit uses POST method")
  func transmitUsesPOST() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    _ = try await client.transmit(payload)

    #expect(mockSession.lastRequest?.httpMethod == "POST")
  }

  @Test("Transmit encodes payload as JSON body")
  func transmitEncodesPayloadAsJSON() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let actionId = UUID()
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: actionId)

    _ = try await client.transmit(payload)

    let bodyData = mockSession.lastRequest?.httpBody
    #expect(bodyData != nil)

    let bodyDict = try JSONSerialization.jsonObject(with: bodyData!) as? [String: Any]
    #expect(bodyDict?["timestamp"] as? Int == 1_720_380_913)
  }

  // MARK: - Failure: 401

  @Test("Transmit throws authenticationFailed on 401")
  func transmitFailure401() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 401))
    )
    let client = AitherAPIClient(
      bearerToken: "invalid-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.authenticationFailed) {
      _ = try await client.transmit(payload)
    }
  }

  // MARK: - Failure: 429

  @Test("Transmit throws rateLimited on 429")
  func transmitFailure429() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 429))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.rateLimited) {
      _ = try await client.transmit(payload)
    }
  }

  // MARK: - Failure: 5xx

  @Test("Transmit throws serverError on 500")
  func transmitFailure500() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 500))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.serverError(statusCode: 500)) {
      _ = try await client.transmit(payload)
    }
  }

  @Test("Transmit throws serverError on 503")
  func transmitFailure503() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 503))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.serverError(statusCode: 503)) {
      _ = try await client.transmit(payload)
    }
  }

  // MARK: - Failure: 4xx (non-401, non-429)

  @Test("Transmit throws clientError on 400")
  func transmitFailure400() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 400))
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.clientError(statusCode: 400)) {
      _ = try await client.transmit(payload)
    }
  }

  // MARK: - Failure: Timeout

  @Test("Transmit throws timeout on URLError.timedOut")
  func transmitFailureTimeout() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200)),
      error: URLError(.timedOut)
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.timeout) {
      _ = try await client.transmit(payload)
    }
  }

  // MARK: - Failure: Network Error

  @Test("Transmit throws networkError on no connectivity")
  func transmitFailureNoConnectivity() async throws {
    let mockSession = MockURLSession(
      response: (Data(), makeHTTPResponse(statusCode: 200)),
      error: URLError(.notConnectedToInternet)
    )
    let client = AitherAPIClient(
      bearerToken: "test-token",
      urlSession: mockSession
    )
    let payload = TimestampPayload(unixTimestamp: 1_720_380_913, actionId: UUID())

    await #expect(throws: AitherError.networkError) {
      _ = try await client.transmit(payload)
    }
  }
}
