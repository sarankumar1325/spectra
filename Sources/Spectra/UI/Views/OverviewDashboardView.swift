import SwiftUI

public struct OverviewDashboardView: View {
    public let metrics: SystemMetricsSnapshot
    @Binding public var isProcessDrawerOpen: Bool
    
    public init(metrics: SystemMetricsSnapshot, isProcessDrawerOpen: Binding<Bool>) {
        self.metrics = metrics
        self._isProcessDrawerOpen = isProcessDrawerOpen
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let colCount = availableWidth > 860 ? 3 : (availableWidth > 540 ? 2 : 1)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: colCount)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    // Responsive Balanced Metric Cards Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                    // 1. CPU
                    MetricCardView(
                        iconName: "cpu",
                        title: "CPU",
                        statusHeader: "NOW",
                        heroValue: "\(Int(metrics.cpu.usagePercent))%",
                        subtitle: "Load \(String(format: "%.2f", metrics.cpu.load1Min))",
                        accentColor: SpectraTheme.cpu,
                        lightAccentColor: SpectraTheme.cpuLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "User", value: "\(Int(metrics.cpu.userPercent))%"),
                            MetricBreakdownItem(label: "System", value: "\(Int(metrics.cpu.systemPercent))%"),
                            MetricBreakdownItem(label: "Average today", value: "\(Int(metrics.cpu.avgTodayPercent))%")
                        ],
                        waveformHistory: metrics.cpu.history
                    )
                    
                    // 2. Memory
                    MetricCardView(
                        iconName: "memorychip",
                        title: "Memory",
                        statusHeader: "IN USE OF \(String(format: "%.2f GB", metrics.memory.totalGB))",
                        heroValue: String(format: "%.2f GB", metrics.memory.inUseGB),
                        subtitle: metrics.memory.pressureStatus,
                        accentColor: SpectraTheme.memory,
                        lightAccentColor: SpectraTheme.memoryLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "App", value: String(format: "%.2f GB", metrics.memory.appGB)),
                            MetricBreakdownItem(label: "Wired", value: String(format: "%.2f GB", metrics.memory.wiredGB)),
                            MetricBreakdownItem(label: "Compressed", value: String(format: "%.2f GB", metrics.memory.compressedGB))
                        ],
                        waveformHistory: metrics.memory.history
                    )
                    
                    // 3. GPU
                    MetricCardView(
                        iconName: "cube",
                        title: "GPU",
                        statusHeader: metrics.gpu.chipName.uppercased(),
                        heroValue: "\(Int(metrics.gpu.utilizationPercent))%",
                        subtitle: "Utilization",
                        accentColor: SpectraTheme.gpu,
                        lightAccentColor: SpectraTheme.gpuLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "Memory", value: String(format: "%.2f GB", metrics.gpu.memoryGB)),
                            MetricBreakdownItem(label: "Average today", value: "\(Int(metrics.gpu.avgTodayPercent))%"),
                            MetricBreakdownItem(label: "Peak today", value: "\(Int(metrics.gpu.peakTodayPercent))%")
                        ],
                        waveformHistory: metrics.gpu.history
                    )
                    
                    // 4. Disk
                    MetricCardView(
                        iconName: "internaldrive",
                        title: "Disk",
                        statusHeader: "FREE OF \(Int(metrics.disk.totalGB)) GB",
                        heroValue: "\(Int(metrics.disk.freeGB)) GB",
                        subtitle: "\(Int(metrics.disk.usedGB)) GB used",
                        accentColor: SpectraTheme.disk,
                        lightAccentColor: SpectraTheme.diskLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "Reading", value: String(format: "%.1f MB/s", metrics.disk.readSpeedMBs)),
                            MetricBreakdownItem(label: "Writing", value: String(format: "%.2f MB/s", metrics.disk.writeSpeedMBs)),
                            MetricBreakdownItem(label: "Total written", value: "\(Int(metrics.disk.writtenTotalGB)) GB")
                        ],
                        waveformHistory: metrics.disk.history
                    )
                    
                    // 5. Network
                    MetricCardView(
                        iconName: "globe",
                        title: "Network",
                        statusHeader: "DOWNLOADING",
                        heroValue: formatNetworkSpeed(metrics.network.downloadSpeedKBs),
                        subtitle: metrics.network.interfaceName.components(separatedBy: " ").first ?? metrics.network.interfaceName,
                        accentColor: SpectraTheme.network,
                        lightAccentColor: SpectraTheme.networkLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "Uploading", value: formatNetworkSpeed(metrics.network.uploadSpeedKBs)),
                            MetricBreakdownItem(label: "Session in", value: String(format: "%.2f GB", metrics.network.totalDownloadedGB)),
                            MetricBreakdownItem(label: "Session out", value: String(format: "%.2f GB", metrics.network.totalUploadedGB))
                        ],
                        waveformHistory: metrics.network.history
                    )
                    
                    // 6. Battery
                    MetricCardView(
                        iconName: "battery.100",
                        title: "Battery",
                        statusHeader: "CHARGED",
                        heroValue: "\(metrics.battery.chargePercent)%",
                        subtitle: "\(metrics.battery.cycleCount) cycles",
                        accentColor: SpectraTheme.battery,
                        lightAccentColor: SpectraTheme.batteryLight,
                        breakdownItems: [
                            MetricBreakdownItem(label: "Remaining", value: metrics.battery.remainingFormatted),
                            MetricBreakdownItem(label: "Power draw", value: String(format: "%.1f W", metrics.battery.powerDrawWatts)),
                            MetricBreakdownItem(label: "Health", value: "\(metrics.battery.healthPercent)%")
                        ],
                        waveformHistory: metrics.battery.history
                    )
                }
                
                // Memory by Type Horizontal Breakdown Bar
                MemoryDistributionBar(
                    appGB: metrics.memory.appGB,
                    wiredGB: metrics.memory.wiredGB,
                    compressedGB: metrics.memory.compressedGB,
                    cachedGB: metrics.memory.cachedGB,
                    freeGB: metrics.memory.freeGB,
                    totalGB: metrics.memory.totalGB
                )
                
                // Resource Consumers Tickers Footer
                AppUsageTickerView(
                    memoryTotalGB: metrics.memoryByAppTotalGB,
                    powerTotalWatts: metrics.powerByAppTotalWatts,
                    topProcesses: metrics.topProcesses,
                    isProcessDrawerOpen: $isProcessDrawerOpen
                )
                
                // Expandable Process Inspector Drawer
                if isProcessDrawerOpen {
                    processDrawer
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(width: geometry.size.width)
        }
    }
    
    // MARK: - Process Inspector Drawer
    private var processDrawer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Process Consumers")
                    .font(SpectraTheme.mono(12, weight: .bold))
                    .foregroundStyle(SpectraTheme.textPrimary)
                Spacer()
                Text("PID / CPU / RAM")
                    .font(SpectraTheme.mono(10, weight: .medium))
                    .foregroundStyle(SpectraTheme.textMuted)
            }
            
            VStack(spacing: 6) {
                ForEach(metrics.topProcesses) { proc in
                    HStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 11))
                            .foregroundStyle(SpectraTheme.textSecondary)
                            .frame(width: 14)
                        
                        Text(proc.name)
                            .font(SpectraTheme.mono(11.5, weight: .medium))
                            .foregroundStyle(SpectraTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text("(\(proc.id))")
                            .font(SpectraTheme.mono(10, weight: .regular))
                            .foregroundStyle(SpectraTheme.textMuted)
                            .lineLimit(1)
                        
                        Spacer(minLength: 4)
                        
                        Text(String(format: "%.1f%% CPU", proc.cpuPercent))
                            .font(SpectraTheme.mono(11, weight: .semibold))
                            .foregroundStyle(SpectraTheme.cpuLight)
                            .lineLimit(1)
                        
                        Text(String(format: "%.0f MB", proc.memoryMB))
                            .font(SpectraTheme.mono(11, weight: .semibold))
                            .foregroundStyle(SpectraTheme.memoryLight)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(SpectraTheme.innerSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(14)
        .background(SpectraTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SpectraTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private func formatNetworkSpeed(_ kbs: Double) -> String {
        if kbs >= 1024.0 {
            return String(format: "%.1f MB/s", kbs / 1024.0)
        } else {
            return String(format: "%.1f kB/s", kbs)
        }
    }
}
