import SwiftUI

public struct AppUsageTickerView: View {
    public let memoryTotalGB: Double
    public let powerTotalWatts: Double
    public let topProcesses: [ProcessMetricItem]
    @Binding public var isProcessDrawerOpen: Bool
    
    public init(
        memoryTotalGB: Double,
        powerTotalWatts: Double,
        topProcesses: [ProcessMetricItem],
        isProcessDrawerOpen: Binding<Bool>
    ) {
        self.memoryTotalGB = memoryTotalGB
        self.powerTotalWatts = powerTotalWatts
        self.topProcesses = topProcesses
        self._isProcessDrawerOpen = isProcessDrawerOpen
    }
    
    public var body: some View {
        ViewThatFits(in: .horizontal) {
            // Tier 1: Wide viewport - single row
            HStack(spacing: 12) {
                memoryPill
                powerPill
                Spacer(minLength: 4)
                drawerTrigger
            }
            
            // Tier 2: Medium viewport - pills row + trigger below
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    memoryPill
                    powerPill
                }
                drawerTrigger
            }
            
            // Tier 3: Compact viewport - clean vertical stack
            VStack(alignment: .leading, spacing: 6) {
                memoryPill
                powerPill
                drawerTrigger
            }
        }
        .padding(.vertical, 2)
    }
    
    private var memoryPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isProcessDrawerOpen.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(SpectraTheme.memory)
                    .frame(width: 6, height: 6)
                
                Text("Memory by App")
                    .font(SpectraTheme.mono(11, weight: .bold))
                    .foregroundStyle(SpectraTheme.textPrimary)
                
                Text(String(format: "%.2f GB", memoryTotalGB))
                    .font(SpectraTheme.mono(11, weight: .bold))
                    .foregroundStyle(SpectraTheme.memory)
                
                Text("all apps")
                    .font(SpectraTheme.mono(9.5, weight: .medium))
                    .foregroundStyle(SpectraTheme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SpectraTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(SpectraTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var powerPill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isProcessDrawerOpen.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(SpectraTheme.cpu)
                    .frame(width: 6, height: 6)
                
                Text("Power by App")
                    .font(SpectraTheme.mono(11, weight: .bold))
                    .foregroundStyle(SpectraTheme.textPrimary)
                
                Text(String(format: "%.1f W", powerTotalWatts))
                    .font(SpectraTheme.mono(11, weight: .bold))
                    .foregroundStyle(SpectraTheme.cpu)
                
                Text("all apps")
                    .font(SpectraTheme.mono(9.5, weight: .medium))
                    .foregroundStyle(SpectraTheme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SpectraTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(SpectraTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var drawerTrigger: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isProcessDrawerOpen.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Text(isProcessDrawerOpen ? "Hide Process Inspector" : "Inspect Top Processes")
                    .font(SpectraTheme.mono(10.5, weight: .semibold))
                    .foregroundStyle(SpectraTheme.textSecondary)
                
                Image(systemName: isProcessDrawerOpen ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(SpectraTheme.textMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}
