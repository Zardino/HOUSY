import SwiftUI
import SceneKit

// MARK: - TEMPORANEAMENTE DISABILITATO
// TODO: Ricreare quando avremo il nuovo sistema di scansione

/*
struct SaveProjectView: View {
    @ObservedObject var logic: LidarLogic
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationStack {
            List(logic.savedProjects) { project in
                Button(action: {
                    selectedProject = project
                }) {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                        Text(project.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Saved Projects")
            .sheet(item: $selectedProject) { project in
                Project3DPreviewView(project: project, logic: logic)
            }
        }
    }
}

struct Project3DPreviewView: View {
    let project: Project
    let logic: LidarLogic
    @State private var scene: SCNScene?
    
    var body: some View {
        VStack(spacing: 24) {
            Text(project.name)
                .font(.title2)
                .bold()
            
            if let scene = scene {
                SceneView(
                    scene: scene,
                    options: [.autoenablesDefaultLighting, .allowsCameraControl]
                )
                .frame(height: 300)
                .cornerRadius(16)
            } else {
                // Placeholder se il modello non è caricato
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .cornerRadius(16)
                    VStack {
                        ProgressView()
                        Text("Caricamento modello 3D...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
            
            Text("Data: \(project.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Chiudi") {
                // handled by .sheet
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .onAppear {
            loadProjectModel()
        }
    }
    
    private func loadProjectModel() {
        guard let modelPath = project.modelPath else {
            print("⚠️ Nessun modello 3D salvato per questo progetto")
            return
        }
        
        let url = URL(fileURLWithPath: modelPath)
        
        do {
            let loadedScene = try SCNScene(url: url, options: nil)
            self.scene = loadedScene
            print("✅ Modello 3D caricato: \(modelPath)")
        } catch {
            print("❌ Errore caricamento modello: \(error.localizedDescription)")
            // Fallback
            self.scene = logic.previewScene
        }
    }
}
*/

// Placeholder temporaneo
struct SaveProjectView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("SAVED PROJECTS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Feature coming soon")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
            }
        }
    }
}

// Preview solo per SwiftUI Canvas
#Preview {
    SaveProjectView()
}
