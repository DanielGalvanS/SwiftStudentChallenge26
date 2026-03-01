//
//  Theme.swift
//  Musiora
//

import SwiftUI

/// Centralized Design System for Musiora
enum Theme {
    
    // MARK: - Typography (Rounded)
    enum Typography {
        static let displayLarge = Font.system(size: 120, weight: .black, design: .rounded)
        static let displayMedium = Font.system(size: 56, weight: .black, design: .rounded)
        static let displaySmall = Font.system(size: 42, weight: .black, design: .rounded)
        
        static let titleLarge = Font.system(size: 24, weight: .bold, design: .rounded)
        static let titleMedium = Font.system(size: 20, weight: .bold, design: .rounded)
        static let titleSmall = Font.system(size: 18, weight: .semibold, design: .rounded)

        static let bodyLarge = Font.system(size: 16, weight: .medium, design: .rounded)
        static let bodyMedium = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
        
        static let labelLarge = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let labelMedium = Font.system(size: 14, weight: .bold, design: .monospaced)
        static let labelSmall = Font.system(size: 11, weight: .black, design: .rounded)
    }
    
    // MARK: - Colors
    enum Colors {
        static let background = Color.black
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let textTertiary = Color.white.opacity(0.5)
        
        static let overlayDark = Color.black.opacity(0.6)
        static let overlayLight = Color.white.opacity(0.05)
        
        static let primaryAction = Color.white
        static let primaryActionText = Color.black
        
        // Contextual
        static let success = Color.green
    }
    
    // MARK: - Spacing & Layout
    enum Layout {
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        static let paddingXLarge: CGFloat = 32
        
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 16
        static let cornerRadiusLarge: CGFloat = 20
        static let cornerRadiusXLarge: CGFloat = 24
    }
}
