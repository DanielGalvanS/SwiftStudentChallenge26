//
//  GameSessionView.swift
//  Musiora
//

import SwiftUI

struct GameSessionView: View {
    @Bindable var pose: PoseDetectorVM
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreviewView(session: pose.session)
                    .ignoresSafeArea()

                BodyLabelsOverlay(
                    bodyPoints: pose.bodyPoints,
                    size: geo.size,
                    activeMovements: pose.activeMovements
                )

                // ── AR start button & Calibration ──────────────────────────
                if !pose.gameActive && !pose.isCountingDown {
                    GameStartHUD(
                        progress: pose.startProgress,
                        isCalibrated: pose.isCalibrated
                    )
                }

                // ── Countdown ──────────────────────────────────────────────
                if pose.isCountingDown {
                    GameCountdownHUD(countdown: pose.countdown)
                }

                // ── Pause – body lost ──────────────────────────────────────
                if pose.isPaused {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: Theme.Layout.paddingMedium) {
                        Text("Step back into frame")
                            .font(Theme.Typography.titleMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("The game resumes when you're detected")
                            .font(Theme.Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(Theme.Layout.paddingLarge)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusLarge))
                }

                // ── Phase instruction ──────────────────────────────────────
                GamePhaseHUD(
                    phase: pose.phase,
                    isPaused: pose.isPaused
                )

                // ── Rhythm Guide ───────────────────────────────────────────
                VStack {
                    Spacer()
                    RhythmGuidePanel(
                        currentBeat: pose.currentBeat,
                        correctHits: pose.correctHits,
                        missedHits: pose.missedHits,
                        wrongHits: pose.wrongHits,
                        guidesVisible: pose.guidesVisible
                    )
                    .padding(.bottom, 80)
                    .animation(.easeInOut(duration: 0.4), value: pose.guidesVisible)
                }
            }
        }
        .task { await pose.start() }
        .transition(.opacity)
    }
}
