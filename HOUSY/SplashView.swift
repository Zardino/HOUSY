import SwiftUI

struct SplashView: View {
    @State private var progress: Double = 0.0
    @State private var isComplete: Bool = false
    @Binding var showMainApp: Bool
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // HOUSY title
                Text("HOUSY")
                    .font(.system(size: 48, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .tracking(2.0)
                
                Spacer()
                
                // Progress section
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            // Progress fill
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                                .cornerRadius(2)
                                .animation(.linear(duration: 0.1), value: progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 60)
                    
                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        // Reset progress
        progress = 0.0
        isComplete = false
        
        // Animate progress over 3 seconds
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.0167 // Increment to reach 100% in 3 seconds (60 updates)
            } else {
                timer.invalidate()
                
                // Small delay at 100% then transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMainApp = true
                }
            }
        }
    }
}

#Preview {
    SplashView(showMainApp: .constant(false))
}
