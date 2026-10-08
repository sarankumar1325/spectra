import SwiftUI

public struct SpectraMainView: View {
    @State private var appState = AppState()
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left Navigation Sidebar
            if appState.isSidebarVisible {
                SidebarView(
                    selection: $appState.selectedSection,
                    alertsCount: appState.metrics.alerts.count
                )
                
                Divider()
                    .background(SpectraTheme.cardBorder)
            }
            
            // Main Dashboard Area
            VStack(spacing: 0) {
                // Header
                HeaderBarView(
                    title: appState.selectedSection.rawValue,
                    chipModel: appState.metrics.chipModel,
                    uptimeString: appState.metrics.uptimeString,
                    searchText: $appState.searchText,
                    onToggleSidebar: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.isSidebarVisible.toggle()
                        }
                    }
                )
                
                // Body View
                if appState.selectedSection == .overview {
                    OverviewDashboardView(
                        metrics: appState.metrics,
                        isProcessDrawerOpen: $appState.isProcessDrawerOpen
                    )
                } else {
                    SubsystemDetailView(
                        section: appState.selectedSection,
                        metrics: appState.metrics
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SpectraTheme.background)
        }
        .frame(minWidth: 540, idealWidth: 1060, minHeight: 400, idealHeight: 740)
        .background(SpectraTheme.background)
        .preferredColorScheme(.dark)
    }
}
