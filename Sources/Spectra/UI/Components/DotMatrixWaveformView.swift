import SwiftUI

/// Studio-grade hardware oscilloscope and phosphor matrix waveform visualizer.
/// Combines a fine-pitch 2D phosphor matrix with a luminous crest stroke and oscilloscope grid guidelines.
public struct DotMatrixWaveformView: View {
    public let data: [Double] // Normalized values 0.0 ... 1.0
    public let tintColor: Color
    public let crestColor: Color?
    public let dotSize: CGFloat
    public let dotSpacing: CGFloat
    public let showGrid: Bool
    
    public init(
        data: [Double],
        tintColor: Color,
        crestColor: Color? = nil,
        dotSize: CGFloat = 1.6,
        dotSpacing: CGFloat = 2.6,
        showGrid: Bool = true
    ) {
        self.data = data
        self.tintColor = tintColor
        self.crestColor = crestColor
        self.dotSize = dotSize
        self.dotSpacing = dotSpacing
        self.showGrid = showGrid
    }
    
    public var body: some View {
        Canvas { context, size in
            guard size.width > 20, size.height > 10 else { return }
            
            let columns = max(4, Int(size.width / dotSpacing))
            let rows = max(4, Int(size.height / dotSpacing))
            let resolvedCrest = crestColor ?? tintColor
            
            // 1. Oscilloscope Grid Guides
            if showGrid {
                // 50% horizontal dashed centerline
                let midY = size.height / 2.0
                var midLine = Path()
                midLine.move(to: CGPoint(x: 0, y: midY))
                midLine.addLine(to: CGPoint(x: size.width, y: midY))
                context.stroke(
                    midLine,
                    with: .color(Color.white.opacity(0.04)),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 4])
                )
                
                // Floor baseline
                var floorLine = Path()
                floorLine.move(to: CGPoint(x: 0, y: size.height - 1))
                floorLine.addLine(to: CGPoint(x: size.width, y: size.height - 1))
                context.stroke(
                    floorLine,
                    with: .color(tintColor.opacity(0.18)),
                    lineWidth: 1
                )
            }
            
            // 2. Interpolate normalized telemetry values
            let normalizedValues: [Double] = (0..<columns).map { col in
                guard !data.isEmpty else { return 0.25 }
                if data.count == 1 { return data[0] }
                let progress = Double(col) / Double(columns - 1)
                let dataIndex = progress * Double(data.count - 1)
                let lower = Int(floor(dataIndex))
                let upper = min(lower + 1, data.count - 1)
                let fraction = dataIndex - Double(lower)
                let val = data[lower] * (1.0 - fraction) + data[upper] * fraction
                return min(max(val, 0.04), 0.98)
            }
            
            // 3. Render Fine Phosphor Dot Matrix with Vertical Glow Decay
            for col in 0..<columns {
                let x = CGFloat(col) * dotSpacing + (dotSize / 2.0)
                let val = normalizedValues[col]
                let targetRow = Int(val * Double(rows - 1))
                
                for row in 0..<rows {
                    let y = size.height - (CGFloat(row) * dotSpacing) - (dotSize / 2.0)
                    let rect = CGRect(
                        x: x - dotSize / 2.0,
                        y: y - dotSize / 2.0,
                        width: dotSize,
                        height: dotSize
                    )
                    
                    if row == targetRow {
                        // Crest point: high luminance
                        context.opacity = 1.0
                        context.fill(Path(ellipseIn: rect), with: .color(resolvedCrest))
                    } else if row < targetRow {
                        // Body dots: smooth exponential decay towards baseline
                        let heightRatio = Double(row) / Double(max(1, targetRow))
                        let alpha = 0.08 + (0.32 * heightRatio)
                        context.opacity = alpha
                        context.fill(Path(ellipseIn: rect), with: .color(tintColor))
                    } else if showGrid && row % 4 == 0 && col % 4 == 0 {
                        // Ambient matrix grid hints
                        context.opacity = 0.035
                        context.fill(Path(ellipseIn: rect), with: .color(Color.white))
                    }
                }
            }
            
            // 4. Luminous Crest Filament
            var crestPath = Path()
            for col in 0..<columns {
                let x = CGFloat(col) * dotSpacing + (dotSize / 2.0)
                let val = normalizedValues[col]
                let y = size.height - (CGFloat(val) * (size.height - 4)) - 2
                
                if col == 0 {
                    crestPath.move(to: CGPoint(x: x, y: y))
                } else {
                    crestPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // Glow layer
            context.opacity = 0.35
            context.stroke(crestPath, with: .color(resolvedCrest), lineWidth: 2.5)
            
            // Crisp core stroke
            context.opacity = 0.85
            context.stroke(crestPath, with: .color(resolvedCrest), lineWidth: 1.0)
            
            // Current live cursor dot on the right edge
            if let lastVal = normalizedValues.last {
                let lastX = CGFloat(columns - 1) * dotSpacing + (dotSize / 2.0)
                let lastY = size.height - (CGFloat(lastVal) * (size.height - 4)) - 2
                let cursorRect = CGRect(x: lastX - 2.0, y: lastY - 2.0, width: 4.0, height: 4.0)
                context.opacity = 1.0
                context.fill(Path(ellipseIn: cursorRect), with: .color(Color.white))
            }
        }
    }
}
