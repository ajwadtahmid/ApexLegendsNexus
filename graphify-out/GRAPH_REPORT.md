# Graph Report - .  (2026-05-11)

## Corpus Check
- Large corpus: 134 files · ~1,344,605 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 117 nodes · 166 edges · 19 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 7 edges
2. `Create()` - 6 edges
3. `Destroy()` - 6 edges
4. `MessageHandler()` - 5 edges
5. `WndProc()` - 4 edges
6. `MainFlutterWindow` - 3 edges
7. `GeneratedPluginRegistrant` - 3 edges
8. `RunnerTests` - 3 edges
9. `GetClientArea()` - 3 edges
10. `UpdateTheme()` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.16
Nodes (16): Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle(), GetWindowClass(), MessageHandler(), OnCreate() (+8 more)

### Community 1 - "Community 1"
Cohesion: 0.36
Nodes (0): 

### Community 2 - "Community 2"
Cohesion: 0.33
Nodes (0): 

### Community 3 - "Community 3"
Cohesion: 0.27
Nodes (0): 

### Community 4 - "Community 4"
Cohesion: 0.22
Nodes (0): 

### Community 5 - "Community 5"
Cohesion: 0.25
Nodes (3): AppDelegate, FlutterAppDelegate, FlutterImplicitEngineDelegate

### Community 6 - "Community 6"
Cohesion: 0.32
Nodes (0): 

### Community 7 - "Community 7"
Cohesion: 0.38
Nodes (2): GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "Community 8"
Cohesion: 0.33
Nodes (0): 

### Community 9 - "Community 9"
Cohesion: 0.5
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 10 - "Community 10"
Cohesion: 0.5
Nodes (2): MainFlutterWindow, NSWindow

### Community 11 - "Community 11"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 12 - "Community 12"
Cohesion: 0.5
Nodes (2): RunnerTests, XCTestCase

### Community 13 - "Community 13"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 14 - "Community 14"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 15 - "Community 15"
Cohesion: 1.0
Nodes (1): macOS RunnerTests (XCTestCase stub)

### Community 16 - "Community 16"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Community 17"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "Community 18"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **4 isolated node(s):** `macOS RunnerTests (XCTestCase stub)`, `-registerWithRegistry`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `MainActivity`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 14`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (1 nodes): `macOS RunnerTests (XCTestCase stub)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 16`** (1 nodes): `Runner-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 17`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 18`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `macOS RunnerTests (XCTestCase stub)`, `-registerWithRegistry`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.` to the rest of the system?**
  _4 weakly-connected nodes found - possible documentation gaps or missing edges._