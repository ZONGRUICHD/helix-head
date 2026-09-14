import SwiftUI
import SceneKit

struct HeadScene: UIViewRepresentable {
    var orientation: simd_quatf
    final class Coordinator { let head = SCNNode() }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        let scene = SCNScene(); view.scene = scene
        let camera = SCNNode(); camera.camera = SCNCamera(); camera.position = SCNVector3(0, 0.25, 6.2)
        scene.rootNode.addChildNode(camera); view.pointOfView = camera
        let head = context.coordinator.head; scene.rootNode.addChildNode(head)
        let pearl = SCNMaterial(); pearl.diffuse.contents = UIColor(red: 0.78, green: 0.86, blue: 0.81, alpha: 1)
        pearl.metalness.contents = 0.65; pearl.roughness.contents = 0.28
        func part(_ geometry: SCNGeometry, _ position: SCNVector3, _ scale: SCNVector3) {
            geometry.materials = [pearl]; let node = SCNNode(geometry: geometry)
            node.position = position; node.scale = scale; head.addChildNode(node)
        }
        part(SCNSphere(radius: 1), SCNVector3(0, 0.22, 0), SCNVector3(0.73, 1.04, 0.76))
        part(SCNSphere(radius: 1), SCNVector3(0, -0.38, 0.22), SCNVector3(0.56, 0.55, 0.58))
        part(SCNCapsule(capRadius: 0.29, height: 0.8), SCNVector3(0, -1.05, 0), SCNVector3(1, 1, 1))
        part(SCNSphere(radius: 1), SCNVector3(0, 0.07, 0.76), SCNVector3(0.13, 0.25, 0.2))
        for x: Float in [-0.74, 0.74] {
            part(SCNSphere(radius: 1), SCNVector3(x, 0.1, 0), SCNVector3(0.13, 0.3, 0.21))
            let eye = SCNNode(geometry: SCNSphere(radius: 0.075))
            eye.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.08, green: 0.15, blue: 0.12, alpha: 1)
            eye.position = SCNVector3(x * 0.39, 0.3, 0.70); eye.scale = SCNVector3(1.3, 0.55, 0.5)
            head.addChildNode(eye)
        }
        for (position, intensity) in [(SCNVector3(-3, 4, 5), CGFloat(1300)), (SCNVector3(3, 1, -2), CGFloat(950))] {
            let light = SCNNode(); light.light = SCNLight(); light.light?.type = .omni
            light.light?.intensity = intensity; light.position = position; scene.rootNode.addChildNode(light)
        }
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient
        ambient.light?.intensity = 350; scene.rootNode.addChildNode(ambient)
        view.accessibilityLabel = "跟随头部姿态的三维模型"
        return view
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        SCNTransaction.begin(); SCNTransaction.animationDuration = 0
        context.coordinator.head.simdOrientation = orientation
        SCNTransaction.commit()
    }
}
