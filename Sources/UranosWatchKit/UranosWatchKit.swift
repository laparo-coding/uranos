// UranosWatchKit — WatchKit-specific extensions and utilities.

import Foundation
import UranosCore

/// WatchKit helpers for the Uranos companion app.
public enum UranosWatchKit {
  /// Formats a short status string suitable for the Apple Watch complication.
  public static func shortStatus(for state: UranosCore.ConnectionState) -> String {
    switch state {
    case .connected:
      return "●"
    case .disconnected:
      return "○"
    case .syncing:
      return "◐"
    }
  }
}

// MARK: - Connection State

extension UranosCore {
  /// Represents the connection state between the Watch and the companion app.
  public enum ConnectionState: Sendable {
    case connected
    case disconnected
    case syncing
  }
}
