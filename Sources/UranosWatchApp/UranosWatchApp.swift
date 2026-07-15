import SwiftUI
import UranosCore
import UranosWatchKit
import WatchKit

/// Entry point for the Uranos watchOS app.
@main
struct UranosWatchApp: App {
  @WKApplicationDelegateAdaptor private var appDelegate: UranosAppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView(appDelegate: appDelegate)
    }
  }
}

/// App delegate handling lifecycle and glench detection setup.
final class UranosAppDelegate: NSObject, WKApplicationDelegate, ObservableObject {

  @Published var queueCount: Int = 0
  @Published var transmissionState: TransmissionState = .pending

  private var glenchDetector: GlenchDetector?
  private var offlineQueue = OfflineTimestampQueue()
  private var apiClient: AitherAPIClient?
  private var connectivityObserver: ConnectivityObserver?

  func applicationDidFinishLaunching() {
    UranosLogger.info("Uranos Watch app started")

    // Load auth token
    do {
      let token = try AuthConfig.loadBearerToken()
      apiClient = AitherAPIClient(bearerToken: token, urlSession: URLSession.shared)
      UranosLogger.info("Aither auth token loaded")
    } catch {
      UranosLogger.error("Missing AITHER_BEARER_TOKEN — glench transmission disabled")
    }

    // Setup glench detector
    glenchDetector = GlenchDetector()

    // Setup connectivity observer for queue retries
    if let client = apiClient {
      let coordinator = RetryCoordinator(client: client)
      connectivityObserver = ConnectivityObserver {
        await coordinator.retryPending()
      }
      connectivityObserver?.startMonitoring()
    }
  }

  /// Processes a glench event: captures timestamp, triggers haptic, queues payload.
  func handleGlench() {
    let event = SensorData(
      accelerometerX: 1.0, accelerometerY: 0, accelerometerZ: 0,
      gyroscopeX: 0, gyroscopeY: 0, gyroscopeZ: 0
    )

    guard let detector = glenchDetector, detector.onSensorEvent(event) else {
      UranosLogger.debug("Glench debounced — ignored")
      return
    }

    HapticFeedback.triggerGlenchHaptic()

    let timestamp = UInt32(Date().timeIntervalSince1970)
    let payload = TimestampPayload(unixTimestamp: timestamp, actionId: UUID())

    UranosLogger.logTransmissionStart(payload: payload)
    offlineQueue.append(payload)
    queueCount = offlineQueue.count
    transmissionState = .pending

    UranosLogger.logQueueState(queue: offlineQueue)

    // Attempt immediate transmission
    Task {
      await attemptTransmission(payload: payload)
    }
  }

  /// Attempts to transmit a payload to Aither.
  private func attemptTransmission(payload: TimestampPayload) async {
    guard let client = apiClient else {
      UranosLogger.warning("No API client — payload stays in queue")
      return
    }

    do {
      let statusCode = try await client.transmit(payload)
      UranosLogger.logTransmissionSuccess(payload: payload, statusCode: statusCode)

      // Remove from queue on success
      offlineQueue.remove(payload.actionId)
      await MainActor.run {
        queueCount = offlineQueue.count
        transmissionState = .sent
      }
    } catch AitherError.authenticationFailed {
      UranosLogger.logAuthFailure()
      offlineQueue.clearQueue()
      await MainActor.run {
        queueCount = 0
        transmissionState = .failed
      }
    } catch {
      UranosLogger.logTransmissionFailure(
        payload: payload,
        error: error as? AitherError ?? .networkError,
        retryCount: payload.retryCount
      )
      await MainActor.run {
        transmissionState = .failed
      }
    }
  }
}
