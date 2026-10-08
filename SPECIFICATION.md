# Spectra — Precision macOS System Monitor
### Architectural Specification & Product Plan

---

## 1. Executive Summary & Vision

**Spectra** is a boutique, pro-grade system telemetry application built exclusively for macOS and Apple Silicon using **SwiftUI**. 

Unlike standard system monitors that present generic tables or flat charts, Spectra draws inspiration from high-end analog/digital hardware synthesizers (Teenage Engineering, Elektron) and precision engineering tools (Linear, Raycast). It delivers a striking **dark obsidian aesthetic**, **color-coded subsystem cards**, and **custom dithered/dot-matrix waveform telemetry** running at 60 FPS with near-zero (<0.5%) CPU overhead.

---

## 2. Visual Design System & UI Specification

### 2.1 Design Language
- **Window Presentation**: Unified title bar with integrated traffic lights, sidebar toggle, floating vibrancy (`.ultraThinMaterial` / custom deep dark surface `#141416`).
- **Color Palette & Accents**:
  - Background Base: `#121214` (Deep Obsidian)
  - Card Surfaces: `#1B1B1E` with subtle 1px border `#2A2A30` and 12px corner radii.
  - Subsystem Color Signatures:
    - **CPU**: Electric Blue (`#3B82F6` / `#60A5FA`)
    - **Memory**: Terminal Emerald (`#22C55E` / `#4ADE80`)
    - **GPU**: Vivid Magenta / Violet (`#C084FC` / `#E879F9`)
    - **Disk**: Amber Tangerine (`#F97316` / `#FB923C`)
    - **Network**: Neon Aqua / Cyan (`#06B6D4` / `#22D3EE`)
    - **Battery**: Chartreuse Lime (`#84CC16` / `#A3E635`)
- **Typography**:
  - Metric Headers: `SF Pro Display`, Semibold, uppercase tracking.
  - Large Metric Heroes: `SF Pro Display` / `SF Mono`, Bold (e.g. `29%`, `22.32 GB`).
  - Readout Data & Telemetry: `SF Mono` / Tabular Digits to prevent metric jitter.

### 2.2 Signature UI Components

#### A. Dot-Matrix Waveform Chart (`DotMatrixWaveformView`)
- Custom SwiftUI `Canvas` implementation.
- Renders historical telemetry samples as a 2D matrix of discrete circular or square phosphor dots.
- Two distinct layers:
  1. **Background Fill**: Low-opacity phosphor dots below the current value curve.
  2. **Crest Line**: High-luminance, full-brightness dots tracing the real-time wave peak.
- Extremely lightweight: direct CoreGraphics rendering within `Canvas`, zero allocation per frame.

#### B. Subsystem Metric Cards (2x3 Responsive Grid)
- **CPU Card**: Current usage %, system load (1m/5m/15m avg), User vs System breakdown, 30s dot waveform.
- **Memory Card**: In-use RAM vs total RAM, pressure state indicator (Normal / Warning / Critical), App vs Wired vs Compressed breakdown.
- **GPU Card**: Apple Silicon GPU utilization %, unified GPU memory allocation, peak today & average metrics.
- **Disk Card**: Free space vs capacity, live reading/writing throughput (MB/s), total written today.
- **Network Card**: Current download/upload speed (kB/s or MB/s), active interface (`en0` / Wi-Fi), daily transfer volume.
- **Battery Card**: Charge %, cycle count, live wattage draw (W), battery health %.

#### C. Memory by Type Segmented Distribution Bar
- Continuous multi-colored progress bar breakdown:
  - `App` (Emerald) → `Wired` (Amber) → `Compressed` (Magenta) → `Cached` (Blue) → `Free` (Dark Slate).
  - Accurate live GB labels and percentage in use.

#### D. Resource Consumers Bar
- Live top consumers: `Memory by App` and `Power / CPU by App` with instant process filtering.

---

## 3. Low-Level System Telemetry Engine

Spectra interfaces directly with macOS Darwin / Mach kernel APIs and Apple Silicon hardware controllers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Spectra SwiftUI Presentation Layer                  │
│       (@Observable SystemMetricsState, 60 FPS Canvas Waveforms)        │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Publishes updates @ 1.0 Hz
┌───────────────────────────────────┴────────────────────────────────────┐
│                    SystemTelemetryEngine (Swift Actor)                 │
├─────────────────┬──────────────────┬─────────────────┬─────────────────┤
│    CPUEngine    │   MemoryEngine   │    GPUEngine    │   DiskEngine    │
│ host_processor_ │  host_statistics │  IOReport/Metal │  statfs/IOKit   │
│      info       │   vm_statistics  │  IOAccelerator  │  storage driver │
├─────────────────┴──────────────────┴─────────────────┴─────────────────┤
│   NetworkEngine (getifaddrs)  │  BatteryEngine (IOPSCopyPowerSources)  │
│   ProcessEngine (libproc)     │  SensorsEngine (Apple SMC / HID)       │
└────────────────────────────────────────────────────────────────────────┘
```

### Low-Level API Specifications:
1. **CPU & Cores**:
   - `host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, ...)`
   - Computes tick deltas across User, System, Idle, and Nice states.
   - Core topology detection: identifies Efficiency (E-cores) vs Performance (P-cores).
   - `getloadavg()` for UNIX load averages.
2. **Memory**:
   - `host_statistics64(mach_host_self(), HOST_VM_INFO64, ...)`
   - Extracts `active_count`, `inactive_count`, `wire_count`, `compressor_page_count`, and `free_count`.
   - Page-to-byte conversion via `vm_kernel_page_size`.
3. **GPU (Apple Silicon)**:
   - Queries `IOAccelerator` service via IOKit and Metal framework device query (`MTLCopyAllDevices()`).
   - Unified memory GPU footprint extraction.
4. **Disk I/O**:
   - `statfs()` / `statvfs()` for mounted volume capacity and mount points.
   - `IOBlockStorageDriver` properties via IOKit registry for disk read/write bytes per second.
5. **Network**:
   - `getifaddrs()` iteration across active interfaces (`en0`, `en1`, `pdp_ip0`).
   - Delta differential over sample time intervals to calculate exact download and upload rates.
6. **Battery & Power**:
   - `IOPMPowerSource` via `IOPSCopyPowerSourcesInfo()` and `IOPSGetPowerSourceDescription()`.
   - Wattage calculation, cycle count, designed vs current capacity health.
7. **Processes**:
   - `proc_listpids()` and `proc_pidinfo()` (`PROC_PIDTASKINFO`) for top CPU and memory consumers.

---

## 4. Project Structure & Architecture

```
system monitor/
├── SPECIFICATION.md                 # Architectural & Design specification
├── Package.swift                    # Swift Package / App configuration
├── Sources/
│   └── Spectra/
│       ├── App/
│       │   ├── SpectraApp.swift     # App entry point, Window & MenuBar setup
│       │   └── AppState.swift       # Global application state & navigation
│       ├── Engine/
│       │   ├── SystemTelemetryEngine.swift # Central actor coordinator
│       │   ├── CPUEngine.swift             # Host processor & per-core counters
│       │   ├── MemoryEngine.swift          # VM statistics & memory pressure
│       │   ├── GPUEngine.swift             # Metal & Apple Silicon GPU monitor
│       │   ├── DiskEngine.swift            # Volume stats & disk I/O throughput
│       │   ├── NetworkEngine.swift         # Interface bandwidth deltas
│       │   ├── BatteryEngine.swift         # IOPowerSources telemetry
│       │   └── ProcessEngine.swift         # libproc process list & resource hogs
│       ├── Models/
│       │   ├── SystemMetrics.swift         # Snapshot metric representations
│       │   ├── TelemetryHistory.swift      # Circular ring buffers for waveform charts
│       │   └── ProcessItem.swift           # Lightweight process data structures
│       ├── Theme/
│       │   ├── SpectraColors.swift         # Harmonious color tokens
│       │   └── SpectraTypography.swift     # Font styles & tabular alignment
│       └── UI/
│           ├── Components/
│           │   ├── DotMatrixWaveformView.swift # Custom Canvas-based dotted waveform
│           │   ├── MetricCardView.swift        # Subsystem telemetry card
│           │   ├── MemoryDistributionBar.swift # Segmented memory bar
│           │   ├── SidebarView.swift           # Navigation sidebar
│           │   └── AppUsageTickerView.swift    # Top consumers footer
│           └── Views/
│               ├── OverviewDashboardView.swift # Main reference dashboard
│               ├── SubsystemDetailView.swift   # Dedicated tabs (CPU, RAM, etc.)
│               └── HeaderBarView.swift         # Mac model, uptime, search filter
└── Tests/
    └── SpectraTests/
        └── TelemetryTests.swift
```

---

## 5. Implementation Roadmap

- [x] **Milestone 1: Specification & Design Blueprint** (`SPECIFICATION.md`)
- [ ] **Milestone 2: Swift Project Initialization & Setup**
  - Set up native Swift executable package configured for macOS 14+ / Sonoma / Sequoia.
- [ ] **Milestone 3: Low-Level Darwin & Mach Telemetry Engine**
  - Implement zero-overhead C-bridge Darwin calls for CPU, Memory, GPU, Disk, Network, Battery.
- [ ] **Milestone 4: Custom Canvas Dot-Matrix Telemetry Visualizer**
  - Implement phosphor dot-matrix rendering with custom color shaders and historical ring buffers.
- [ ] **Milestone 5: Dashboard Assembly (Pixel-Perfect to Mockup)**
  - Sidebar with icons, header with chip model and uptime, 6 metric cards, segmented memory bar, app tickers.
- [ ] **Milestone 6: Verification, Performance Profiling & Standalone App Build**
  - Validate on Apple Silicon macOS, ensuring CPU usage < 0.5% and 60 FPS smooth rendering.
