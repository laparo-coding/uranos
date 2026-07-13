# uranos Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-07-13

## Active Technologies
- Swift 6.x (package targets), Swift 6.1 manifest + SwiftPM only, Foundation
- Apple Watch companion app (watchOS 11+, iOS 18+)
- In-memory cache patterns for Watch connectivity

## Project Structure

```
Sources/
  UranosCore/        # Shared business logic
  UranosWatchKit/    # WatchKit-specific extensions
  UranosCLI/         # Development CLI tool
Tests/
  UranosCoreTests/
  UranosWatchKitTests/
```

## Commands

- `swift build` - Compile the package and all targets.
- `swift test` - Run all Swift test targets.
- `swift run UranosCLI` - Run the CLI tool.
- `swift package update` - Update Swift package dependencies.
- `swift package dump-package` - Print the resolved manifest for inspection.

## Swift Style and .swift-format Conventions

- Use `.swift-format` as the source of truth for automated formatting and linting.
- Follow Swift API Design Guidelines:
	- Types use `UpperCamelCase`.
	- Functions, methods, and properties use `lowerCamelCase`.
- Prefer explicit access control (`public`, `internal`, `private`) over implicit defaults.
- Favor value types (`struct`, `enum`) where reference semantics are not required.
- Use `guard` for early exits and clear failure paths.
- Keep functions focused and limit complexity/length.
- Document public APIs with Swift doc comments (`///`).
- CI should run formatting/lint checks (`swift format lint`) and tests (`swift test`) to enforce consistency.

## Caveman Mode (Manual)

- Reference: `.github/caveman-mode.md`.
