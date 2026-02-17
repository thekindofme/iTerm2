# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Fork Context

This is a fork (`thekindofme/iTerm2`) of the upstream iTerm2 (`gnachman/iTerm2`). The fork adds custom features — primarily tab grouping for the vertical tab bar — on top of upstream.

- **App name**: "yiTerm2" (bundle ID: `com.thekindofme.yiterm2`)
- **Auto-updates**: Disabled — the fork has no update feed
- **Remotes**: `origin` = `thekindofme/iTerm2`, `upstream` = `gnachman/iTerm2`
- **Workflow**: periodically merge upstream/master, develop features on `master` branch
- **Syncing**: `git fetch upstream && git merge upstream/master`

## Build & Run

```bash
make Development          # Debug build (requires valid signing or Xcode "Sign to Run Locally")
make Deployment           # Release build
make clean                # Clean all build artifacts
make paranoiddeps         # Rebuild ThirdParty deps in sandbox (needs cmake + rustup from brew)
```

If building from command line without a signing certificate, use xcodebuild directly:
```bash
xcodebuild -scheme iTerm2 -configuration Development -destination 'platform=macOS' \
  -skipPackagePluginValidation \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

The built app goes to Xcode's DerivedData (`~/Library/Developer/Xcode/DerivedData/iTerm2-*/Build/Products/Development/iTerm2.app`).

## Testing

```bash
tools/run_tests.expect ModernTests/iTermScriptFunctionCallTest/testSignature
```

Test locations:
- `ModernTests/` — Modern Swift test suite (Swift Testing framework)
- `iTerm2XCTests/` — Traditional XCTest suite
- `tests/` — Manual test scripts and data files

## Code Best Practices

- In Swift, use `it_fatalError` and `it_assert` instead of `fatalError` and `assert` (they produce useful crash logs).
- Don't write more than one line of inline JS, HTML, or CSS. Create a new file and load it using `iTermBrowserTemplateLoader.swift`.
- After creating a new file, `git add` it immediately. Use `git mv` for renames.
- Don't create dependency cycles. Use delegates or closures instead.
- The deployment target is macOS 12. No availability checks needed for older versions.
- Don't replace curly quotes with straight quotes. Same for apostrophes and single quotes.
- Little scripts or text files for manual testing go in `tests/`.

## Architecture

### Language Split

Objective-C dominates the core (~816 .m files): terminal emulation, session management, window management, text rendering. Swift (~512 files) is used for newer features: AI integration, browser, modern UI components. Both interoperate via bridging headers (`sources/iTerm2SharedARC-Bridging-Header.h`, `sources/iTerm2-Bridging-Header.h`).

### Application Flow

```
iTermApplication → iTermController → PseudoTerminal → PTYTab → PTYSession
   (NSApp)         (coordinator)     (window ctrl)    (tab)    (session)
                                                                  ↓
                                              PTYTask ← VT100Terminal → PTYTextView
                                             (process)  (emulation)     (rendering)
```

### Terminal Emulation Pipeline

```
Input bytes → VT100Parser → VT100Terminal → VT100ScreenMutableState → VT100Grid
              (tokenize)    (interpret)      (modify state)           (cell storage)
```

Parsers: `VT100AnsiParser`, `VT100CSIParser`, `VT100DCSParser`, `VT100XtermParser`, `VT100TmuxParser`, `VT100SixelParser`.

### Key Subsystems

- **Rendering**: Metal-accelerated via `iTermMetalDriver` with 30+ specialized renderers in `sources/Metal/Renderers/`.
- **Profiles**: `ProfileModel` (singleton for global, per-session for "divorced" profiles) + `iTermProfilePreferences` for access.
- **Shell integration**: `iTermShellHistoryController` + scripts in `submodules/iTerm2-shell-integration/` (bash/zsh/fish/tcsh).
- **tmux integration**: `TmuxController` + `TmuxGateway` — runs `tmux -CC` control mode, maps tmux windows to native tabs.
- **iTermServer**: Separate process keeping shells alive across app crashes.
- **AI integration**: `AITerm`, `ChatAgent`, `AIPluginClient` in sources/.
- **Browser**: `Browser/` directory + `WebExtensionsFramework/` Swift package for web extensions.

### Scripting/API

- **Python API** over WebSocket (protocol defined in `proto/api.proto`, library in `api/library/python/iterm2/`). Server: `iTermAPIServer`.
- **AppleScript** defined in `iTerm2.sdef`.

### Build Targets

| Target | Purpose |
|---|---|
| iTerm2 | Main application |
| iTerm2SharedARC | Shared code (ARC-enabled, contains most Swift) |
| iTerm2Shared | Shared code (non-ARC legacy) |
| iTermServer | Session server (keeps shells alive) |
| ShellLauncher | Shell launch helper |
| iTerm2SandboxedWorker | Sandboxed image processing |
| pidinfo | XPC service for process info |
| iTermSwiftPackages | Swift package dependencies (wraps WebExtensionsFramework) |

### ThirdParty Dependencies

Pre-built frameworks in `ThirdParty/` (rebuilt via `make paranoiddeps` when Xcode version changes):

| Library | Purpose |
|---|---|
| NMSSH | SSH client (wraps libssh2 + openssl) |
| Sparkle | Auto-updates |
| CoreParse | Parser framework |
| libsixel | Sixel graphics protocol |
| libgit2 | Git operations |
| librailroad_dsl | Rust DSL parser |
| Highlightr | Syntax highlighting |
| SwiftyMarkdown | Markdown rendering |
| fmdb | SQLite wrapper |

Internal UI frameworks: `BetterFontPicker/`, `ColorPicker/`, `SearchableComboListView/`.

### Xcode Version Gating

`last-xcode-version` tracks the Xcode used to build ThirdParty deps. On mismatch, the build script phase "Build binary dependencies if xcode version changed" fails. For minor version bumps, update the file: `xcodebuild -version > last-xcode-version`. For major jumps, run `make paranoiddeps`.

## Active Development Areas (Fork)

### 1. Tab Grouping (Vertical Tab Bar) — Primary Feature

Adds the ability to group tabs in the vertical (left) tab bar with collapsible group headers.

**Key new files:**
- `ThirdParty/PSMTabBarControl/source/PSMTabGroup.h/.m` — group model
- `ThirdParty/PSMTabBarControl/source/PSMTabGroupHeaderCell.h/.m` — header rendering

**Key modified files:**
- `ThirdParty/PSMTabBarControl/source/PSMTabBarControl.h/.m` — layout + group management
- `ThirdParty/PSMTabBarControl/source/PSMTabBarCell.h` — `selectedForGrouping` property
- `ThirdParty/PSMTabBarControl/source/PSMTabDragAssistant.h/.m` — group-aware dragging
- `sources/PseudoTerminal.m` — context menus, persistence, group operations

**Scope:** only applies to vertical (left) tab bar (`PSMTab_LeftTab`).

**Persistence:** groups serialized under `TERMINAL_ARRANGEMENT_TAB_GROUPS` key.

**Tests:** `iTerm2XCTests/PSMTabGroupTest.m`, `PSMTabBarControlGroupTest.m`, `PSMTabGroupArrangementTest.m`

### 2. Active Pane Border — Upstream Feature Extended in Fork

### 3. Window Radius Improvements — Fork Enhancement

## Fork-Specific Guidelines

- When adding new tab grouping functionality, follow the pattern in `PSMTabBarControl.m` vertical layout.
- Group header rendering follows `PSMTabGroupHeaderCell.m` patterns (SF Symbols, luminance-based text contrast).
- Tab grouping context menus are gated on vertical tab position — check `tabBarIsVertical` before adding group menu items.
- New group features need serialization support via `arrangementRepresentation` in `PSMTabGroup`.
- Keep tab grouping tests in dedicated test files (`PSMTabGroupTest.m`, `PSMTabBarControlGroupTest.m`, `PSMTabGroupArrangementTest.m`).
