# Uranos

Apple Watch companion app for the [Laparo Academy](https://github.com/laparo-coding) ecosystem.

## Overview

Uranos provides Apple Watch integration for the Laparo Academy platform, enabling quick access to course controls, slide navigation, and real-time session status directly from the wrist.

## Architecture

```
Sources/
  UranosCore/        # Shared business logic, models, networking
  UranosWatchKit/    # WatchKit-specific extensions and UI helpers
  UranosCLI/         # Development CLI tool
Tests/
  UranosCoreTests/
  UranosWatchKitTests/
```

## Development

```bash
# Build all targets
swift build

# Run tests
swift test

# Lint with swift-format
swift format lint --configuration .swift-format --strict --recursive Sources Tests

# Format code
swift format --configuration .swift-format --recursive Sources Tests
```

## Platform Requirements

- **Xcode 16+** with watchOS 11+ SDK
- **Swift 6.1+** (toolchain)
- **watchOS 11+** (deployment target)
- **iOS 18+** (companion app deployment target)
- **VS Code** with the [`swiftlang.swift-vscode`](https://marketplace.visualstudio.com/items?itemName=swiftlang.swift-vscode) extension
- **SwiftPM** as the canonical build and dependency system

For deployment details, see `docs/WATCHOS-DEPLOYMENT.md`.

## Authentication Setup

Uranos communicates with the Aither API using a Bearer token. Configure the
token before running the app:

1. Copy `.env.local.example` to `.env.local`
2. Set `AITHER_BEARER_TOKEN` to your Aither API token
3. The token is loaded at app startup and passed to `AitherAPIClient`

```bash
cp .env.local.example .env.local
# Edit .env.local and add your token
```

> ⚠️ Never commit `.env.local` — it is gitignored by default.

## VS Code Tasks

| Task | Command | Shortcut |
|------|---------|----------|
| Build Debug | `swift build -c debug` | `Cmd+Shift+B` |
| Test | `swift test` | `Cmd+Shift+T` (task list) |
| Format | `swift format format -i -r Sources Tests` | task list |
| Lint | `swift format lint --strict -r Sources Tests` | task list |

## Related Repositories

| Repo | Description |
|------|-------------|
| [Gaia](https://github.com/laparo-coding/gaia) | Core platform services |
| [Hemera](https://github.com/laparo-coding/hemera) | Course management API |
| [Aither](https://github.com/laparo-coding/aither) | Slide generation & sync |
| [Thalassa](https://github.com/laparo-coding/thalassa) | Video analysis |

## License

MIT — see [LICENSE](LICENSE).
