# watchOS Deployment Guide

## Requirements

- Xcode 16+ with watchOS 11 SDK installed
- Apple Developer account with valid Team ID
- Provisioning profile for watchOS target
- Swift 6.1+ toolchain

## Local Validation

Run before deployment:

```bash
swift build
swift test
swift format lint --configuration .swift-format --strict Package.swift
swift format lint --configuration .swift-format --strict --recursive Sources Tests
```

## Signing Notes

- Ensure Watch app bundle identifier matches provisioning profile
- Select the correct signing team in Xcode if building app bundles
- For SwiftPM-only flows, keep core logic validated via CLI (`swift build`, `swift test`)

## Troubleshooting

- **Missing watchOS SDK**: Update/install Xcode 16+
- **Signing errors**: Recreate provisioning profile and verify Team ID
- **Runtime API mismatch**: Ensure minimum deployment targets are watchOS 11 / iOS 18
