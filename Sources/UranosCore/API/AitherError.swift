import Foundation

/// Errors that can occur when communicating with the Aither API.
public enum AitherError: Error, Sendable, Equatable {

  /// The bearer token is missing from the environment.
  case missingAuthToken

  /// The server returned a 401 Unauthorized response.
  case authenticationFailed

  /// The server returned a 429 Too Many Requests response.
  case rateLimited

  /// The server returned a 5xx server error.
  case serverError(statusCode: Int)

  /// The server returned an unexpected 4xx client error.
  case clientError(statusCode: Int)

  /// The request timed out.
  case timeout

  /// A network error occurred (e.g., no connectivity).
  case networkError

  /// The response could not be parsed.
  case invalidResponse
}
