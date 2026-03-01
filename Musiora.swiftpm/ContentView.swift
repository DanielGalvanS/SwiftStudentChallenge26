//
//  ContentView.swift
//  Musiora
//

import SwiftUI
import Vision

struct ContentView: View {
    @State private var pose = PoseDetectorVM()
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            // Background is always dark
            Theme.Colors.background.ignoresSafeArea()
            
            // ── Game Session ───────────────────────────────────────────
            if gameStarted && pose.phase != .results {
                GameSessionView(pose: pose)
                    .transition(.opacity)
            }

            // ── Welcome Screen ─────────────────────────────────────────
            if !gameStarted {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        gameStarted = true
                    }
                }
                .transition(.opacity)
            }

            // ── Results Screen ─────────────────────────────────────────
            if pose.phase == .results {
                ResultsView(score: pose.score) {
                    pose.stop()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        pose = PoseDetectorVM()
                        gameStarted = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: pose.phase == .results)
        .animation(.easeInOut(duration: 0.5), value: gameStarted)
    }

    // Moved visionToScreen to an extension or helper if needed in CameraPreviewView,
    // but here we keep it as it's not being used directly in ContentView anymore.
}
