import Testing
import Foundation
@testable import Spectra

@Suite("Spectra Telemetry Tests")
struct SpectraTelemetryTests {
    
    @Test("Telemetry Engine Snapshot Capture")
    func testTelemetrySnapshot() async throws {
        let snapshot = SystemTelemetryEngine.shared.captureSnapshot()
        
        #expect(!snapshot.chipModel.isEmpty)
        #expect(!snapshot.uptimeString.isEmpty)
        #expect(snapshot.cpu.usagePercent >= 0.0 && snapshot.cpu.usagePercent <= 100.0)
        #expect(snapshot.cpu.history.count == 45)
        
        #expect(snapshot.memory.totalGB > 0)
        #expect(snapshot.memory.inUseGB >= 0)
        #expect(snapshot.memory.history.count == 45)
        
        #expect(snapshot.disk.totalGB > 0)
        #expect(snapshot.disk.freeGB >= 0)
        #expect(snapshot.disk.history.count == 45)
        
        #expect(snapshot.network.history.count == 45)
        #expect(snapshot.battery.history.count == 45)
    }
    
    @Test("Memory Calculations Integrity")
    func testMemoryIntegrity() async throws {
        let memory = MemorySnapshot(
            inUseGB: 16.0,
            totalGB: 32.0,
            pressureStatus: "Pressure Normal",
            appGB: 10.0,
            wiredGB: 3.0,
            compressedGB: 3.0,
            cachedGB: 8.0,
            freeGB: 8.0,
            history: [0.5]
        )
        
        #expect(memory.usedPercent == 50.0)
    }
    
    @Test("Navigation Sections Completeness")
    func testNavigationSections() async throws {
        let allSections = NavigationSection.allCases
        #expect(allSections.count == 12)
        #expect(allSections.contains(.overview))
        #expect(allSections.contains(.cpu))
        #expect(allSections.contains(.memory))
        #expect(allSections.contains(.gpu))
        #expect(allSections.contains(.disk))
        #expect(allSections.contains(.network))
        #expect(allSections.contains(.battery))
        #expect(allSections.contains(.sensors))
    }
}
