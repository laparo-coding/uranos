# Module Architecture Contract: App Foundation

## Module Boundaries

### UranosCore

**Purpose**: Shared business logic and domain models

**Public API**:
- Domain models for Watch and iPhone
- Watch Connectivity coordination logic
- In-memory cache patterns

**Dependencies**: Foundation, WatchKit (for Connectivity types)

### UranosWatchKit

**Purpose**: watchOS-specific extensions and UI

**Public API**:
- Watch-specific extensions on UranosCore models
- UI helpers and view modifiers (future SwiftUI)
- Watch Connectivity delegates

**Dependencies**: UranosCore, WatchKit, Foundation

### UranosCLI

**Purpose**: Development and diagnostic tools

**Public API**:
- CLI commands for local development
- Diagnostic outputs

**Dependencies**: UranosCore, Foundation

## Communication Patterns

[To be detailed in Watch Connectivity contract]
