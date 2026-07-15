import Foundation

/// HTTP client for transmitting timestamps to the Aither API.
///
/// Uses a Bearer token for authentication and enforces a 15-second request
/// timeout suitable for watchOS network conditions.
public final class AitherAPIClient: Sendable {

  /// The base URL for the Aither timestamp endpoint.
  /// Uses `AITHER_API_URL` env var if set, otherwise defaults to localhost for dev.

  public static let endpointURL: URL = {

    let urlString =
      ProcessInfo.processInfo.environment["AITHER_API_URL"]
      ?? "http://localhost:3000/api/recording/timestamp"
    guard let url = URL(string: urlString) else {
      fatalError("Invalid Aither endpoint URL: \(urlString)")
    }
    return url
  }()

  /// Default request timeout for watchOS network conditions.
  public static let defaultTimeout: TimeInterval = 15

  private let bearerToken: String
  private let timeout: TimeInterval
  private let urlSession: URLSessionProtocol

  /// Creates a client with the given configuration.
  ///
  /// - Parameters:
  ///   - bearerToken: The Bearer token for Aither API authentication.
  ///   - timeout: Request timeout in seconds (defaults to 15).
  ///   - urlSession: The URL session to use for network requests.
  public init(
    bearerToken: String,
    timeout: TimeInterval = defaultTimeout,
    urlSession: URLSessionProtocol
  ) {
    self.bearerToken = bearerToken
    self.timeout = timeout
    self.urlSession = urlSession
  }

  /// Creates a client using the shared URLSession.
  ///
  /// - Parameters:
  ///   - bearerToken: The Bearer token for Aither API authentication.
  ///   - timeout: Request timeout in seconds (defaults to 15).
  @available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
  public convenience init(
    bearerToken: String,
    timeout: TimeInterval = defaultTimeout
  ) {
    self.init(bearerToken: bearerToken, timeout: timeout, urlSession: URLSession.shared)
  }

  /// Transmits a timestamp payload to the Aither API.
  ///
  /// - Parameter payload: The timestamp payload to send.
  /// - Returns: The HTTP status code on success.
  /// - Throws: `AitherError` for authentication, rate limit, server, or network errors.
  public func transmit(_ payload: TimestampPayload) async throws -> Int {
    var request = URLRequest(url: Self.endpointURL)
    request.httpMethod = "POST"
    request.timeoutInterval = timeout
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONEncoder().encode(AitherRequestBody(timestamp: payload.unixTimestamp))

    let (_, response): (Data, URLResponse)
    do {
      (_, response) = try await urlSession.data(for: request)
    } catch let error as URLError {
      switch error.code {
      case .timedOut:
        throw AitherError.timeout
      case .notConnectedToInternet, .networkConnectionLost:
        throw AitherError.networkError
      default:
        throw AitherError.networkError
      }
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw AitherError.invalidResponse
    }

    let statusCode = httpResponse.statusCode

    switch statusCode {
    case 200...299:
      return statusCode
    case 401:
      throw AitherError.authenticationFailed
    case 429:
      throw AitherError.rateLimited
    case 400...499:
      throw AitherError.clientError(statusCode: statusCode)
    case 500...599:
      throw AitherError.serverError(statusCode: statusCode)
    default:
      throw AitherError.invalidResponse
    }
  }
}

// MARK: - Aither Request Body

/// Request body schema for the Aither timestamp endpoint.
///
/// Aither expects `{ "timestamp": <number> }` (Spec 009).
struct AitherRequestBody: Codable {
  let timestamp: UInt32
}

// MARK: - URLSession Protocol

/// Protocol abstraction over `URLSession` for testability.
public protocol URLSessionProtocol: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
extension URLSession: URLSessionProtocol {
  public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await data(for: request, delegate: nil)
  }
}
