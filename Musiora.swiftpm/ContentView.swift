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
                
                VStack {
                    Spacer()
                    Text(pose.isCalibrated ? "✅ Cuerpo detectado" : "⏳ Buscando cuerpo...")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
        .task { await pose.start() }
    }
    
    func visionToScreen(_ point: CGPoint, size: CGSize) -> CGPoint {
        // Buffer de cámara es 4:3, pantalla es más alta
        // resizeAspectFill escala al alto y recorta los lados
        let videoAspect: CGFloat = 4.0 / 3.0
        let screenAspect: CGFloat = size.height / size.width
        
        var x = point.x * size.width
        let y = point.y * size.height
        
        if screenAspect > videoAspect {
            // Pantalla más alta — video se recorta horizontalmente
            let scaledWidth = size.height / videoAspect
            let offset = (scaledWidth - size.width) / 2
            x = point.x * scaledWidth - offset
        }
        
        return CGPoint(x: x, y: y)
    }
}
