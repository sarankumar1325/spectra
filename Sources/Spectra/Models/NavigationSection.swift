import Foundation

public enum NavigationSection: String, CaseIterable, Identifiable, Sendable {
    // Monitor
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
    case network = "Network"
    case gpu = "GPU"
    case battery = "Battery"
    case sensors = "Sensors"
    
    // Devices
    case sound = "Sound"
    case bluetooth = "Bluetooth"
    
    // Work
    case projects = "Projects"
    case alerts = "Alerts"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "globe"
        case .gpu: return "cube"
        case .battery: return "battery.100"
        case .sensors: return "thermometer.medium"
        case .sound: return "speaker.wave.2"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .projects: return "hammer"
        case .alerts: return "bell"
        }
    }
}
