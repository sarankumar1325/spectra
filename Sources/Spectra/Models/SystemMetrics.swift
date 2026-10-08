import Foundation

public struct ProcessMetricItem: Identifiable, Sendable {
    public let id: Int32 // Real PID
    public let name: String
    public let cpuPercent: Double
    public let memoryMB: Double
    
    public init(id: Int32, name: String, cpuPercent: Double, memoryMB: Double) {
        self.id = id
        self.name = name
        self.cpuPercent = cpuPercent
        self.memoryMB = memoryMB
    }
}

public struct CoreLoadItem: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let loadPercent: Double
    
    public init(id: Int, name: String, loadPercent: Double) {
        self.id = id
        self.name = name
        self.loadPercent = loadPercent
    }
}

public struct VolumeItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let totalGB: Double
    public let freeGB: Double
    public var usedGB: Double { max(0, totalGB - freeGB) }
    
    public init(id: String, name: String, totalGB: Double, freeGB: Double) {
        self.id = id
        self.name = name
        self.totalGB = totalGB
        self.freeGB = freeGB
    }
}

public struct NetworkInterfaceItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let ipAddress: String
    public let isUp: Bool
    
    public init(id: String, name: String, ipAddress: String, isUp: Bool) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.isUp = isUp
    }
}

public struct CPUSnapshot: Sendable {
    public var usagePercent: Double
    public var load1Min: Double
    public var load5Min: Double
    public var load15Min: Double
    public var userPercent: Double
    public var systemPercent: Double
    public var avgTodayPercent: Double
    public var cores: [CoreLoadItem]
    public var history: [Double]
    
    public static var preview: CPUSnapshot {
        CPUSnapshot(
            usagePercent: 0.0,
            load1Min: 0.0,
            load5Min: 0.0,
            load15Min: 0.0,
            userPercent: 0.0,
            systemPercent: 0.0,
            avgTodayPercent: 0.0,
            cores: [],
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct MemorySnapshot: Sendable {
    public var inUseGB: Double
    public var totalGB: Double
    public var pressureStatus: String
    public var appGB: Double
    public var wiredGB: Double
    public var compressedGB: Double
    public var cachedGB: Double
    public var freeGB: Double
    public var usedPercent: Double {
        totalGB > 0 ? (inUseGB / totalGB) * 100.0 : 0.0
    }
    public var history: [Double]
    
    public static var preview: MemorySnapshot {
        MemorySnapshot(
            inUseGB: 0.0,
            totalGB: 0.0,
            pressureStatus: "Pressure Normal",
            appGB: 0.0,
            wiredGB: 0.0,
            compressedGB: 0.0,
            cachedGB: 0.0,
            freeGB: 0.0,
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct GPUSnapshot: Sendable {
    public var chipName: String
    public var utilizationPercent: Double
    public var memoryGB: Double
    public var avgTodayPercent: Double
    public var peakTodayPercent: Double
    public var history: [Double]
    
    public static var preview: GPUSnapshot {
        GPUSnapshot(
            chipName: "Apple Silicon",
            utilizationPercent: 0.0,
            memoryGB: 0.0,
            avgTodayPercent: 0.0,
            peakTodayPercent: 0.0,
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct DiskSnapshot: Sendable {
    public var freeGB: Double
    public var totalGB: Double
    public var usedGB: Double
    public var readSpeedMBs: Double
    public var writeSpeedMBs: Double
    public var writtenTotalGB: Double
    public var volumes: [VolumeItem]
    public var history: [Double]
    
    public static var preview: DiskSnapshot {
        DiskSnapshot(
            freeGB: 0.0,
            totalGB: 0.0,
            usedGB: 0.0,
            readSpeedMBs: 0.0,
            writeSpeedMBs: 0.0,
            writtenTotalGB: 0.0,
            volumes: [],
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct NetworkSnapshot: Sendable {
    public var downloadSpeedKBs: Double
    public var uploadSpeedKBs: Double
    public var interfaceName: String
    public var totalDownloadedGB: Double
    public var totalUploadedGB: Double
    public var interfaces: [NetworkInterfaceItem]
    public var history: [Double]
    
    public static var preview: NetworkSnapshot {
        NetworkSnapshot(
            downloadSpeedKBs: 0.0,
            uploadSpeedKBs: 0.0,
            interfaceName: "en0",
            totalDownloadedGB: 0.0,
            totalUploadedGB: 0.0,
            interfaces: [],
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct BatterySnapshot: Sendable {
    public var isAvailable: Bool
    public var chargePercent: Int
    public var cycleCount: Int
    public var remainingFormatted: String
    public var powerDrawWatts: Double
    public var healthPercent: Int
    public var history: [Double]
    
    public static var preview: BatterySnapshot {
        BatterySnapshot(
            isAvailable: false,
            chargePercent: 100,
            cycleCount: 0,
            remainingFormatted: "-",
            powerDrawWatts: 0.0,
            healthPercent: 100,
            history: Array(repeating: 0.0, count: 45)
        )
    }
}

public struct SystemAlertItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let message: String
    public let isWarning: Bool
    
    public init(id: String, title: String, message: String, isWarning: Bool) {
        self.id = id
        self.title = title
        self.message = message
        self.isWarning = isWarning
    }
}

public struct SystemMetricsSnapshot: Sendable {
    public var chipModel: String
    public var uptimeString: String
    public var thermalStateString: String
    public var audioDeviceString: String
    public var cpu: CPUSnapshot
    public var memory: MemorySnapshot
    public var gpu: GPUSnapshot
    public var disk: DiskSnapshot
    public var network: NetworkSnapshot
    public var battery: BatterySnapshot
    public var memoryByAppTotalGB: Double
    public var powerByAppTotalWatts: Double
    public var topProcesses: [ProcessMetricItem]
    public var alerts: [SystemAlertItem]
    
    public static var preview: SystemMetricsSnapshot {
        SystemMetricsSnapshot(
            chipModel: "Apple Silicon",
            uptimeString: "up 0m",
            thermalStateString: "Nominal",
            audioDeviceString: "Default Output",
            cpu: .preview,
            memory: .preview,
            gpu: .preview,
            disk: .preview,
            network: .preview,
            battery: .preview,
            memoryByAppTotalGB: 0.0,
            powerByAppTotalWatts: 0.0,
            topProcesses: [],
            alerts: []
        )
    }
}
