import Testing

@testable import UranosCore

@Suite("UranosCore Tests")
struct UranosCoreTests {
  @Test("Version is non-empty")
  func versionIsNonEmpty() {
    #expect(!UranosCore.version.isEmpty)
  }
}
