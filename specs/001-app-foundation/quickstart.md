# Quick Start: App Foundation

## Prerequisites

- Xcode 16+ with watchOS 11 SDK
- Swift 6.1+
- VS Code with swiftlang.swift-vscode extension
- Aither API credentials (token for authentication)

## Local Setup

```bash
cd uranos
swift build
swift test
swift format lint
```

## Configuring Authentication

1. Obtain Aither API token (use same token as Gaia)
2. Store token in environment or `.env.local` file:
   ```
   AITHER_BEARER_TOKEN=<your-token-here>
   ```
3. App loads token at startup and uses it for all API requests

## Building for watchOS

### Simulator

```bash
swift build -c debug
# Then run via Xcode simulator
```

### Physical Device

```bash
# Requires provisioning profiles and code signing
swift build -c release -Xswiftc -suppress-warnings
```

## Running Tests

```bash
swift test
```

## Testing Glench Action

### Simulator

1. Build and run app in Watch simulator
2. Trigger glench gesture (simulator keyboard shortcut or menu)
3. Verify:
   - [ ] Haptic feedback plays
   - [ ] Timestamp appears in logs
   - [ ] API request appears in network logs (or Aither logs)

### Physical Device

1. Build and install to Watch
2. Perform glench gesture on device
3. Verify:
   - [ ] Haptic feedback is tactile
   - [ ] App logs timestamp event
   - [ ] Aither receives transmission

## Debugging

### View Logs

```bash
# Xcode console
xcrun log stream --predicate 'process == "uranos"' --level debug
```

### Check API Connectivity

```bash
curl -H "Authorization: Bearer $AITHER_BEARER_TOKEN" \
     -X POST "${AITHER_API_URL:-http://localhost:3000/api/recording/timestamp}" \
     -H "Content-Type: application/json" \
     -d '{"timestamp": 1720380913}'
```

## Next Steps

1. Run the spec through `speckit.plan` to generate `plan.md`
2. Generate tasks with `speckit.tasks`
3. Begin implementation following the development checklist
4. Validate against acceptance criteria in `checklists/requirements.md`
