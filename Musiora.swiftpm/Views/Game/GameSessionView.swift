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

                if pose.gameActive && !pose.isCountingDown {
                    BodyLabelsOverlay(
                        bodyPoints: pose.bodyPoints,
                        size: geo.size,
                        activeMovements: pose.activeMovements,
                        scores: pose.score
                    )
                }

                // ── AR start button & Calibration ──────────────────────────
                if !pose.gameActive && !pose.isCountingDown && !pose.hasStarted && !pose.isShowingTutorial {
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
                if pose.gameActive && !pose.isCountingDown {
                    GamePhaseHUD(
                        phase: pose.phase,
                        isPaused: pose.isPaused,
                        phaseHits: pose.phaseHits
                    )
                }

                // ── Rhythm Guide ───────────────────────────────────────────
                if pose.gameActive && !pose.isCountingDown {
                    VStack {
                        Spacer()
                        RhythmGuidePanel(
                            currentBeat: pose.currentBeat,
                            correctHits: pose.correctHits,
                            missedHits: pose.missedHits,
                            wrongHits: pose.wrongHits,
                            guidesVisible: pose.guidesShown
                        )
                        .padding(.bottom, 80)
                        .animation(.easeInOut(duration: 0.4), value: pose.guidesVisible)
                    }
                }
                
                // ── Tutorial Overlay ───────────────────────────────────────
                if pose.isShowingTutorial {
                    TutorialOverlay(
                        phase: pose.phase,
                        onReady: {
                            pose.dismissTutorial()
                        }
                    )
                    .zIndex(100)
                }
            }
        }
        .task { await pose.start() }
        .transition(.opacity)
    }
}
