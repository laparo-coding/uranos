import Foundation
import Testing

@testable import UranosCore

@Suite("RetryBackoff Tests")
struct RetryBackoffTests {

  @Test("Backoff intervals are [1, 2, 4, 8, 16]")
  func intervalsAreExponential() {
    #expect(RetryBackoff.intervals == [1, 2, 4, 8, 16])
  }

  @Test("Delay for retry 0 is 1 second")
  func delayForRetry0() {
    #expect(RetryBackoff.delay(forRetryCount: 0) == 1)
  }

  @Test("Delay for retry 1 is 2 seconds")
  func delayForRetry1() {
    #expect(RetryBackoff.delay(forRetryCount: 1) == 2)
  }

  @Test("Delay for retry 2 is 4 seconds")
  func delayForRetry2() {
    #expect(RetryBackoff.delay(forRetryCount: 2) == 4)
  }

  @Test("Delay for retry 3 is 8 seconds")
  func delayForRetry3() {
    #expect(RetryBackoff.delay(forRetryCount: 3) == 8)
  }

  @Test("Delay for retry 4 is 16 seconds")
  func delayForRetry4() {
    #expect(RetryBackoff.delay(forRetryCount: 4) == 16)
  }

  @Test("Delay for retry 5 (exceeds max) returns nil")
  func delayForRetry5ReturnsNil() {
    #expect(RetryBackoff.delay(forRetryCount: 5) == nil)
  }

  @Test("Delay for negative retry count returns nil")
  func delayForNegativeRetryReturnsNil() {
    #expect(RetryBackoff.delay(forRetryCount: -1) == nil)
  }

  @Test("Max retries is 5")
  func maxRetriesIs5() {
    #expect(RetryBackoff.maxRetries == 5)
  }

  @Test("Total maximum delay is 31 seconds")
  func totalMaximumDelayIs31() {
    #expect(RetryBackoff.totalMaximumDelay == 31)
  }
}
