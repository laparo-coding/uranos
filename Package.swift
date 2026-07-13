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
  ],
  dependencies: [
    .package(url: "https://github.com/rollbar/rollbar-apple", from: "3.4.0")
  ],
  targets: [
    .target(
      name: "UranosCore",
      dependencies: [
        .product(name: "RollbarNotifier", package: "rollbar-apple")
      ]
    ),
    .target(
      name: "UranosWatchKit",
      dependencies: ["UranosCore"]
    ),
    .executableTarget(
      name: "UranosCLI",
      dependencies: ["UranosCore"]
    ),
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
