import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Sfondo rosso temporaneo
            Color.red
                .ignoresSafeArea()
            
            VStack {
                // Top bar con bottone back
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // Testo placeholder
                Text("CAMERA VIEW")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Ready for implementation")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 8)
                
                Spacer()
            }
        }
    }
}

#Preview {
    CameraView()
}
