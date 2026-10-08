import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure main window has dark title bar styling
        if let window = NSApp.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
            window.isMovableByWindowBackground = true
        }
        
        // Listen for programmatic resize commands across tests and automation
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spectra.resizeWindow"),
            object: nil,
            queue: .main
        ) { note in
            if let str = note.userInfo?["size"] as? String {
                let parts = str.split(separator: "x").compactMap { Double($0) }
                if parts.count == 2 {
                    Task { @MainActor in
                        NSApp.resizeMainWindow(to: CGSize(width: parts[0], height: parts[1]))
                    }
                }
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@MainActor
extension NSApplication {
    func resizeMainWindow(to size: CGSize) {
        guard let window = NSApp.windows.first(where: { $0.canBecomeMain }) ?? NSApp.windows.first else { return }
        var frame = window.frame
        let oldHeight = frame.size.height
        frame.size = size
        frame.origin.y += (oldHeight - size.height)
        window.setFrame(frame, display: true, animate: true)
    }
}

@main
struct SpectraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SpectraMainView()
                .background(SpectraTheme.background)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1080, height: 720)
        .commands {
            CommandMenu("Window Size") {
                Button("Compact HUD (600 x 480)") {
                    NSApp.resizeMainWindow(to: CGSize(width: 600, height: 480))
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Studio Dashboard (1060 x 740)") {
                    NSApp.resizeMainWindow(to: CGSize(width: 1060, height: 740))
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Command Center (1440 x 880)") {
                    NSApp.resizeMainWindow(to: CGSize(width: 1440, height: 880))
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }
    }
}
