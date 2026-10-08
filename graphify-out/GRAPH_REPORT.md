# Graph Report - system monitor  (2026-10-09)

## Corpus Check
- 20 files · ~98,161 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 235 nodes · 451 edges · 14 communities (12 shown, 2 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `81a20531`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- SubsystemDetailView
- NavigationSection
- SystemMetricsSnapshot
- Spectra — Precision macOS System Monitor
- Spectra.swift
- SystemTelemetryEngine
- AppState
- AppUsageTickerView
- SystemTelemetryEngine.swift
- MemoryDistributionBar
- README.md
- OverviewDashboardView
- bundle_app.sh
- Package.swift

## God Nodes (most connected - your core abstractions)
1. `NavigationSection` - 27 edges
2. `SystemTelemetryEngine` - 21 edges
3. `SystemMetricsSnapshot` - 20 edges
4. `SubsystemDetailView` - 20 edges
5. `AppState` - 13 edges
6. `DotMatrixWaveformView` - 13 edges
7. `ProcessMetricItem` - 11 edges
8. `AppUsageTickerView` - 11 edges
9. `MemorySnapshot` - 10 edges
10. `BatterySnapshot` - 10 edges

## Surprising Connections (you probably didn't know these)
- `.projectsDetailView` --references--> `SystemMetricsSnapshot`  [INFERRED]
  Sources/Spectra/UI/Views/SubsystemDetailView.swift → Sources/Spectra/Models/SystemMetrics.swift
- `.body` --calls--> `SpectraMainView`  [INFERRED]
  Sources/Spectra/Spectra.swift → Sources/Spectra/UI/Views/SpectraMainView.swift
- `.body` --calls--> `AppUsageTickerView`  [INFERRED]
  Sources/Spectra/UI/Views/OverviewDashboardView.swift → Sources/Spectra/UI/Components/AppUsageTickerView.swift
- `.memoryDetailView` --calls--> `MemoryDistributionBar`  [INFERRED]
  Sources/Spectra/UI/Views/SubsystemDetailView.swift → Sources/Spectra/UI/Components/MemoryDistributionBar.swift
- `.body` --calls--> `SidebarView`  [INFERRED]
  Sources/Spectra/UI/Views/SpectraMainView.swift → Sources/Spectra/UI/Components/SidebarView.swift

## Import Cycles
- None detected.

## Communities (14 total, 2 thin omitted)

### Community 0 - "SubsystemDetailView"
Cohesion: 0.17
Nodes (23): Font, CGFloat, DotMatrixWaveformView, .body, Bool, CGFloat, Double, .body (+15 more)

### Community 1 - "NavigationSection"
Cohesion: 0.09
Nodes (23): CaseIterable, Content, NavigationSection, alerts, battery, bluetooth, cpu, disk (+15 more)

### Community 2 - "SystemMetricsSnapshot"
Cohesion: 0.16
Nodes (28): Identifiable, Int32, Sendable, BatterySnapshot, .preview, CoreLoadItem, CPUSnapshot, .preview (+20 more)

### Community 3 - "Spectra — Precision macOS System Monitor"
Cohesion: 0.13
Nodes (14): 1. Executive Summary & Vision, 2.1 Design Language, 2.2 Signature UI Components, 2. Visual Design System & UI Specification, 3. Low-Level System Telemetry Engine, 4. Project Structure & Architecture, 5. Implementation Roadmap, A. Dot-Matrix Waveform Chart (`DotMatrixWaveformView`) (+6 more)

### Community 4 - "Spectra.swift"
Cohesion: 0.17
Nodes (12): App, AppKit, CGSize, Notification, NSApplicationDelegate, NSObject, Scene, AppDelegate (+4 more)

### Community 5 - "SystemTelemetryEngine"
Cohesion: 0.21
Nodes (5): Date, Double, String, SystemTelemetryEngine, UInt64

### Community 6 - "AppState"
Cohesion: 0.10
Nodes (16): Never, AppState, .isolated, Bool, String, Void, SpectraTheme, HeaderBarView (+8 more)

### Community 7 - "AppUsageTickerView"
Cohesion: 0.24
Nodes (8): AppUsageTickerView, .body, .drawerTrigger, .memoryPill, .powerPill, Binding, Bool, Double

### Community 8 - "SystemTelemetryEngine.swift"
Cohesion: 0.12
Nodes (10): CoreAudio, Darwin, Foundation, IOKit, IOKit.ps, IOKit.storage, Metal, Spectra (+2 more)

### Community 9 - "MemoryDistributionBar"
Cohesion: 0.18
Nodes (13): Color, String, MemoryDistributionBar, .body, .inUsePercent, Double, Int, String (+5 more)

### Community 11 - "README.md"
Cohesion: 0.22
Nodes (8): 6 Core Subsystems, Build & Package Local App, Highlights, Interface Gallery, ⌨️ Keyboard Shortcuts, 🚀 Quick Start, Run from Command Line, 🛠️ System Architecture

### Community 12 - "OverviewDashboardView"
Cohesion: 0.25
Nodes (6): OverviewDashboardView, .processDrawer, Binding, Bool, Double, String

## Knowledge Gaps
- **55 isolated node(s):** `PackageDescription`, `.isolated`, `Darwin`, `IOKit`, `IOKit.ps` (+50 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 85 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NavigationSection` connect `NavigationSection` to `SystemTelemetryEngine.swift`, `SubsystemDetailView`, `SystemMetricsSnapshot`, `AppState`?**
  _High betweenness centrality (0.194) - this node is a cross-community bridge._
- **Why does `SystemMetricsSnapshot` connect `SystemMetricsSnapshot` to `SubsystemDetailView`, `NavigationSection`, `SystemTelemetryEngine`, `AppState`, `OverviewDashboardView`?**
  _High betweenness centrality (0.173) - this node is a cross-community bridge._
- **Why does `SubsystemDetailView` connect `SubsystemDetailView` to `NavigationSection`, `SystemMetricsSnapshot`, `AppState`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `.isolated`, `Darwin` to the rest of the system?**
  _55 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `NavigationSection` be split into smaller, more focused modules?**
  _Cohesion score 0.0873015873015873 - nodes in this community are weakly interconnected._
- **Should `Spectra — Precision macOS System Monitor` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `AppState` be split into smaller, more focused modules?**
  _Cohesion score 0.09686609686609686 - nodes in this community are weakly interconnected._