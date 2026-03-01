//
//  GlassPanel.swift
//  Musiora
//

import SwiftUI

/// A reusable glassmorphic panel
struct GlassPanel<Content: View>: View {
    let padding: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        padding: CGFloat = Theme.Layout.paddingLarge,
        cornerRadius: CGFloat = Theme.Layout.cornerRadiusLarge,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(.regularMaterial)
            .environment(\.colorScheme, .dark) // Forces dark material look
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}
