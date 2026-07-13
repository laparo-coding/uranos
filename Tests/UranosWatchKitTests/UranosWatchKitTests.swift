import Testing

@testable import UranosCore
@testable import UranosWatchKit

@Suite("UranosWatchKit Tests")
struct UranosWatchKitTests {
  @Test("Short status returns expected symbols")
  func shortStatusSymbols() async {
    #expect(UranosWatchKit.shortStatus(for: .connected) == "●")
    #expect(UranosWatchKit.shortStatus(for: .disconnected) == "○")
    #expect(UranosWatchKit.shortStatus(for: .syncing) == "◐")
  }
}
