import Foundation
import Darwin
import IOKit
import IOKit.ps
import IOKit.storage
import Metal
import CoreAudio

public final class SystemTelemetryEngine: @unchecked Sendable {
    public static let shared = SystemTelemetryEngine()
    
    // CPU tick tracking
    private var prevCPUTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)? = nil
    private var prevPerCoreTicks: [[UInt64]] = []
    
    // Network delta tracking
    private var prevNetworkBytes: (inBytes: UInt64, outBytes: UInt64, timestamp: Date)? = nil
    private var initialNetworkInBytes: UInt64 = 0
    private var initialNetworkOutBytes: UInt64 = 0
    
    // Disk I/O delta tracking
    private var prevDiskBytes: (readBytes: UInt64, writeBytes: UInt64, timestamp: Date)? = nil
    
    // Rolling history buffers (45 samples)
    private var cpuHistory: [Double] = Array(repeating: 0.05, count: 45)
    private var memoryHistory: [Double] = Array(repeating: 0.10, count: 45)
    private var gpuHistory: [Double] = Array(repeating: 0.05, count: 45)
    private var diskHistory: [Double] = Array(repeating: 0.05, count: 45)
    private var networkHistory: [Double] = Array(repeating: 0.05, count: 45)
    private var batteryHistory: [Double] = Array(repeating: 0.10, count: 45)
    
    private init() {
        // Initialize baseline network counters
        let (inBytes, outBytes) = fetchRawNetworkBytes()
        self.initialNetworkInBytes = inBytes
        self.initialNetworkOutBytes = outBytes
        self.prevNetworkBytes = (inBytes, outBytes, Date())
        
        // Initialize baseline disk counters
        let (readBytes, writeBytes) = fetchRawDiskBytes()
        self.prevDiskBytes = (readBytes, writeBytes, Date())
    }
    
    // MARK: - Primary Capture Pipeline
    public func captureSnapshot() -> SystemMetricsSnapshot {
        let (chipModel, uptime) = fetchSystemInfo()
        let thermal = fetchThermalState()
        let audioDevice = fetchDefaultAudioDevice()
        
        let cpu = fetchCPUMetrics()
        let memory = fetchMemoryMetrics()
        let gpu = fetchGPUMetrics(chipModel: chipModel)
        let disk = fetchDiskMetrics()
        let network = fetchNetworkMetrics()
        let battery = fetchBatteryMetrics()
        let processes = fetchRealProcesses()
        
        let totalProcMemGB = processes.reduce(0.0) { $0 + ($1.memoryMB / 1024.0) }
        let alerts = generateRealAlerts(disk: disk, memory: memory, battery: battery)
        
        return SystemMetricsSnapshot(
            chipModel: chipModel,
            uptimeString: uptime,
            thermalStateString: thermal,
            audioDeviceString: audioDevice,
            cpu: cpu,
            memory: memory,
            gpu: gpu,
            disk: disk,
            network: network,
            battery: battery,
            memoryByAppTotalGB: max(totalProcMemGB, memory.appGB),
            powerByAppTotalWatts: battery.isAvailable && battery.powerDrawWatts > 0 ? battery.powerDrawWatts : max(1.0, cpu.usagePercent * 0.15),
            topProcesses: processes,
            alerts: alerts
        )
    }
    
    // MARK: - 1. Real CPU Telemetry
    private func fetchCPUMetrics() -> CPUSnapshot {
        // A. Host CPU load info
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        var userPercent = 0.0
        var sysPercent = 0.0
        var totalPercent = 0.0
        
        let kerr = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let user = UInt64(cpuLoadInfo.cpu_ticks.0)
            let sys = UInt64(cpuLoadInfo.cpu_ticks.1)
            let idle = UInt64(cpuLoadInfo.cpu_ticks.2)
            let nice = UInt64(cpuLoadInfo.cpu_ticks.3)
            
            if let prev = prevCPUTicks {
                let userDelta = user >= prev.user ? user - prev.user : 0
                let sysDelta = sys >= prev.system ? sys - prev.system : 0
                let idleDelta = idle >= prev.idle ? idle - prev.idle : 0
                let niceDelta = nice >= prev.nice ? nice - prev.nice : 0
                let totalDelta = userDelta + sysDelta + idleDelta + niceDelta
                
                if totalDelta > 0 {
                    userPercent = (Double(userDelta) / Double(totalDelta)) * 100.0
                    sysPercent = (Double(sysDelta) / Double(totalDelta)) * 100.0
                    totalPercent = ((Double(userDelta + sysDelta + niceDelta)) / Double(totalDelta)) * 100.0
                }
            }
            prevCPUTicks = (user, sys, idle, nice)
        }
        
        // B. Per-Core CPU load info
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var coreItems: [CoreLoadItem] = []
        
        if host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo) == KERN_SUCCESS, let info = cpuInfo {
            let coreCount = Int(numCPUs)
            var currentCoreTicks: [[UInt64]] = []
            
            for i in 0..<coreCount {
                let base = i * Int(CPU_STATE_MAX)
                let u = UInt64(info[base + Int(CPU_STATE_USER)])
                let s = UInt64(info[base + Int(CPU_STATE_SYSTEM)])
                let id = UInt64(info[base + Int(CPU_STATE_IDLE)])
                let n = UInt64(info[base + Int(CPU_STATE_NICE)])
                currentCoreTicks.append([u, s, id, n])
                
                var coreUsage = totalPercent
                if i < prevPerCoreTicks.count {
                    let prev = prevPerCoreTicks[i]
                    let du = u >= prev[0] ? u - prev[0] : 0
                    let ds = s >= prev[1] ? s - prev[1] : 0
                    let did = id >= prev[2] ? id - prev[2] : 0
                    let dn = n >= prev[3] ? n - prev[3] : 0
                    let dTot = du + ds + did + dn
                    if dTot > 0 {
                        coreUsage = (Double(du + ds + dn) / Double(dTot)) * 100.0
                    }
                }
                
                // Typical Apple Silicon has 4 E-cores then P-cores
                let coreLabel = i < 4 ? "E-Core \(i + 1)" : "P-Core \(i - 3)"
                coreItems.append(CoreLoadItem(id: i, name: coreLabel, loadPercent: coreUsage))
            }
            prevPerCoreTicks = currentCoreTicks
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        
        // C. UNIX load averages
        var loadAvg: [Double] = [0.0, 0.0, 0.0]
        getloadavg(&loadAvg, 3)
        
        // D. Update history
        let normalized = min(max(totalPercent / 100.0, 0.02), 1.0)
        cpuHistory.removeFirst()
        cpuHistory.append(normalized)
        
        // Real average of recorded history
        let nonZeroHistory = cpuHistory.filter { $0 > 0.02 }
        let avgPercent = nonZeroHistory.isEmpty ? totalPercent : (nonZeroHistory.reduce(0.0, +) / Double(nonZeroHistory.count)) * 100.0
        
        return CPUSnapshot(
            usagePercent: totalPercent,
            load1Min: loadAvg[0],
            load5Min: loadAvg[1],
            load15Min: loadAvg[2],
            userPercent: userPercent,
            systemPercent: sysPercent,
            avgTodayPercent: avgPercent,
            cores: coreItems,
            history: cpuHistory
        )
    }
    
    // MARK: - 2. Real Memory Telemetry
    private func fetchMemoryMetrics() -> MemorySnapshot {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        let totalBytes = Double(ProcessInfo.processInfo.physicalMemory)
        let totalGB = totalBytes / 1_073_741_824.0
        
        var appGB = 0.0
        var wiredGB = 0.0
        var compressedGB = 0.0
        var cachedGB = 0.0
        var freeGB = 0.0
        
        if kerr == KERN_SUCCESS {
            let pageSize = Double(getpagesize())
            wiredGB = (Double(vmStats.wire_count) * pageSize) / 1_073_741_824.0
            appGB = (Double(vmStats.active_count) * pageSize) / 1_073_741_824.0
            compressedGB = (Double(vmStats.compressor_page_count) * pageSize) / 1_073_741_824.0
            cachedGB = (Double(vmStats.inactive_count) * pageSize) / 1_073_741_824.0
            freeGB = (Double(vmStats.free_count) * pageSize) / 1_073_741_824.0
        }
        
        let inUseGB = appGB + wiredGB + compressedGB
        let normalized = min(max(inUseGB / max(totalGB, 1.0), 0.05), 1.0)
        
        memoryHistory.removeFirst()
        memoryHistory.append(normalized)
        
        let isPressureHigh = (freeGB + cachedGB) < (totalGB * 0.12) || compressedGB > 4.5
        let pressureStatus = isPressureHigh ? "Pressure High" : "Pressure Normal"
        
        return MemorySnapshot(
            inUseGB: inUseGB,
            totalGB: totalGB,
            pressureStatus: pressureStatus,
            appGB: appGB,
            wiredGB: wiredGB,
            compressedGB: compressedGB,
            cachedGB: cachedGB,
            freeGB: freeGB,
            history: memoryHistory
        )
    }
    
    // MARK: - 3. Real GPU Telemetry (IOAccelerator / Metal)
    private func fetchGPUMetrics(chipModel: String) -> GPUSnapshot {
        var gpuName = chipModel
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            gpuName = metalDevice.name
        }
        
        var utilPercent = 0.0
        var memGB = 0.0
        
        // Query Apple Silicon IOAccelerator service for live GPU performance statistics
        let accel = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOAccelerator"))
        if accel != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(accel, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any],
               let stats = dict["PerformanceStatistics"] as? [String: Any] {
                
                if let devUtil = stats["Device Utilization %"] as? Int {
                    utilPercent = Double(devUtil)
                } else if let devUtil = stats["Device Utilization %"] as? Double {
                    utilPercent = devUtil
                }
                
                if let memBytes = stats["In use system memory"] as? UInt64 {
                    memGB = Double(memBytes) / 1_073_741_824.0
                }
            }
            IOObjectRelease(accel)
        }
        
        let normalized = min(max(utilPercent / 100.0, 0.02), 1.0)
        gpuHistory.removeFirst()
        gpuHistory.append(normalized)
        
        let nonZero = gpuHistory.filter { $0 > 0.02 }
        let avg = nonZero.isEmpty ? utilPercent : (nonZero.reduce(0.0, +) / Double(nonZero.count)) * 100.0
        let peak = (gpuHistory.max() ?? 0.0) * 100.0
        
        return GPUSnapshot(
            chipName: gpuName.uppercased(),
            utilizationPercent: utilPercent,
            memoryGB: memGB,
            avgTodayPercent: avg,
            peakTodayPercent: max(peak, utilPercent),
            history: gpuHistory
        )
    }
    
    // MARK: - 4. Real Disk I/O & Volumes Telemetry
    private func fetchDiskMetrics() -> DiskSnapshot {
        // A. Root volume space
        var stat = statfs()
        var totalGB = 0.0
        var freeGB = 0.0
        var usedGB = 0.0
        
        if statfs("/", &stat) == 0 {
            let totalBytes = UInt64(stat.f_blocks) * UInt64(stat.f_bsize)
            let freeBytes = UInt64(stat.f_bavail) * UInt64(stat.f_bsize)
            totalGB = Double(totalBytes) / 1_073_741_824.0
            freeGB = Double(freeBytes) / 1_073_741_824.0
            usedGB = max(0, totalGB - freeGB)
        }
        
        // B. Real Disk I/O read & write throughput via IOBlockStorageDriver
        let (currentReadBytes, currentWriteBytes) = fetchRawDiskBytes()
        var readSpeedMBs = 0.0
        var writeSpeedMBs = 0.0
        let now = Date()
        
        if let prev = prevDiskBytes {
            let elapsed = max(now.timeIntervalSince(prev.timestamp), 0.1)
            let readDelta = currentReadBytes >= prev.readBytes ? currentReadBytes - prev.readBytes : 0
            let writeDelta = currentWriteBytes >= prev.writeBytes ? currentWriteBytes - prev.writeBytes : 0
            
            readSpeedMBs = (Double(readDelta) / 1_048_576.0) / elapsed
            writeSpeedMBs = (Double(writeDelta) / 1_048_576.0) / elapsed
        }
        prevDiskBytes = (currentReadBytes, currentWriteBytes, now)
        
        // Total cumulative written bytes across all storage drivers
        let writtenTotalGB = Double(currentWriteBytes) / 1_073_741_824.0
        
        // C. Real mounted volumes
        var volumesList: [VolumeItem] = []
        let volumeUrls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey],
            options: [.skipHiddenVolumes]
        ) ?? []
        
        for url in volumeUrls {
            if let vals = try? url.resourceValues(forKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey]) {
                let name = vals.volumeName ?? url.lastPathComponent
                let tot = Double(vals.volumeTotalCapacity ?? 0) / 1_073_741_824.0
                let avail = Double(vals.volumeAvailableCapacity ?? 0) / 1_073_741_824.0
                if tot > 0 {
                    volumesList.append(VolumeItem(id: url.path, name: name, totalGB: tot, freeGB: avail))
                }
            }
        }
        
        let normalized = min(max((readSpeedMBs + writeSpeedMBs) / 100.0, 0.03), 1.0)
        diskHistory.removeFirst()
        diskHistory.append(normalized)
        
        return DiskSnapshot(
            freeGB: freeGB,
            totalGB: totalGB,
            usedGB: usedGB,
            readSpeedMBs: readSpeedMBs,
            writeSpeedMBs: writeSpeedMBs,
            writtenTotalGB: writtenTotalGB,
            volumes: volumesList,
            history: diskHistory
        )
    }
    
    private func fetchRawDiskBytes() -> (read: UInt64, write: UInt64) {
        var iter: io_iterator_t = 0
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0
        
        if IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iter) == KERN_SUCCESS {
            var driver = IOIteratorNext(iter)
            while driver != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(driver, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = props?.takeRetainedValue() as? [String: Any],
                   let stats = dict["Statistics"] as? [String: Any] {
                    totalRead += (stats["Bytes (Read)"] as? UInt64) ?? 0
                    totalWrite += (stats["Bytes (Write)"] as? UInt64) ?? 0
                }
                IOObjectRelease(driver)
                driver = IOIteratorNext(iter)
            }
            IOObjectRelease(iter)
        }
        return (totalRead, totalWrite)
    }
    
    // MARK: - 5. Real Network Bandwidth & Interfaces
    private func fetchNetworkMetrics() -> NetworkSnapshot {
        let (inBytes, outBytes) = fetchRawNetworkBytes()
        var dlSpeedKBs = 0.0
        var ulSpeedKBs = 0.0
        let now = Date()
        
        if let prev = prevNetworkBytes {
            let elapsed = max(now.timeIntervalSince(prev.timestamp), 0.1)
            let inDelta = inBytes >= prev.inBytes ? inBytes - prev.inBytes : 0
            let outDelta = outBytes >= prev.outBytes ? outBytes - prev.outBytes : 0
            
            dlSpeedKBs = (Double(inDelta) / 1024.0) / elapsed
            ulSpeedKBs = (Double(outDelta) / 1024.0) / elapsed
        }
        prevNetworkBytes = (inBytes, outBytes, now)
        
        // Cumulative volume for this boot session
        let totalDownloadedGB = Double(inBytes >= initialNetworkInBytes ? inBytes - initialNetworkInBytes : inBytes) / 1_073_741_824.0
        let totalUploadedGB = Double(outBytes >= initialNetworkOutBytes ? outBytes - initialNetworkOutBytes : outBytes) / 1_073_741_824.0
        
        // Active interfaces inspection
        let (activeIfName, interfaceList) = fetchNetworkInterfaces()
        
        let normalized = min(max(dlSpeedKBs / 200.0, 0.03), 1.0)
        networkHistory.removeFirst()
        networkHistory.append(normalized)
        
        return NetworkSnapshot(
            downloadSpeedKBs: dlSpeedKBs,
            uploadSpeedKBs: ulSpeedKBs,
            interfaceName: activeIfName,
            totalDownloadedGB: totalDownloadedGB,
            totalUploadedGB: totalUploadedGB,
            interfaces: interfaceList,
            history: networkHistory
        )
    }
    
    private func fetchRawNetworkBytes() -> (inBytes: UInt64, outBytes: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        var inBytes: UInt64 = 0
        var outBytes: UInt64 = 0
        
        if getifaddrs(&ifaddr) == 0, let first = ifaddr {
            var ptr: UnsafeMutablePointer<ifaddrs>? = first
            while let current = ptr {
                let name = String(cString: current.pointee.ifa_name)
                if (name.starts(with: "en") || name.starts(with: "pdp_ip")) && !name.contains("lo") {
                    if let data = current.pointee.ifa_data {
                        let ifData = data.assumingMemoryBound(to: if_data.self)
                        inBytes += UInt64(ifData.pointee.ifi_ibytes)
                        outBytes += UInt64(ifData.pointee.ifi_obytes)
                    }
                }
                ptr = current.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return (inBytes, outBytes)
    }
    
    private func fetchNetworkInterfaces() -> (active: String, list: [NetworkInterfaceItem]) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        var active = "Wi-Fi en0"
        var list: [NetworkInterfaceItem] = []
        
        if getifaddrs(&ifaddr) == 0, let first = ifaddr {
            var ptr: UnsafeMutablePointer<ifaddrs>? = first
            var seen = Set<String>()
            
            while let current = ptr {
                let name = String(cString: current.pointee.ifa_name)
                let flags = Int32(current.pointee.ifa_flags)
                let isUp = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0
                
                if let addr = current.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET), !seen.contains(name) {
                    seen.insert(name)
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                    let ip = String(decoding: host.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
                    
                    if isUp && (name.starts(with: "en") || name.starts(with: "pdp_ip")) {
                        active = "\(name) (\(ip))"
                    }
                    list.append(NetworkInterfaceItem(id: name, name: name, ipAddress: ip, isUp: isUp))
                }
                ptr = current.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return (active, list)
    }
    
    // MARK: - 6. Real Battery & Power Telemetry (AppleSmartBattery)
    private func fetchBatteryMetrics() -> BatterySnapshot {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return BatterySnapshot(
                isAvailable: false,
                chargePercent: 100,
                cycleCount: 0,
                remainingFormatted: "AC Power",
                powerDrawWatts: 0.0,
                healthPercent: 100,
                history: batteryHistory
            )
        }
        
        var charge = 100
        var isCharging = false
        var remainingMins = -1
        
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
                   let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int, maxCap > 0 {
                    charge = Int((Double(cur) / Double(maxCap)) * 100.0)
                }
                if let isChg = desc[kIOPSIsChargingKey as String] as? Bool {
                    isCharging = isChg
                }
                if let time = desc[kIOPSTimeToEmptyKey as String] as? Int {
                    remainingMins = time
                }
            }
        }
        
        // Real Cycle Count, Real Health %, and Real Wattage from AppleSmartBattery
        var realCycles = 0
        var realHealth = 100
        var realWatts = 0.0
        
        let batteryService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if batteryService != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(batteryService, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                
                if let cycles = dict["CycleCount"] as? Int {
                    realCycles = cycles
                }
                
                let maxCap = (dict["MaxCapacity"] as? Double) ?? (dict["MaxCapacity"] as? Int).map(Double.init) ?? 0.0
                let rawMaxCap = (dict["AppleRawMaxCapacity"] as? Double) ?? (dict["AppleRawMaxCapacity"] as? Int).map(Double.init) ?? (dict["NominalChargeCapacity"] as? Double) ?? (dict["NominalChargeCapacity"] as? Int).map(Double.init) ?? (maxCap > 100.0 ? maxCap : 0.0)
                let designCap = (dict["DesignCapacity"] as? Double) ?? (dict["DesignCapacity"] as? Int).map(Double.init) ?? 0.0
                
                if rawMaxCap > 0 && designCap > 0 {
                    realHealth = min(100, max(1, Int(round((rawMaxCap / designCap) * 100.0))))
                } else if maxCap > 0 && maxCap <= 100.0 {
                    realHealth = Int(maxCap)
                }
                
                let amperage = (dict["InstantAmperage"] as? Double) ?? (dict["InstantAmperage"] as? Int).map(Double.init) ?? (dict["Amperage"] as? Double) ?? 0.0
                let voltage = (dict["Voltage"] as? Double) ?? (dict["Voltage"] as? Int).map(Double.init) ?? 0.0
                if voltage > 0 {
                    realWatts = abs(amperage * voltage) / 1_000_000.0
                }
            }
            IOObjectRelease(batteryService)
        }
        
        let remainingStr: String
        if isCharging {
            remainingStr = "Charging"
        } else if remainingMins > 0 {
            let h = remainingMins / 60
            let m = remainingMins % 60
            remainingStr = "\(h)h \(m)m"
        } else {
            remainingStr = "-"
        }
        
        let normalized = Double(charge) / 100.0
        batteryHistory.removeFirst()
        batteryHistory.append(normalized)
        
        return BatterySnapshot(
            isAvailable: true,
            chargePercent: charge,
            cycleCount: realCycles,
            remainingFormatted: remainingStr,
            powerDrawWatts: realWatts,
            healthPercent: realHealth,
            history: batteryHistory
        )
    }
    
    // MARK: - 7. Real Processes from libproc
    private func fetchRealProcesses() -> [ProcessMetricItem] {
        var numPids = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard numPids > 0 else { return [] }
        
        var pids = [pid_t](repeating: 0, count: Int(numPids))
        numPids = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, numPids * Int32(MemoryLayout<pid_t>.size))
        
        var list: [ProcessMetricItem] = []
        for pid in pids where pid > 0 {
            var taskInfo = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            if proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size) == size {
                var nameBuf = [CChar](repeating: 0, count: 256)
                proc_name(pid, &nameBuf, 256)
                let name = String(decoding: nameBuf.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
                
                if !name.isEmpty && name != "kernel_task" {
                    let memMB = Double(taskInfo.pti_resident_size) / (1024.0 * 1024.0)
                    if memMB > 1.0 {
                        list.append(ProcessMetricItem(id: pid, name: name, cpuPercent: 0.0, memoryMB: memMB))
                    }
                }
            }
        }
        
        list.sort { $0.memoryMB > $1.memoryMB }
        return Array(list.prefix(8))
    }
    
    // MARK: - 8. Real System Info & CoreAudio
    private func fetchSystemInfo() -> (chip: String, uptime: String) {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let rawModel = String(decoding: model.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        
        var chip = "Apple Silicon"
        var cpuSize = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &cpuSize, nil, 0)
        if cpuSize > 0 {
            var brand = [CChar](repeating: 0, count: cpuSize)
            sysctlbyname("machdep.cpu.brand_string", &brand, &cpuSize, nil, 0)
            chip = String(decoding: brand.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
        if !chip.contains("Apple") {
            if let metal = MTLCreateSystemDefaultDevice() {
                chip = metal.name
            } else if !rawModel.isEmpty {
                chip = rawModel
            }
        }
        
        let uptimeSecs = Int(ProcessInfo.processInfo.systemUptime)
        let hours = uptimeSecs / 3600
        let minutes = (uptimeSecs % 3600) / 60
        let uptimeStr = "up \(hours)h \(minutes)m"
        
        return (chip, uptimeStr)
    }
    
    private func fetchThermalState() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal (Normal)"
        case .fair: return "Fair (Elevated)"
        case .serious: return "Serious (Throttling)"
        case .critical: return "Critical (High Heat)"
        @unknown default: return "Nominal"
        }
    }
    
    private func fetchDefaultAudioDevice() -> String {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )
        
        if status == noErr {
            var nameCF: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            withUnsafeMutablePointer(to: &nameCF) { ptr in
                _ = AudioObjectGetPropertyData(defaultOutputDeviceID, &nameAddress, 0, nil, &nameSize, ptr)
            }
            return nameCF as String
        }
        return "Internal Audio"
    }
    
    private func generateRealAlerts(disk: DiskSnapshot, memory: MemorySnapshot, battery: BatterySnapshot) -> [SystemAlertItem] {
        var alerts: [SystemAlertItem] = []
        if disk.totalGB > 0 && (disk.freeGB / disk.totalGB) < 0.15 {
            alerts.append(SystemAlertItem(
                id: "disk_space",
                title: "Storage Space Advisory",
                message: "Macintosh HD free space is under 15% (\(Int(disk.freeGB)) GB free of \(Int(disk.totalGB)) GB).",
                isWarning: true
            ))
        }
        if memory.pressureStatus == "Pressure High" {
            alerts.append(SystemAlertItem(
                id: "mem_pressure",
                title: "Memory Pressure Warning",
                message: "System memory pressure is elevated with active compression.",
                isWarning: true
            ))
        }
        if battery.isAvailable && battery.chargePercent < 20 {
            alerts.append(SystemAlertItem(
                id: "bat_low",
                title: "Battery Charge Low",
                message: "Battery level is at \(battery.chargePercent)%. Connect to power.",
                isWarning: true
            ))
        }
        return alerts
    }
}
