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
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 1.7
        scene.rootNode.addChildNode(camera); view.pointOfView = camera
        let head = context.coordinator.head; scene.rootNode.addChildNode(head)
        let pearl = SCNMaterial(); pearl.diffuse.contents = UIColor(red: 0.78, green: 0.86, blue: 0.81, alpha: 1)
        pearl.metalness.contents = 0.65; pearl.roughness.contents = 0.28
        func part(_ geometry: SCNGeometry, _ position: SCNVector3, _ scale: SCNVector3) {
            geometry.materials = [pearl]; let node = SCNNode(geometry: geometry)
            node.position = position; node.scale = scale; head.addChildNode(node)
        }
        part(Self.sculptedHead(), SCNVector3Zero, SCNVector3(1, 1, 1))
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

    // A single smooth mesh avoids intersecting skull/jaw seams.
    private static func sculptedHead() -> SCNGeometry {
        // radius X, radius Z, forward offset; bottom to crown.
        let profile: [SIMD3<Float>] = [
            SIMD3(0.02, 0.02, 0.20), SIMD3(0.35, 0.35, 0.20),
            SIMD3(0.51, 0.48, 0.15), SIMD3(0.64, 0.60, 0.07),
            SIMD3(0.71, 0.69, 0.02), SIMD3(0.73, 0.73, 0),
            SIMD3(0.70, 0.72, -0.02), SIMD3(0.61, 0.65, -0.04),
            SIMD3(0.43, 0.48, -0.06), SIMD3(0.02, 0.02, -0.06)
        ]
        let rings = 72, segments = 64
        func sample(_ t: Float) -> SIMD3<Float> {
            let u = max(0, min(1, t)) * Float(profile.count - 1)
            let i = min(Int(u), profile.count - 2), f = u - Float(i)
            let a = profile[max(0, i - 1)], b = profile[i]
            let c = profile[i + 1], d = profile[min(profile.count - 1, i + 2)]
            let linear = (c - a) * f
            let quadratic = (2 * a - 5 * b + 4 * c - d) * f * f
            let cubic = (-a + 3 * b - 3 * c + d) * f * f * f
            return (2 * b + linear + quadratic + cubic) * 0.5
        }
        var vertices: [SCNVector3] = [], normals: [SCNVector3] = [], indices: [Int32] = []
        for ring in 0...rings {
            let t = Float(ring) / Float(rings), p = sample(t)
            let low = max(0, t - 0.001), high = min(1, t + 0.001)
            let delta = (sample(high) - sample(low)) / (high - low)
            for segment in 0...segments {
                let theta = Float(segment) / Float(segments) * 2 * .pi
                let c = cos(theta), s = sin(theta)
                vertices.append(SCNVector3(p.x * c, -0.91 + t * 2.17, p.z + p.y * s))
                let vertical = SIMD3<Float>(delta.x * c, 2.17, delta.z + delta.y * s)
                let tangent = SIMD3<Float>(-p.x * s, 0, p.y * c)
                let normal = simd_normalize(simd_cross(vertical, tangent))
                normals.append(SCNVector3(normal.x, normal.y, normal.z))
                if ring < rings && segment < segments {
                    let a = Int32(ring * (segments + 1) + segment), b = a + Int32(segments + 1)
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        return SCNGeometry(sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
                           elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    }
}
