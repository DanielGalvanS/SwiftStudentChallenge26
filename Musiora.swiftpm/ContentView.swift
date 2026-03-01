import SwiftUI
import Vision

struct ContentView: View {
    @State private var pose = PoseDetectorVM()
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            // ── Cámara + juego ──────────────────────────────────────────
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

                        // Overlay de pausa cuando se pierde el cuerpo
                        if pose.isPaused {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text("Vuelve al encuadre")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("El juego continúa cuando te detecte")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .multilineTextAlignment(.center)
                        }

                        VStack {
                            Spacer()

                            if !pose.isCalibrated && !pose.isPaused {
                                Text("⏳ Buscando cuerpo...")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.black.opacity(0.55))
                                    .clipShape(Capsule())
                            } else if pose.gameActive && pose.phase != .results && !pose.isPaused {
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

            // ── Bienvenida ──────────────────────────────────────────────
            if !gameStarted {
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        gameStarted = true
                    }
                }
                .transition(.opacity)
            }

            // ── Resultados ──────────────────────────────────────────────
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
