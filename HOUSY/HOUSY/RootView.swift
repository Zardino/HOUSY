import SwiftUI

struct RootView: View {
    @State private var showMainApp: Bool = false
    @State private var showCamera: Bool = false
    
    var body: some View {
        ZStack {
            if showMainApp {
                MainView()
            } else {
                SplashView(showMainApp: $showMainApp)
            }
        }
        .onChange(of: showMainApp) {
            print("[RootView] showMainApp changed: \(showMainApp)")
        }
    }
}

#Preview {
    RootView()
}
