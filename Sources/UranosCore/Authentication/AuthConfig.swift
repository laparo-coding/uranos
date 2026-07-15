import Foundation

/// Loads authentication credentials for the Aither API.
public enum AuthConfig {

  /// The environment variable name for the Aither Bearer token.
  public static let tokenEnvironmentVariable = "AITHER_BEARER_TOKEN"

  /// Loads the Bearer token from the environment.
  ///
  /// - Returns: The Bearer token string.
  /// - Throws: `AitherError.missingAuthToken` if the token is not set.
  public static func loadBearerToken() throws -> String {
    guard let token = ProcessInfo.processInfo.environment[tokenEnvironmentVariable],
      !token.isEmpty
    else {
      throw AitherError.missingAuthToken
    }
    return token
  }

  /// Loads the Bearer token from a specific environment dictionary.
  ///
  /// Useful for testing with custom environments.
  ///
  /// - Parameter environment: The environment dictionary to read from.
  /// - Returns: The Bearer token string.
  /// - Throws: `AitherError.missingAuthToken` if the token is not set.
  public static func loadBearerToken(from environment: [String: String]) throws -> String {
    guard let token = environment[tokenEnvironmentVariable], !token.isEmpty else {
      throw AitherError.missingAuthToken
    }
    return token
  }
}
