import SwiftUI

extension Color {
    // Nexus Design System
    static let nexusNavy = Color(red: 8/255, green: 12/255, blue: 24/255)
    static let nexusCharcoal = Color(red: 15/255, green: 22/255, blue: 36/255)
    static let nexusSurface = Color(red: 20/255, green: 28/255, blue: 44/255)
    static let nexusSurface2 = Color(red: 26/255, green: 34/255, blue: 54/255)
    static let nexusTeal = Color(red: 45/255, green: 212/255, blue: 191/255)
    static let nexusBlue = Color(red: 56/255, green: 189/255, blue: 248/255)
    static let nexusText = Color(red: 226/255, green: 232/255, blue: 240/255)
    static let nexusMuted = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let nexusBorder = Color(red: 45/255, green: 212/255, blue: 191/255).opacity(0.12)
    
    // Semantic aliases
    static let nexusBackground = nexusNavy
    static let nexusCardBackground = nexusSurface
    static let nexusAccent = nexusTeal
    static let nexusSecondaryAccent = nexusBlue
    
    // Status colors (tinted to fit the dark theme)
    static let nexusSuccess = Color(red: 34/255, green: 197/255, blue: 94/255)
    static let nexusWarning = Color(red: 250/255, green: 204/255, blue: 21/255)
    static let nexusError = Color(red: 239/255, green: 68/255, blue: 68/255)
}

// MARK: - View Modifiers

struct NexusCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.nexusSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.nexusBorder, lineWidth: 1)
            )
    }
}

struct NexusGlowCard: ViewModifier {
    var color: Color = .nexusTeal
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.nexusSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 0)
    }
}

extension View {
    func nexusCard() -> some View {
        modifier(NexusCardStyle())
    }
    
    func nexusGlowCard(color: Color = .nexusTeal) -> some View {
        modifier(NexusGlowCard(color: color))
    }
    
    func nexusBackground() -> some View {
        self.background(Color.nexusNavy.ignoresSafeArea())
    }
}
