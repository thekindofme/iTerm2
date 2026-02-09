---
name: iterm2-dev-setup
description: >
  Set up and build iTerm2 from source for local development. Use when:
  (1) Setting up the iTerm2 development environment from a fresh clone,
  (2) Troubleshooting build failures (code signing, Xcode version mismatch, missing Metal Toolchain),
  (3) Running iTerm2 tests,
  (4) Rebuilding after Xcode updates.
  Triggers: "build iterm2", "setup iterm2", "dev environment", "build fails", "make Development", "code signing error", "xcode version mismatch".
---

# iTerm2 Development Setup

## Prerequisites

- Xcode with command line tools
- Metal Toolchain: `xcodebuild -downloadComponent MetalToolchain`

## Build Steps

### 1. Initialize submodules

```bash
git submodule update --init --recursive
```

### 2. Fix Xcode version mismatch

The build script phase "Build binary dependencies if xcode version changed" compares `last-xcode-version` against your Xcode. If mismatched:

- **Minor version difference** (e.g., 26.0 vs 26.0.1): safe to update the file:
  ```bash
  xcodebuild -version > last-xcode-version
  ```
- **Major version jump**: rebuild deps (requires `cmake` and `rustup` via brew):
  ```bash
  make paranoiddeps
  ```

### 3. Build with code signing bypassed

The project uses team ID `H7V7XYVQ7D` (original developer). Bypass for local dev:

```bash
xcodebuild -scheme iTerm2 -configuration Development -destination 'platform=macOS' \
  -skipPackagePluginValidation \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

Note: `make Development` does NOT pass code signing overrides. It only works if you have a matching certificate or modify signing settings in Xcode to "Sign to Run Locally".

### 4. Run

```bash
open ~/Library/Developer/Xcode/DerivedData/iTerm2-*/Build/Products/Development/iTerm2.app
```

For Xcode debugging: `open iTerm2.xcodeproj`, set signing to "Sign to Run Locally", then Cmd+R.

## Running Tests

```bash
tools/run_tests.expect ModernTests/iTermScriptFunctionCallTest/testSignature
```

## Key Makefile Targets

| Target | Purpose |
|---|---|
| `make Development` | Debug build (needs valid signing) |
| `make Deployment` | Release build |
| `make clean` | Clean all build artifacts |
| `make paranoiddeps` | Rebuild ThirdParty deps in sandbox (needs cmake + rustup) |

## Common Build Failures

| Error | Fix |
|---|---|
| "No Mac Development signing certificate" | Add `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` |
| "xcode version is out of sync" | Update `last-xcode-version` or run `make paranoiddeps` |
| "cannot execute tool 'metal'" | Run `xcodebuild -downloadComponent MetalToolchain` |
| `make` not found (zsh autoload) | Use `/usr/bin/make` or full xcodebuild command directly |
