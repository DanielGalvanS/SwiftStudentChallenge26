import SwiftUI
import Vision

struct ContentView: View {
    @State private var pose = PoseDetectorVM()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreviewView(session: pose.session)
                    .ignoresSafeArea()
                
                ForEach(Array(pose.bodyPoints.keys), id: \.rawValue) { joint in
                    if let point = pose.bodyPoints[joint] {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .position(visionToScreen(point, size: geo.size))
                    }
                }
                
                BodyLabelsOverlay(
                    bodyPoints: pose.bodyPoints,
                    size: geo.size,
                    activeMovements: pose.activeMovements
                )
                
                VStack {
                    Spacer()
                    Text(pose.isCalibrated ? "✅ Cuerpo detectado" : "⏳ Buscando cuerpo...")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
                
                VStack {
                    Spacer()
                    RhythmGuidePanel(
                        currentBeat: pose.currentBeat,
                        activeMovements: pose.activeMovements
                    )
                    .padding(.bottom, 80)
                }
            }
        }
        .task { await pose.start() }
    }
    
    func visionToScreen(_ point: CGPoint, size: CGSize) -> CGPoint {
        let videoAspect: CGFloat = 4.0 / 3.0
        let screenAspect: CGFloat = size.height / size.width

        // Vision origin: bottom-left, Y up → invertir Y
        // X: Vision no tiene espejo, pero el preview sí → espejear X
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
