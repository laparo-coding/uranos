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

## Platforms

- iOS 18+
- watchOS 11+

## Related Repositories

| Repo | Description |
|------|-------------|
| [Gaia](https://github.com/laparo-coding/gaia) | Core platform services |
| [Hemera](https://github.com/laparo-coding/hemera) | Course management API |
| [Aither](https://github.com/laparo-coding/aither) | Slide generation & sync |
| [Thalassa](https://github.com/laparo-coding/thalassa) | Video analysis |

## License

MIT — see [LICENSE](LICENSE).
