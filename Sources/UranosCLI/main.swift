// UranosCLI — Command-line interface for Uranos development and testing.

import Foundation
import UranosCore

@main
enum UranosCLI {
  static func main() async throws {
    print("Uranos CLI v\(UranosCore.version)")
    print("Run with --help for usage information.")
  }
}
