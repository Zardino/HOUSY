

import SwiftUI
struct CubeButton: View {
    var isActive: Bool = false
    @State private var meshAngle: Double = 0
    @State private var showGrid: Bool = false
    let gridColor = Color.white.opacity(0.22)
    let meshColor = Color.blue.opacity(0.18)

    var body: some View {
        ZStack {
            // Precision grid lock
            if isActive {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 90, height: 90)
                    .overlay(
                        PrecisionGrid(show: showGrid, color: gridColor)
                            .clipShape(Circle())
                            .animation(.easeOut(duration: 0.7), value: showGrid)
                    )
            }

            // Rotating mesh overlay
            if isActive {
                RotatingMesh(angle: meshAngle, color: meshColor)
                    .frame(width: 90, height: 90)
                    .animation(.linear(duration: 2.5).repeatForever(autoreverses: false), value: meshAngle)
            }

            // Main icon
            Image(systemName: "cube.transparent")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(isActive ? Color.blue : Color.white)
                .shadow(color: isActive ? Color.blue.opacity(0.18) : Color.clear, radius: isActive ? 12 : 0)
        }
        .onAppear {
            if isActive {
                showGrid = true
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    meshAngle = 2 * .pi
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                showGrid = true
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    meshAngle = 2 * .pi
                }
            } else {
                showGrid = false
                meshAngle = 0
            }
        }
    }
}

// Griglia tecnica che si "blocca" in posizione
struct PrecisionGrid: View {
    var show: Bool
    var color: Color
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let lines: [CGFloat] = [0.25, 0.5, 0.75]
            ZStack {
                ForEach(lines, id: \ .self) { pos in
                    Path { path in
                        // Vertical
                        path.move(to: CGPoint(x: width * pos, y: 0))
                        path.addLine(to: CGPoint(x: width * pos, y: height))
                        // Horizontal
                        path.move(to: CGPoint(x: 0, y: height * pos))
                        path.addLine(to: CGPoint(x: width, y: height * pos))
                    }
                    .trim(from: 0, to: show ? 1 : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }
            }
        }
    }
}

// Mesh ruotante sottile
struct RotatingMesh: View {
    var angle: Double
    var color: Color
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                ForEach(0..<6, id: \ .self) { i in
                    Path { path in
                        let theta = angle + Double(i) * .pi / 3
                        let r = width / 2
                        let center = CGPoint(x: width/2, y: height/2)
                        let end = CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
                        path.move(to: center)
                        path.addLine(to: end)
                    }
                    .stroke(color, lineWidth: 1)
                }
            }
        }
    }
}

// Preview solo per SwiftUI Canvas/Xcode compatibile
//struct CubeButton_Previews: PreviewProvider {
//    static var previews: some View {
//        CubeButton(isActive: true)
//            .background(Color.black)
//    }
//}
