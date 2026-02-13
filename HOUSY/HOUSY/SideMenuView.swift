import SwiftUI
// Import espliciti per risolvere scope
import RoomPlan
// CubeButton, LidarView sono nello stesso modulo

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @State private var dragOffset = CGSize.zero
    @State private var showSavedProjects = false
    @StateObject private var logic = LidarLogic()
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Menu panel
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("HOUSY")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Text("Professional LiDAR Scanner")
                            ZStack {
                                // Background overlay
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        isPresented = false
                                    }
                                // Menu panel
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Header
                                        VStack(alignment: .leading, spacing: 16) {
                                            HStack {
                                                Text("HOUSY")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                Spacer()
                                            }
                        
                                            Text("Professional LiDAR Scanner")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.top, 60)
                                        .padding(.bottom, 32)
                    
                                        // Menu items
                                        VStack(spacing: 0) {
                                            // Projects section
                                            MenuSectionHeader(title: "PROJECTS")
                        
                                            MenuItemView(
                                                icon: "folder.fill",
                                                title: "Saved Projects",
                                                subtitle: "View your LiDAR scans"
                                            ) {
                                                showSavedProjects = true
                                                isPresented = false
                                            }
                        
                                            MenuItemView(
                                                icon: "square.and.arrow.down",
                                                title: "Import Project",
                                                subtitle: "Import existing scan"
                                            ) {
                                                print("Import Project tapped")
                                                isPresented = false
                                            }
                        
                                            // Settings section
                                            MenuSectionHeader(title: "SETTINGS")
                        
                                            MenuItemView(
                                                icon: "gearshape.fill",
                                                title: "Scan Settings",
                                                subtitle: "Configure quality & precision"
                                            ) {
                                                print("Scan Settings tapped")
                                                isPresented = false
                                            }
                        
                                            MenuItemView(
                                                icon: "square.and.arrow.up",
                                                title: "Export Settings",
                                                subtitle: "File formats & sharing"
                                            ) {
                                                print("Export Settings tapped")
                                                isPresented = false
                                            }
                        
                                            // Info section
                                            MenuSectionHeader(title: "INFO")
                        
                                            MenuItemView(
                                                icon: "info.circle.fill",
                                                title: "About HOUSY",
                                                subtitle: "Version & support"
                                            ) {
                                                print("About HOUSY tapped")
                                                isPresented = false
                                            }
                                        }
                    
                                        Spacer()
                                    }
                                    .frame(width: 280)
                                    .background(Color.black)
                                    .offset(x: dragOffset.width)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                // Solo swipe verso sinistra per chiudere
                                                if value.translation.width < 0 {
                                                    dragOffset = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if value.translation.width < -100 && value.velocity.width < 0 {
                                                    isPresented = false
                                                } else {
                                                    withAnimation(.spring()) {
                                                        dragOffset = .zero
                                                    }
                                                }
                                            }
                                    )
                
                                    Spacer()
                                }
                                .gesture(
                                    DragGesture()
                                        .onEnded { value in
                                            if value.translation.width < -50 {
                                                // Swipe verso sinistra per chiudere
                                                isPresented = false
                                            }
                                        }
                                )
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
                            .sheet(isPresented: $showSavedProjects) {
                                SaveProjectView(logic: logic)
                            }
                        }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SideMenuView(isPresented: .constant(true))
}
