import SwiftUI
import SceneKit

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
    
    var body: some View {
        VStack(spacing: 24) {
            Text(project.name)
                .font(.title2)
                .bold()
            SceneView(
                scene: logic.previewScene,
                options: [.autoenablesDefaultLighting, .allowsCameraControl]
            )
            .frame(height: 300)
            .cornerRadius(16)
            Text("Data: \(project.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Chiudi") {
                // handled by .sheet
            }
            .padding()
        }
        .padding()
    }
}

// Preview solo per SwiftUI Canvas
//#Preview {
//    SaveProjectView(logic: LidarLogic())
//}
