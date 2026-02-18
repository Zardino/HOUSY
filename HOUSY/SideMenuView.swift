import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var showSavedProjects = false
    // TODO: Ricreare logic quando avremo la nuova implementazione scansione

    var body: some View {
        ZStack(alignment: .leading) {
            // overlay scuro
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // pannello menu
            VStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: 10) {
                    Text("HOUSY")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Professional LiDAR Scanner")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 28)

                VStack(spacing: 0) {

                    MenuSectionHeader(title: "PROJECTS")

                    MenuItemView(
                        icon: "folder.fill",
                        title: "Saved Projects",
                        subtitle: "View your LiDAR scans"
                    ) {
                        // Temporaneamente disabilitato
                        print("⚠️ Saved Projects - Da implementare con nuovo sistema")
                        isPresented = false
                    }

                    MenuItemView(
                        icon: "square.and.arrow.down",
                        title: "Import Project",
                        subtitle: "Import existing scan"
                    ) {
                        isPresented = false
                        print("Import Project tapped")
                    }

                    MenuSectionHeader(title: "SETTINGS")

                    MenuItemView(
                        icon: "gearshape.fill",
                        title: "Scan Settings",
                        subtitle: "Configure quality & precision"
                    ) {
                        isPresented = false
                        print("Scan Settings tapped")
                    }

                    MenuItemView(
                        icon: "square.and.arrow.up",
                        title: "Export Settings",
                        subtitle: "File formats & sharing"
                    ) {
                        isPresented = false
                        print("Export Settings tapped")
                    }

                    MenuSectionHeader(title: "INFO")

                    MenuItemView(
                        icon: "info.circle.fill",
                        title: "About HOUSY",
                        subtitle: "Version & support"
                    ) {
                        isPresented = false
                        print("About HOUSY tapped")
                    }
                }

                Spacer()
            }
            .frame(width: 280)
            .background(Color.black)
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // trascina solo verso sinistra (chiusura)
                        if value.translation.width < 0 {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -90 {
                            isPresented = false
                        }
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: dragOffset)
        // Sheet temporaneamente disabilitata
        // .sheet(isPresented: $showSavedProjects) { ... }
    }
}

private struct MenuSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 6)
    }
}

private struct MenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SideMenuView(isPresented: .constant(true))
}

#Preview {
    SideMenuView(isPresented: .constant(true))
}
