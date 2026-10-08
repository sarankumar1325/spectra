import SwiftUI

public struct MemoryDistributionBar: View {
    public let appGB: Double
    public let wiredGB: Double
    public let compressedGB: Double
    public let cachedGB: Double
    public let freeGB: Double
    public let totalGB: Double
    
    public init(
        appGB: Double,
        wiredGB: Double,
        compressedGB: Double,
        cachedGB: Double,
        freeGB: Double,
        totalGB: Double
    ) {
        self.appGB = appGB
        self.wiredGB = wiredGB
        self.compressedGB = compressedGB
        self.cachedGB = cachedGB
        self.freeGB = freeGB
        self.totalGB = totalGB
    }
    
    private var inUsePercent: Int {
        guard totalGB > 0 else { return 0 }
        let inUse = appGB + wiredGB + compressedGB
        return Int(round((inUse / totalGB) * 100))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SpectraTheme.memory)
                        .frame(width: 6, height: 6)
                    Text("Memory by Type")
                        .font(SpectraTheme.mono(12.5, weight: .bold))
                        .foregroundStyle(SpectraTheme.textPrimary)
                }
                
                Spacer()
                
                Text("\(inUsePercent)% in use")
                    .font(SpectraTheme.mono(10.5, weight: .semibold))
                    .foregroundStyle(SpectraTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Segmented Track
            GeometryReader { proxy in
                let w = proxy.size.width
                let validTotal = max(totalGB, appGB + wiredGB + compressedGB + cachedGB + freeGB, 1.0)
                
                let appW = max(3, (appGB / validTotal) * w)
                let wiredW = max(3, (wiredGB / validTotal) * w)
                let compW = max(3, (compressedGB / validTotal) * w)
                let cachedW = max(3, (cachedGB / validTotal) * w)
                let freeW = max(3, (freeGB / validTotal) * w)
                
                HStack(spacing: 2.5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SpectraTheme.memApp)
                        .frame(width: appW)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SpectraTheme.memWired)
                        .frame(width: wiredW)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SpectraTheme.memCompressed)
                        .frame(width: compW)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SpectraTheme.memCached)
                        .frame(width: cachedW)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SpectraTheme.memFree)
                        .frame(width: freeW)
                }
            }
            .frame(height: 12)
            
            // Responsive Legend Capsules
            ViewThatFits(in: .horizontal) {
                // Wide viewport: Single horizontal line
                HStack(spacing: 12) {
                    legendItem(color: SpectraTheme.memApp, label: "App", value: appGB)
                    legendItem(color: SpectraTheme.memWired, label: "Wired", value: wiredGB)
                    legendItem(color: SpectraTheme.memCompressed, label: "Compressed", value: compressedGB)
                    legendItem(color: SpectraTheme.memCached, label: "Cached", value: cachedGB)
                    legendItem(color: SpectraTheme.memFree, label: "Free", value: freeGB)
                    Spacer(minLength: 0)
                }
                
                // Compact viewport: Adaptive grid flow
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 8)], alignment: .leading, spacing: 6) {
                    legendItem(color: SpectraTheme.memApp, label: "App", value: appGB)
                    legendItem(color: SpectraTheme.memWired, label: "Wired", value: wiredGB)
                    legendItem(color: SpectraTheme.memCompressed, label: "Compressed", value: compressedGB)
                    legendItem(color: SpectraTheme.memCached, label: "Cached", value: cachedGB)
                    legendItem(color: SpectraTheme.memFree, label: "Free", value: freeGB)
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SpectraTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(label)
                .font(SpectraTheme.mono(10.5, weight: .medium))
                .foregroundStyle(SpectraTheme.textSecondary)
            
            Text(String(format: "%.2f GB", value))
                .font(SpectraTheme.mono(10.5, weight: .bold))
                .foregroundStyle(SpectraTheme.textPrimary)
        }
    }
}
