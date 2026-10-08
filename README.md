# Spectra - Precision macOS System Monitor

**Spectra** is a boutique macOS system telemetry and hardware monitor built with **SwiftUI** for Apple Silicon. 

Inspired by precision hardware instruments (Teenage Engineering, Elektron) and modern craft software (Linear, Raycast), Spectra features an obsidian dark UI, custom 60 FPS dot-matrix telemetry waveforms, color-coded subsystem cards, and a low-overhead native Darwin kernel polling engine.

---

## 📸 Overview Reference

- **6 Core Subsystems**: CPU (Blue), Memory (Green), GPU (Purple), Disk (Orange), Network (Cyan), Battery (Lime).
- **Custom Dot-Matrix Waveforms**: GPU-accelerated phosphor matrix charts rendered using SwiftUI `Canvas`.
- **Memory Distribution Bar**: Segmented real-time visualization of App, Wired, Compressed, Cached, and Free RAM.
- **Top Resource Consumers**: Instant process drawer displaying top CPU and memory consumers.
- **Dedicated Subsystem Views**: Deep dive into CPU cores, GPU shader load, disk volumes, network bandwidth, and hardware thermal sensors.

---

## 🚀 Quick Start

### Build & Run from Command Line
```bash
# Run directly with SPM
swift run

# Run tests
swift test
```

### Build macOS App Bundle
```bash
./bundle_app.sh

# Launch application
open Spectra.app
```

---

## 🛠️ Architecture

- **UI Framework**: SwiftUI 5 (macOS 14+ Sonoma & macOS 15+ Sequoia)
- **State Engine**: `@Observable` `AppState` with background actor polling loop at 1 Hz.
- **Low-Level Darwin APIs**:
  - `host_processor_info()` for tick-accurate CPU core statistics.
  - `host_statistics64()` with `vm_statistics64` for unified memory allocations.
  - `statfs()` for APFS volume capacity.
  - `getifaddrs()` for active network interface bandwidth deltas.
  - `IOPMPowerSource` for cycle counts, battery health, and wattage draw.
  - `Metal` default device inspection for GPU identification.
