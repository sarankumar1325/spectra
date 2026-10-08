import SwiftUI

@Observable
@MainActor
public final class AppState {
    public var metrics: SystemMetricsSnapshot = .preview
    public var selectedSection: NavigationSection = .overview
    public var searchText: String = ""
    public var isProcessDrawerOpen: Bool = false
    public var isSidebarVisible: Bool = true
    
    private var telemetryTask: Task<Void, Never>? = nil
    
    public init() {
        // Initial capture
        self.metrics = SystemTelemetryEngine.shared.captureSnapshot()
        startTelemetryLoop()
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spectra.navigate"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            if let secStr = note.userInfo?["section"] as? String,
               let section = NavigationSection(rawValue: secStr) {
                Task { @MainActor [weak self] in
                    self?.selectedSection = section
                }
            }
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spectra.toggleSidebar"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isSidebarVisible.toggle()
            }
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spectra.toggleProcessDrawer"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isProcessDrawerOpen.toggle()
            }
        }
    }
    
    public func startTelemetryLoop() {
        telemetryTask?.cancel()
        telemetryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 Hz
                guard let self = self, !Task.isCancelled else { break }
                let newSnapshot = SystemTelemetryEngine.shared.captureSnapshot()
                self.metrics = newSnapshot
            }
        }
    }
    
    isolated deinit {
        telemetryTask?.cancel()
    }
}
