import SwiftUI

public struct HeaderBarView: View {
    public let title: String
    public let chipModel: String
    public let uptimeString: String
    @Binding public var searchText: String
    public var onToggleSidebar: (() -> Void)?
    
    public init(
        title: String,
        chipModel: String,
        uptimeString: String,
        searchText: Binding<String>,
        onToggleSidebar: (() -> Void)? = nil
    ) {
        self.title = title
        self.chipModel = chipModel
        self.uptimeString = uptimeString
        self._searchText = searchText
        self.onToggleSidebar = onToggleSidebar
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Sidebar Toggle Button
            if let onToggleSidebar {
                Button(action: onToggleSidebar) {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpectraTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(SpectraTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(SpectraTheme.cardBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("b", modifiers: .command)
                .help("Toggle Sidebar (⌘B)")
            }
            
            // Title + Dynamic Chip Vitals
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SpectraTheme.mono(15, weight: .bold))
                    .foregroundStyle(SpectraTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(SpectraTheme.memory)
                        .frame(width: 5, height: 5)
                    
                    Text("\(chipModel) · \(uptimeString)")
                        .font(SpectraTheme.mono(10.5, weight: .medium))
                        .foregroundStyle(SpectraTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            
            Spacer(minLength: 6)
            
            // Search / Filter Input (Responsive frame)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpectraTheme.textMuted)
                
                TextField("Filter apps", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(SpectraTheme.mono(11, weight: .medium))
                    .foregroundStyle(SpectraTheme.textPrimary)
                    .frame(minWidth: 60, idealWidth: 110, maxWidth: 140)
                
                Text("⌘F")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SpectraTheme.textDim)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(SpectraTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(SpectraTheme.cardBorder, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
