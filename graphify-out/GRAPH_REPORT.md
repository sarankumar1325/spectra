# Graph Report - system monitor  (2026-10-08)

## Corpus Check
- 20 files · ~10,369 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 233 nodes · 449 edges · 15 communities (13 shown, 2 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

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
- DotMatrixWaveformView
- View
- Spectra — Precision macOS System Monitor
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
- `.batteryDetailView` --calls--> `DotMatrixWaveformView`  [INFERRED]
  Sources/Spectra/UI/Views/SubsystemDetailView.swift → Sources/Spectra/UI/Components/DotMatrixWaveformView.swift
- `.cpuDetailView` --calls--> `DotMatrixWaveformView`  [INFERRED]
  Sources/Spectra/UI/Views/SubsystemDetailView.swift → Sources/Spectra/UI/Components/DotMatrixWaveformView.swift

## Import Cycles
- None detected.

## Communities (15 total, 2 thin omitted)

### Community 0 - "SubsystemDetailView"
Cohesion: 0.24
Nodes (16): Font, CGFloat, SubsystemDetailView, .alertsDetailView, .batteryDetailView, .bluetoothDetailView, .body, .cpuDetailView (+8 more)

### Community 1 - "NavigationSection"
Cohesion: 0.08
Nodes (21): CaseIterable, Foundation, NavigationSection, alerts, battery, bluetooth, cpu, disk (+13 more)

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
Cohesion: 0.22
Nodes (5): Date, Double, String, SystemTelemetryEngine, UInt64

### Community 6 - "AppState"
Cohesion: 0.11
Nodes (15): Never, AppState, .isolated, Bool, String, Void, HeaderBarView, .body (+7 more)

### Community 7 - "AppUsageTickerView"
Cohesion: 0.24
Nodes (8): AppUsageTickerView, .body, .drawerTrigger, .memoryPill, .powerPill, Binding, Bool, Double

### Community 8 - "SystemTelemetryEngine.swift"
Cohesion: 0.29
Nodes (6): CoreAudio, Darwin, IOKit, IOKit.ps, IOKit.storage, Metal

### Community 9 - "DotMatrixWaveformView"
Cohesion: 0.18
Nodes (13): Color, SpectraTheme, String, DotMatrixWaveformView, .body, Bool, CGFloat, Double (+5 more)

### Community 10 - "View"
Cohesion: 0.16
Nodes (13): Content, MemoryDistributionBar, .body, .inUsePercent, Double, Int, String, SidebarView (+5 more)

### Community 11 - "Spectra — Precision macOS System Monitor"
Cohesion: 0.29
Nodes (6): 🛠️ Architecture, Build macOS App Bundle, Build & Run from Command Line, 📸 Overview Reference, 🚀 Quick Start, Spectra — Precision macOS System Monitor

### Community 12 - "OverviewDashboardView"
Cohesion: 0.24
Nodes (7): OverviewDashboardView, .body, .processDrawer, Binding, Bool, Double, String

## Knowledge Gaps
- **52 isolated node(s):** `PackageDescription`, `.isolated`, `Darwin`, `IOKit`, `IOKit.ps` (+47 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 83 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `NavigationSection` connect `NavigationSection` to `SubsystemDetailView`, `SystemMetricsSnapshot`, `View`, `AppState`?**
  _High betweenness centrality (0.197) - this node is a cross-community bridge._
- **Why does `SystemMetricsSnapshot` connect `SystemMetricsSnapshot` to `SubsystemDetailView`, `NavigationSection`, `SystemTelemetryEngine`, `AppState`, `OverviewDashboardView`?**
  _High betweenness centrality (0.176) - this node is a cross-community bridge._
- **Why does `SubsystemDetailView` connect `SubsystemDetailView` to `NavigationSection`, `SystemMetricsSnapshot`, `View`, `AppState`?**
  _High betweenness centrality (0.124) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `.isolated`, `Darwin` to the rest of the system?**
  _52 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `NavigationSection` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Spectra — Precision macOS System Monitor` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `AppState` be split into smaller, more focused modules?**
  _Cohesion score 0.10666666666666667 - nodes in this community are weakly interconnected._