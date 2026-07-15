import SwiftUI
import UranosCore
import UranosWatchKit

/// Main view for the Uranos Watch app.
///
/// Displays the current transmission state and provides a manual glench trigger
/// for testing on the simulator (where accelerometer/gyroscope is not available).
struct ContentView: View {

  @ObservedObject var appDelegate: UranosAppDelegate

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "hand.tap.fill")
        .font(.system(size: 40))
        .foregroundStyle(.tint)

      Text("Uranos")
        .font(.headline)

      Text(stateLabel)
        .font(.caption)
        .foregroundStyle(stateColor)

      Text("Queue: \(appDelegate.queueCount)")
        .font(.caption2)
        .foregroundStyle(.secondary)

      Button("Glench") {
        appDelegate.handleGlench()
      }
      .buttonStyle(.borderedProminent)
      .tint(.blue)
    }
    .padding()
  }

  private var stateLabel: String {
    switch appDelegate.transmissionState {
    case .pending:
      return "Bereit"
    case .sent:
      return "Gesendet ✓"
    case .failed:
      return "Fehlgeschlagen"
    }
  }

  private var stateColor: Color {
    switch appDelegate.transmissionState {
    case .pending:
      return .gray
    case .sent:
      return .green
    case .failed:
      return .red
    }
  }
}
