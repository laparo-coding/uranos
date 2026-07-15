// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "Uranos",
  platforms: [
    .iOS(.v18),
    .watchOS(.v11),
  ],
  products: [
    .library(name: "UranosCore", targets: ["UranosCore"]),
    .library(name: "UranosWatchKit", targets: ["UranosWatchKit"]),
    .executable(name: "UranosCLI", targets: ["UranosCLI"]),
    // UranosWatchApp is built via Xcode (requires WatchKit on watchOS).
  ],
  dependencies: [
    // Rollbar removed: incompatible with watchOS 11 deployment target.
    // UranosLogger provides structured logging without external dependencies.
  ],
  targets: [
    .target(
      name: "UranosCore",
      dependencies: []
    ),
    .target(
      name: "UranosWatchKit",
      dependencies: ["UranosCore"]
    ),
    .executableTarget(
      name: "UranosCLI",
      dependencies: ["UranosCore"]
    ),
    // UranosWatchApp target omitted — built via Xcode (WatchKit not available in SwiftPM on macOS).
    .testTarget(
      name: "UranosCoreTests",
      dependencies: ["UranosCore"]
    ),
    .testTarget(
      name: "UranosWatchKitTests",
      dependencies: ["UranosWatchKit"]
    ),
  ]
)
