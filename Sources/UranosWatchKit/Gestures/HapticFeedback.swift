import Foundation

#if canImport(WatchKit)
  import WatchKit
#endif

/// Provides haptic feedback to the Watch user.
public enum HapticFeedback {

  /// Triggers a click haptic on the Watch.
  ///
  /// Called immediately on valid glench detection, before network transmission.
  /// Handles gracefully if haptic is unavailable (no error thrown).
  public static func triggerGlenchHaptic() {
    #if canImport(WatchKit)
      WKInterfaceDevice.current().play(.click)
    #endif
  }
}
