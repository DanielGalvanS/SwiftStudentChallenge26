import SwiftUI
import Vision

struct ContentView: View {
    @State private var pose = PoseDetectorVM()
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            // ── Camera + game ───────────────────────────────────────────
            if gameStarted {
                GeometryReader { geo in
                    ZStack {
                        CameraPreviewView(session: pose.session)
                            .ignoresSafeArea()

                        BodyLabelsOverlay(
                            bodyPoints: pose.bodyPoints,
                            size: geo.size,
                            activeMovements: pose.activeMovements
                        )

                        // ── AR start button ──────────────────────────────
                        if pose.isCalibrated && !pose.gameActive && !pose.isCountingDown {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.12))
                                        .frame(width: 110, height: 110)

                                    Circle()
                                        .trim(from: 0, to: pose.startProgress)
                                        .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                        .frame(width: 110, height: 110)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.linear(duration: 0.05), value: pose.startProgress)

                                    Image(systemName: "play.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white)
                                }

                                Text("Bring a hand close to start")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }

                        // ── Body search ──────────────────────────────────
                        if !pose.isCalibrated && !pose.gameActive && !pose.isCountingDown {
                            Text("Step in front of the camera")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.55))
                                .clipShape(Capsule())
                        }

                        // ── Countdown ────────────────────────────────────
                        if pose.isCountingDown {
                            Text(pose.countdown > 0 ? "\(pose.countdown)" : "Go!")
                                .font(.system(size: 120, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .white.opacity(0.4), radius: 20)
                                .id(pose.countdown)
                                .transition(.scale(scale: 1.4).combined(with: .opacity))
                                .animation(.easeOut(duration: 0.25), value: pose.countdown)
                        }

                        // ── Pause – body lost ────────────────────────────
                        if pose.isPaused {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text("Step back into frame")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("The game resumes when you're detected")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .multilineTextAlignment(.center)
                        }

                        // ── Phase instruction ────────────────────────────
                        VStack {
                            Spacer()
                            if pose.gameActive && pose.phase != .results && !pose.isPaused {
                                Text(pose.phase.instruction)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.55))
                                    .clipShape(Capsule())
                                    .animation(.easeInOut, value: pose.phase)
                            }
                        }
                        .padding(.bottom, 40)

                        VStack {
                            Spacer()
                            RhythmGuidePanel(
                                currentBeat: pose.currentBeat,
                                correctHits: pose.correctHits,
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

            // ── Welcome ─────────────────────────────────────────────────
            if !gameStarted {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        gameStarted = true
                    }
                }
                .transition(.opacity)
            }

            // ── Results ─────────────────────────────────────────────────
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
    }

    func visionToScreen(_ point: CGPoint, size: CGSize) -> CGPoint {
        let videoAspect: CGFloat = 4.0 / 3.0
        let screenAspect: CGFloat = size.height / size.width
        var x = point.x * size.width
        let y = (1 - point.y) * size.height
        if screenAspect > videoAspect {
            let scaledWidth = size.height / videoAspect
            let offset = (scaledWidth - size.width) / 2
            x = point.x * scaledWidth - offset
        }
        return CGPoint(x: x, y: y)
    }
}
