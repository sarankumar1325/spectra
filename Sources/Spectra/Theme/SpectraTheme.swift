import SwiftUI

public enum SpectraTheme {
    // MARK: - Surfaces & Vibe
    public static let background = Color(hex: "#0E0E11")
    public static let windowBackground = Color(hex: "#121216")
    public static let sidebarBackground = Color(hex: "#141418")
    public static let cardBackground = Color(hex: "#18181D")
    public static let cardElevated = Color(hex: "#1F1F26")
    public static let innerSurface = Color(hex: "#111114")
    
    // MARK: - Micro Borders & Highlights
    public static let cardBorder = Color.white.opacity(0.08)
    public static let cardInnerHighlight = Color.white.opacity(0.04)
    public static let subtleDivider = Color.white.opacity(0.06)
    
    // MARK: - Subsystem Signature Accents (Studio Calibrated)
    public static let cpu = Color(hex: "#38BDF8")          // Precision Electric Sky
    public static let cpuLight = Color(hex: "#7DD3FC")
    public static let cpuDark = Color(hex: "#0284C7")
    
    public static let memory = Color(hex: "#34D399")       // Terminal Emerald Mint
    public static let memoryLight = Color(hex: "#6EE7B7")
    public static let memoryDark = Color(hex: "#059669")
    
    public static let gpu = Color(hex: "#C084FC")          // Vivid Violet Ribbon
    public static let gpuLight = Color(hex: "#E879F9")
    public static let gpuDark = Color(hex: "#9333EA")
    
    public static let disk = Color(hex: "#FB923C")         // Studio Amber Tangerine
    public static let diskLight = Color(hex: "#FDBA74")
    public static let diskDark = Color(hex: "#EA580C")
    
    public static let network = Color(hex: "#22D3EE")      // Neon Aqua Cyan
    public static let networkLight = Color(hex: "#67E8F9")
    public static let networkDark = Color(hex: "#0891B2")
    
    public static let battery = Color(hex: "#A3E635")      // High-Luminance Lime
    public static let batteryLight = Color(hex: "#BEF264")
    public static let batteryDark = Color(hex: "#65A30D")
    
    // MARK: - Memory Breakdown Colors
    public static let memApp = Color(hex: "#34D399")
    public static let memWired = Color(hex: "#FB923C")
    public static let memCompressed = Color(hex: "#F472B6")
    public static let memCached = Color(hex: "#38BDF8")
    public static let memFree = Color(hex: "#475569")
    
    // MARK: - Text
    public static let textPrimary = Color.white.opacity(0.96)
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textMuted = Color.white.opacity(0.40)
    public static let textDim = Color.white.opacity(0.24)
    
    // MARK: - Precision Monospaced Typography
    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
