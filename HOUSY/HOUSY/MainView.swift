import SwiftUI
// Import espliciti per risolvere scope
import RoomPlan
// CubeButton, SideMenuView sono nello stesso modulo


struct MainView: View {
    @State private var showSideMenu = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var showCameraView = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()

                VStack {
                    // Top navigation bar
                    HStack {
                        // HOUSY title on the left
                        Text("HOUSY")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 12)

                        Spacer()

                        // Hamburger menu on the right
                        Button(action: {
                            showSideMenu = true
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()

                    // Main content area
                    VStack {
                        Spacer()
                        Spacer()
                    }

                    // LIDAR Cube Button (disabilitato)
                    VStack {
                        Button(action: {
                            showCameraView = true
                        }) {
                            CubeButton()
                        }
                        .padding(.bottom, 30)
                    }
                }

                // Side menu overlay
                if showSideMenu {
                    SideMenuView(isPresented: $showSideMenu)
                        .transition(AnyTransition.move(edge: .leading))
                        .zIndex(1)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        // Swipe verso sinistra per chiudere
                                        showSideMenu = false
                                    }
                                }
                        )
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSideMenu)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        if !showSideMenu && value.translation.width > 50 {
                            // Swipe verso destra per aprire
                            showSideMenu = true
                        }
                    }
            )
            .navigationDestination(isPresented: $showCameraView) {
                CameraView()
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    MainView()
}
