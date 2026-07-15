// UranosCLI — Command-line interface for Uranos development and testing.

import Foundation
import UranosCore

@main
enum UranosCLI {
  static func main() async throws {
    let arguments = CommandLine.arguments.dropFirst().map { String($0) }

    if arguments.isEmpty {
      printUsage()
      return
    }

    let command = arguments[0]

    switch command {
    case "--help", "-h":
      printUsage()
    case "queue-inspect":
      printQueueInspect()
    case "queue-clear":
      printQueueClear()
    case "show-config":
      try printShowConfig()
    case "version":
      print("Uranos CLI v\(UranosCore.version)")
    default:
      print("Unknown command: \(command)")
      printUsage()
    }
  }

  // MARK: - Commands

  static func printUsage() {
    print(
      """
      Uranos CLI v\(UranosCore.version)

      Usage: UranosCLI <command>

      Commands:
        queue-inspect    [STUB] Show offline queue structure (always empty; no persistence layer)
        queue-clear      [STUB] No-op demo of queue clearing (always empty; no persistence layer)
        show-config      Verify AITHER_BEARER_TOKEN is present
        version          Print the CLI version
        --help, -h       Show this help message
      """)
  }

  static func printQueueInspect() {
    // OfflineTimestampQueue is in-memory only and always empty when freshly
    // initialized — there is no persistence layer to inspect yet.
    let queue = OfflineTimestampQueue()
    print("Offline Queue Inspection [STUB — no persistence layer]")
    print("─" * 40)
    print("Pending payloads: \(queue.count)")
    print("Max capacity: \(OfflineTimestampQueue.maxSize)")
    if queue.isEmpty {
      print("Queue is empty. (A fresh in-memory queue has no persisted state to inspect.)")
    } else {
      for (index, payload) in queue.allPending().enumerated() {
        print(
          "[\(index)] timestamp=\(payload.unixTimestamp) actionId=\(payload.actionId) retries=\(payload.retryCount)"
        )
      }
    }
  }

  static func printQueueClear() {
    // OfflineTimestampQueue is in-memory only — a fresh instance is always
    // empty, so clearing is a no-op until a persistence layer is added.
    var queue = OfflineTimestampQueue()
    let count = queue.count
    queue.clearQueue()
    print("Queue Clear [STUB — no persistence layer]")
    print("Removed \(count) payloads. (In-memory queue is always empty on startup.)")
  }

  static func printShowConfig() throws {
    print("Uranos Configuration")
    print("─" * 40)

    // Check auth token
    do {
      let token = try AuthConfig.loadBearerToken()
      let fingerprint = tokenFingerprint(token)
      print("AITHER_BEARER_TOKEN: ✓ Set (length=\(token.count), fingerprint=\(fingerprint))")
    } catch AitherError.missingAuthToken {
      print("AITHER_BEARER_TOKEN: ✗ Not set")
      print("  Set the environment variable: export AITHER_BEARER_TOKEN=<your-token>")
    }

    // Show API endpoint
    print("Aither endpoint: \(AitherAPIClient.endpointURL.absoluteString)")
    print("Request timeout: \(AitherAPIClient.defaultTimeout)s")
    print("Max retries: \(RetryBackoff.maxRetries)")
    print("Backoff intervals: \(RetryBackoff.intervals) seconds")
  }

  // MARK: - Helpers

  /// Returns a non-reversible fingerprint of the bearer token.
  ///
  /// Uses the FNV-1a hash to produce a stable, non-invertible identifier
  /// so the value can be matched across runs for verification without
  /// exposing any part of the secret. Only the first 12 hex characters
  /// are shown.
  static func tokenFingerprint(_ token: String) -> String {
    var hash: UInt64 = 0xcbf29ce484222325
    let prime: UInt64 = 0x100000001b3
    for byte in token.utf8 {
      hash ^= UInt64(byte)
      hash &*= prime
    }
    return String(format: "%012llx", hash & 0xffffffffffff)
  }
}

// MARK: - String Helper

extension String {
  static func * (lhs: String, rhs: Int) -> String {
    String(repeating: lhs, count: rhs)
  }
}
