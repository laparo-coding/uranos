import Foundation

#if canImport(Network)
  import Network
#endif

/// Monitors network connectivity and triggers queue retries on restoration.
@available(macOS 12.0, iOS 15.0, watchOS 8.0, *)
public final class ConnectivityObserver: @unchecked Sendable {

  private let onConnectivityRestored: @Sendable () async -> Void
  private var isMonitoring = false

  #if canImport(Network)
    private var pathMonitor: NWPathMonitor?
    private var currentStatus: NWPath.Status = .requiresConnection
  #endif

  /// Creates a connectivity observer with the given callback.
  ///
  /// - Parameter onConnectivityRestored: Called when connectivity is restored after being lost.
  public init(onConnectivityRestored: @escaping @Sendable () async -> Void) {
    self.onConnectivityRestored = onConnectivityRestored
  }

  /// Starts monitoring network connectivity.
  public func startMonitoring() {
    guard !isMonitoring else { return }
    isMonitoring = true

    #if canImport(Network)
      pathMonitor = NWPathMonitor()
      guard let monitor = pathMonitor else { return }

      monitor.pathUpdateHandler = { [weak self] path in
        guard let self else { return }

        let wasDisconnected = self.currentStatus != .satisfied
        self.currentStatus = path.status

        if path.status == .satisfied && wasDisconnected {
          Task {
            await self.onConnectivityRestored()
          }
        }
      }

      monitor.start(queue: DispatchQueue.global(qos: .utility))
    #endif
  }

  /// Stops monitoring network connectivity.
  public func stopMonitoring() {
    #if canImport(Network)
      pathMonitor?.cancel()
      pathMonitor = nil
    #endif
    isMonitoring = false
  }

  /// Manually triggers the connectivity restored callback.
  ///
  /// Useful for testing or when connectivity is detected by other means.
  public func triggerConnectivityRestored() async {
    await onConnectivityRestored()
  }
}

// MARK: - Retry Coordinator

/// Coordinates retrying failed transmissions from the offline queue.
public final class RetryCoordinator: @unchecked Sendable {

  private let client: AitherAPIClient
  private var queue = OfflineTimestampQueue()

  /// Creates a retry coordinator with the given API client.
  public init(client: AitherAPIClient) {
    self.client = client
  }

  /// Enqueues a payload for later retry.
  public func enqueue(_ payload: TimestampPayload) {
    queue.append(payload)
  }

  /// Retries all pending payloads.
  ///
  /// - Returns: The number of successfully transmitted payloads.
  @discardableResult
  public func retryPending() async -> Int {
    let count = await retryQueue(&queue)
    return count
  }

  /// Retries all pending payloads in the given queue.
  ///
  /// - Parameter queue: The offline queue to process.
  /// - Returns: The number of successfully transmitted payloads.
  @discardableResult
  public func retryQueue(_ queue: inout OfflineTimestampQueue) async -> Int {
    var successCount = 0
    var failedPayloads: [TimestampPayload] = []

    while let payload = queue.removeFirst() {
      do {
        _ = try await client.transmit(payload)
        successCount += 1
      } catch AitherError.authenticationFailed {
        // 401: clear entire queue and stop
        queue.clearQueue()
        return successCount
      } catch {
        // Other errors: re-queue for later retry
        var failedPayload = payload
        failedPayload.retryCount += 1

        if failedPayload.retryCount < RetryBackoff.maxRetries {
          failedPayloads.append(failedPayload)
        }
        // If max retries exceeded, payload is dropped (not re-queued)
      }
    }

    // Re-queue failed payloads
    for payload in failedPayloads {
      queue.append(payload)
    }

    return successCount
  }
}
