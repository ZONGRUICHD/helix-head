import Foundation
import simd

struct Pose {
    static let identity = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    // Core Motion: X right, Y forward, Z up. Our avatar faces the viewer (+Z).
    // Mirror positions across depth: M(x,y,z)=(x,z,y). Rotation axes are
    // pseudovectors, so map them by det(M)*M: (x,y,z)->(-x,-z,-y).
    // This makes looking up lift the avatar's nose and right tilt lean right.
    static let basis = simd_quatf(angle: .pi, axis: simd_normalize(SIMD3<Float>(0, 1, -1)))
    static func relative(_ current: simd_quatf, to reference: simd_quatf) -> simd_quatf {
        simd_normalize(reference.inverse * current)
    }
    static func scene(_ relative: simd_quatf) -> simd_quatf {
        simd_normalize(basis * relative * basis.inverse)
    }
    static func degrees(_ q: simd_quatf) -> SIMD3<Double> {
        let x = Double(q.imag.x), y = Double(q.imag.y), z = Double(q.imag.z), w = Double(q.real)
        return SIMD3(atan2(2 * (w*z + x*y), 1 - 2 * (y*y + z*z)),
                     atan2(2 * (w*x + y*z), 1 - 2 * (x*x + y*y)),
                     asin(max(-1, min(1, 2 * (w*y - z*x))))) * (180 / .pi)
    }
}
