import SwiftUI

public struct MetricBreakdownItem: Identifiable, Sendable {
    public let id = UUID()
    public let label: String
    public let value: String
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct MetricCardView: View {
    public let iconName: String
    public let title: String
    public let statusHeader: String
    public let heroValue: String
    public let subtitle: String?
    public let accentColor: Color
    public let lightAccentColor: Color?
    public let breakdownItems: [MetricBreakdownItem]
    public let waveformHistory: [Double]
    
    public init(
        iconName: String,
        title: String,
        statusHeader: String,
        heroValue: String,
        subtitle: String? = nil,
        accentColor: Color,
        lightAccentColor: Color? = nil,
        breakdownItems: [MetricBreakdownItem],
        waveformHistory: [Double]
    ) {
        self.iconName = iconName
        self.title = title
        self.statusHeader = statusHeader
        self.heroValue = heroValue
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.lightAccentColor = lightAccentColor
        self.breakdownItems = breakdownItems
        self.waveformHistory = waveformHistory
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Icon + Title + Status Badge
            HStack(spacing: 8) {
                // Tactile hardware icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor.opacity(0.12))
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(accentColor.opacity(0.28), lineWidth: 1)
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 22, height: 22)
                
                Text(title)
                    .font(SpectraTheme.mono(12.5, weight: .bold))
                    .foregroundStyle(SpectraTheme.textPrimary)
                
                Spacer()
                
                // Micro status pill
                Text(statusHeader.uppercased())
                    .font(SpectraTheme.mono(9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(SpectraTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }
            
            // Hero Metric Row
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(heroValue)
                    .font(SpectraTheme.mono(26, weight: .bold))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                
                if let subtitle {
                    Text(subtitle)
                        .font(SpectraTheme.mono(10.5, weight: .medium))
                        .foregroundStyle(SpectraTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
            .padding(.bottom, 2)
            
            // Telemetry Readout Rows
            VStack(spacing: 6) {
                ForEach(breakdownItems) { item in
                    HStack(spacing: 4) {
                        Text(item.label)
                            .font(SpectraTheme.mono(10.5, weight: .medium))
                            .foregroundStyle(SpectraTheme.textSecondary)
                            .lineLimit(1)
                        
                        // Hairline dotted leader line
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                        
                        Text(item.value)
                            .font(SpectraTheme.mono(11, weight: .semibold))
                            .foregroundStyle(SpectraTheme.textPrimary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 2)
            
            // Oscilloscope Waveform Screen Frame
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(SpectraTheme.innerSurface)
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                
                DotMatrixWaveformView(
                    data: waveformHistory,
                    tintColor: accentColor,
                    crestColor: lightAccentColor ?? accentColor
                )
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
            }
            .frame(height: 52)
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
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
}
