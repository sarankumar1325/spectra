import SwiftUI

public struct SidebarView: View {
    @Binding public var selection: NavigationSection
    public let alertsCount: Int
    
    public init(selection: Binding<NavigationSection>, alertsCount: Int = 3) {
        self._selection = selection
        self.alertsCount = alertsCount
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Monitor Section
            sectionGroup(title: "MONITOR") {
                sidebarButton(for: .overview)
                sidebarButton(for: .cpu)
                sidebarButton(for: .memory)
                sidebarButton(for: .disk)
                sidebarButton(for: .network)
                sidebarButton(for: .gpu)
                sidebarButton(for: .battery)
                sidebarButton(for: .sensors)
            }
            
            // Devices Section
            sectionGroup(title: "DEVICES") {
                sidebarButton(for: .sound)
                sidebarButton(for: .bluetooth)
            }
            
            // Work Section
            sectionGroup(title: "WORK") {
                sidebarButton(for: .projects)
                sidebarButton(for: .alerts, badge: alertsCount > 0 ? "\(alertsCount)" : nil)
            }
            
            Spacer()
            
            // Bottom Telemetry Status Capsule
            HStack(spacing: 7) {
                Circle()
                    .fill(SpectraTheme.memory)
                    .frame(width: 5, height: 5)
                
                Text("ENGINE ACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(SpectraTheme.textMuted)
                
                Spacer()
                
                Text("1.0s")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(SpectraTheme.textDim)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.02))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 10)
        .padding(.top, 42) // Clearance for macOS traffic light buttons
        .padding(.bottom, 14)
        .frame(width: 178)
        .background(SpectraTheme.sidebarBackground)
    }
    
    @ViewBuilder
    private func sectionGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundStyle(SpectraTheme.textMuted)
                .padding(.horizontal, 8)
                .padding(.bottom, 3)
            
            content()
        }
    }
    
    @ViewBuilder
    private func sidebarButton(for item: NavigationSection, badge: String? = nil) -> some View {
        let isSelected = selection == item
        
        Button {
            selection = item
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? SpectraTheme.textPrimary : SpectraTheme.textMuted)
                    .frame(width: 16)
                
                Text(item.rawValue)
                    .font(SpectraTheme.mono(11.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? SpectraTheme.textPrimary : SpectraTheme.textSecondary)
                
                Spacer()
                
                if let badge {
                    Text(badge)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(SpectraTheme.disk)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5.5)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.09))
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
