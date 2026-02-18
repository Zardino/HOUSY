// IMPORTANT: Add NSCameraUsageDescription to Info.plist to access the camera.
import SwiftUI
import ARKit
import RealityKit
import SceneKit
import Metal

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ScanManager()

    var body: some View {
        ZStack {
            ARViewContainer(manager: manager)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                Spacer()
                debugOverlay
                controls
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(.black)
        .onAppear { manager.prepareIfNeeded() }
        .fullScreenCover(isPresented: $manager.showViewer) {
            if let url = manager.savedURL {
                SceneKitPreviewScreen(url: url)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.45), in: Circle())
            }

            Spacer()

            Text(manager.status.rawValue)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6), in: Capsule())
                .foregroundStyle(.white)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                manager.startScan()
            } label: {
                Text("START SCAN")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!manager.canStart)

            Button {
                manager.stopScan()
            } label: {
                Text("STOP / FINE SCAN")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(!manager.canStop)
        }
        .padding(10)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("anchorsCount: \(manager.anchorsCount)")
            Text(String(format: "updateRate: %.1f Hz", manager.updateRate))
            Text("lastLog: \(manager.lastLog)")
            Text("error: \(manager.errorMessage.isEmpty ? "none" : manager.errorMessage)")
                .foregroundStyle(manager.errorMessage.isEmpty ? .white : .red)
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var manager: ScanManager

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        view.renderOptions.insert(.disableMotionBlur)
        view.environment.background = .cameraFeed()
        manager.attachARView(view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        manager.attachARView(uiView)
    }
}

enum ScanStatus: String {
    case idle, scanning, finishing, saved, error
}

private struct MeshCacheData {
    let verticesWorld: [SIMD3<Float>]
    let faces: [SIMD3<UInt32>]
}

final class ScanManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var status: ScanStatus = .idle
    @Published var anchorsCount: Int = 0
    @Published var updateRate: Double = 0
    @Published var lastLog: String = "ready"
    @Published var errorMessage: String = ""
    @Published var savedURL: URL?
    @Published var showViewer: Bool = false

    private(set) var supportsMeshReconstruction = false
    var canStart: Bool { supportsMeshReconstruction && status != .scanning && status != .finishing }
    var canStop: Bool { status == .scanning }

    private weak var arView: ARView?
    private let processQueue = DispatchQueue(label: "scan.mesh.process", qos: .userInitiated)
    private var isScanning = false
    private var isFinishing = false
    private var lastAnchorUpdateTime = Date.distantPast
    private let minUpdateInterval: TimeInterval = 1.0 / 12.0

    private var meshCache: [UUID: MeshCacheData] = [:]
    private var meshEntities: [UUID: ModelEntity] = [:]
    private var rootEntity = AnchorEntity(world: .zero)

    private var updateCounter = 0
    private var rateTimer: DispatchSourceTimer?

    func prepareIfNeeded() {
        supportsMeshReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        if !supportsMeshReconstruction {
            fail("LiDAR mesh reconstruction not supported on this device")
        } else if status == .error {
            status = .idle
            errorMessage = ""
        }
        startRateTimerIfNeeded()
    }

    func attachARView(_ view: ARView) {
        guard arView !== view else { return }
        arView = view
        if !view.scene.anchors.contains(where: { $0 === rootEntity }) {
            view.scene.addAnchor(rootEntity)
        }
    }

    func startScan() {
        guard canStart, let arView else { return }
        guard !isScanning else { return }

        log("starting scan")
        status = .scanning
        errorMessage = ""
        savedURL = nil
        showViewer = false
        isScanning = true
        isFinishing = false

        meshCache.removeAll(keepingCapacity: true)
        anchorsCount = 0

        for entity in meshEntities.values { entity.removeFromParent() }
        meshEntities.removeAll(keepingCapacity: true)

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics.insert(.smoothedSceneDepth)
        }

        DispatchQueue.main.async {
            arView.session.delegate = self
            arView.session.delegateQueue = self.processQueue
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
    }

    func stopScan() {
        guard status == .scanning else { return }
        guard !isFinishing else { return }
        isScanning = false
        isFinishing = true
        status = .finishing
        log("finishing scan")

        let snapshot = meshCache
        processQueue.async {
            do {
                let url = try Self.exportOBJ(from: snapshot)
                DispatchQueue.main.async {
                    self.savedURL = url
                    self.status = .saved
                    self.isFinishing = false
                    self.showViewer = true
                    self.log("saved: \(url.lastPathComponent)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.fail("Export failed: \(error.localizedDescription)")
                    self.isFinishing = false
                }
            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        handle(anchorEvents: anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        handle(anchorEvents: anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let ids = anchors.map(\.identifier)
        DispatchQueue.main.async {
            for id in ids {
                self.meshCache.removeValue(forKey: id)
                if let entity = self.meshEntities.removeValue(forKey: id) {
                    entity.removeFromParent()
                }
            }
            self.anchorsCount = self.meshCache.count
        }
    }

    private func handle(anchorEvents: [ARAnchor]) {
        guard isScanning, !isFinishing else { return }
        let now = Date()
        guard now.timeIntervalSince(lastAnchorUpdateTime) >= minUpdateInterval else { return }
        lastAnchorUpdateTime = now

        let meshAnchors = anchorEvents.compactMap { $0 as? ARMeshAnchor }
        guard !meshAnchors.isEmpty else { return }

        for meshAnchor in meshAnchors {
            guard let meshData = Self.extractMeshData(from: meshAnchor) else { continue }
            updateCounter += 1
            DispatchQueue.main.async {
                self.meshCache[meshAnchor.identifier] = meshData
                self.anchorsCount = self.meshCache.count
                self.upsertLiveEntity(for: meshAnchor.identifier, data: meshData)
            }
        }
    }

    private func upsertLiveEntity(for id: UUID, data: MeshCacheData) {
        guard !data.verticesWorld.isEmpty, !data.faces.isEmpty else { return }
        let descriptor = MeshDescriptor()
        var meshDescriptor = descriptor
        meshDescriptor.positions = .init(data.verticesWorld)

        let indices = data.faces.flatMap { [UInt32($0.x), UInt32($0.y), UInt32($0.z)] }
        meshDescriptor.primitives = .triangles(indices)

        guard let mesh = try? MeshResource.generate(from: [meshDescriptor]) else { return }
        let material = SimpleMaterial(color: UIColor.systemTeal.withAlphaComponent(0.35), roughness: 1.0, isMetallic: false)

        if let entity = meshEntities[id] {
            entity.model = ModelComponent(mesh: mesh, materials: [material])
        } else {
            let entity = ModelEntity(mesh: mesh, materials: [material])
            meshEntities[id] = entity
            rootEntity.addChild(entity)
        }
    }

    private func log(_ message: String) {
        DispatchQueue.main.async { self.lastLog = message }
    }

    private func fail(_ message: String) {
        DispatchQueue.main.async {
            self.status = .error
            self.errorMessage = message
            self.lastLog = message
            self.isScanning = false
            self.isFinishing = false
        }
    }

    private func startRateTimerIfNeeded() {
        guard rateTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.updateRate = Double(self.updateCounter)
            self.updateCounter = 0
        }
        rateTimer = timer
        timer.resume()
    }

    private static func extractMeshData(from anchor: ARMeshAnchor) -> MeshCacheData? {
        let geometry = anchor.geometry
        let vertices = geometry.vertices
        let faces = geometry.faces

        guard vertices.count > 0, faces.count > 0 else { return nil }

        var worldVertices: [SIMD3<Float>] = []
        worldVertices.reserveCapacity(vertices.count)
        let transform = anchor.transform

        for index in 0..<vertices.count {
            let local = geometry.vertex(at: UInt32(index))
            let world4 = transform * SIMD4<Float>(local.x, local.y, local.z, 1)
            worldVertices.append(SIMD3<Float>(world4.x, world4.y, world4.z))
        }

        var tris: [SIMD3<UInt32>] = []
        tris.reserveCapacity(faces.count)

        for faceIndex in 0..<faces.count {
            guard let face = geometry.face(at: faceIndex) else { continue }
            if face.count == 3 {
                tris.append(SIMD3<UInt32>(face[0], face[1], face[2]))
            }
        }

        return MeshCacheData(verticesWorld: worldVertices, faces: tris)
    }

    private static func exportOBJ(from cache: [UUID: MeshCacheData]) throws -> URL {
        guard !cache.isEmpty else {
            throw NSError(domain: "ScanExport", code: -10, userInfo: [NSLocalizedDescriptionKey: "No mesh data captured"])
        }

        let dir = try scansDirectory()
        let stamp = Self.timestampString()
        let objURL = dir.appendingPathComponent("scan_\(stamp).obj")
        let mtlURL = dir.appendingPathComponent("scan_\(stamp).mtl")

        var objLines: [String] = []
        objLines.reserveCapacity(1024)
        objLines.append("mtllib \(mtlURL.lastPathComponent)")
        objLines.append("o scan_mesh")
        objLines.append("usemtl scanMaterial")

        var vertexOffset: UInt32 = 1

        for mesh in cache.values {
            for v in mesh.verticesWorld {
                objLines.append("v \(v.x) \(v.y) \(v.z)")
            }
            for f in mesh.faces {
                let a = f.x + vertexOffset
                let b = f.y + vertexOffset
                let c = f.z + vertexOffset
                objLines.append("f \(a) \(b) \(c)")
            }
            vertexOffset += UInt32(mesh.verticesWorld.count)
        }

        let objData = objLines.joined(separator: "\n")
        try objData.write(to: objURL, atomically: true, encoding: .utf8)

        let mtl = """
        newmtl scanMaterial
        Ka 0.1 0.7 0.8
        Kd 0.2 0.9 1.0
        Ks 0.0 0.0 0.0
        d 1.0
        illum 1
        """
        try mtl.write(to: mtlURL, atomically: true, encoding: .utf8)

        return objURL
    }

    private static func scansDirectory() throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scans = docs.appendingPathComponent("Scans", isDirectory: true)
        if !FileManager.default.fileExists(atPath: scans.path) {
            try FileManager.default.createDirectory(at: scans, withIntermediateDirectories: true)
        }
        return scans
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

private extension ARMeshGeometry {
    func vertex(at index: UInt32) -> SIMD3<Float> {
        let vertices = self.vertices
        let bufferPointer = vertices.buffer.contents().advanced(by: vertices.offset + vertices.stride * Int(index))
        let float3Ptr = bufferPointer.bindMemory(to: (Float, Float, Float).self, capacity: 1)
        let tuple = float3Ptr.pointee
        return SIMD3<Float>(tuple.0, tuple.1, tuple.2)
    }

    func face(at index: Int) -> [UInt32]? {
        let faces = self.faces
        let countPerFace = faces.indexCountPerPrimitive
        guard countPerFace >= 3 else { return nil }

        let offset = index * faces.bytesPerIndex * countPerFace
        let base = faces.buffer.contents().advanced(by: offset)

        var indices: [UInt32] = []
        indices.reserveCapacity(countPerFace)

        for i in 0..<countPerFace {
            let addr = base.advanced(by: i * faces.bytesPerIndex)
            let value: UInt32
            if faces.bytesPerIndex == MemoryLayout<UInt16>.size {
                value = UInt32(addr.bindMemory(to: UInt16.self, capacity: 1).pointee)
            } else {
                value = addr.bindMemory(to: UInt32.self, capacity: 1).pointee
            }
            indices.append(value)
        }

        return indices
    }
}

private struct SceneKitPreviewScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneKitModelViewer(url: url)
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.6), in: Circle())
            }
            .padding(16)
        }
    }
}

private struct SceneKitModelViewer: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .black
        view.allowsCameraControl = true
        view.defaultCameraController.inertiaEnabled = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.autoenablesDefaultLighting = true
        view.rendersContinuously = true

        let scene: SCNScene
        if let loaded = try? SCNScene(url: url, options: nil) {
            scene = loaded
        } else {
            scene = SCNScene()
        }

        if scene.rootNode.childNodes.isEmpty {
            let text = SCNText(string: "Unable to load model", extrusionDepth: 1)
            text.font = UIFont.systemFont(ofSize: 6, weight: .semibold)
            text.firstMaterial?.diffuse.contents = UIColor.white
            let node = SCNNode(geometry: text)
            node.position = SCNVector3(-15, 0, 0)
            scene.rootNode.addChildNode(node)
        }

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.001
        camera.zFar = 500
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        view.pointOfView = cameraNode

        view.scene = scene
        context.coordinator.configure(view: view, cameraNode: cameraNode)

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)

        context.coordinator.fitToModel(animated: false)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    final class Coordinator: NSObject {
        weak var scnView: SCNView?
        weak var cameraNode: SCNNode?

        func configure(view: SCNView, cameraNode: SCNNode) {
            self.scnView = view
            self.cameraNode = cameraNode
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            fitToModel(animated: true)
        }

        func fitToModel(animated: Bool) {
            guard let view = scnView,
                  let scene = view.scene,
                  let cameraNode = cameraNode else { return }

            let bounds = scene.rootNode.worldBoundingBoxExcludingCamera
            let min = bounds.min
            let max = bounds.max

            let centerX = (min.x + max.x) * 0.5
            let centerY = (min.y + max.y) * 0.5
            let centerZ = (min.z + max.z) * 0.5
            let center = SCNVector3(centerX, centerY, centerZ)
            
            let dx = max.x - min.x
            let dy = max.y - min.y
            let dz = max.z - min.z
            let radius = max(0.01, sqrt(dx * dx + dy * dy + dz * dz) * 0.5)
            let distance = max(Double(radius) * 2.8, 0.35)
            let targetPos = SCNVector3(center.x, center.y, center.z + Float(distance))

            let apply = {
                cameraNode.position = targetPos
                cameraNode.lookAt(center)
            }

            if animated {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.45
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                apply()
                SCNTransaction.commit()
            } else {
                apply()
            }
        }
    }
}

private extension SCNNode {
    var worldBoundingBoxExcludingCamera: (min: SCNVector3, max: SCNVector3) {
        var minOut = SCNVector3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
        var maxOut = SCNVector3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
        var found = false
        let zero = SCNVector3Zero

        enumerateChildNodes { node, _ in
            guard node.camera == nil else { return }
            let (bmin, bmax) = node.boundingBox
            guard bmin.x.isFinite, bmax.x.isFinite,
                  bmin != zero || bmax != zero else { return }

            let corners = [
                SCNVector3(bmin.x, bmin.y, bmin.z), SCNVector3(bmin.x, bmin.y, bmax.z),
                SCNVector3(bmin.x, bmax.y, bmin.z), SCNVector3(bmin.x, bmax.y, bmax.z),
                SCNVector3(bmax.x, bmin.y, bmin.z), SCNVector3(bmax.x, bmin.y, bmax.z),
                SCNVector3(bmax.x, bmax.y, bmin.z), SCNVector3(bmax.x, bmax.y, bmax.z)
            ]

            for c in corners {
                let w = node.convertPosition(c, to: nil)
                minOut.x = min(minOut.x, w.x)
                minOut.y = min(minOut.y, w.y)
                minOut.z = min(minOut.z, w.z)
                maxOut.x = max(maxOut.x, w.x)
                maxOut.y = max(maxOut.y, w.y)
                maxOut.z = max(maxOut.z, w.z)
                found = true
            }
        }

        if !found {
            return (SCNVector3(-0.1, -0.1, -0.1), SCNVector3(0.1, 0.1, 0.1))
        }
        return (minOut, maxOut)
    }
}

#Preview {
    CameraView()
}
