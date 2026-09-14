import XCTest
import simd
@testable import HelixHead

final class PoseTests: XCTestCase {
    func testRecenterIsIdentityForCombinedRotation() {
        let q = simd_quatf(angle: 1.1, axis: simd_normalize(SIMD3<Float>(1, 2, 3)))
        XCTAssertEqual(abs(simd_dot(Pose.relative(q, to: q).vector, Pose.identity.vector)), 1, accuracy: 0.00001)
    }
    func testLeftTurnMovesFrontalAvatarNoseLeft() {
        let result = Pose.scene(simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1)))
        let forward = result.act(SIMD3<Float>(0, 0, 1))
        XCTAssertEqual(forward.x, -1, accuracy: 0.00001)
        XCTAssertEqual(forward.y, 0, accuracy: 0.00001)
    }
    func testLookUpMovesFrontalAvatarNoseUp() {
        let result = Pose.scene(simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0)))
        let nose = result.act(SIMD3<Float>(0, 0, 1))
        XCTAssertEqual(nose.y, 1, accuracy: 0.00001)
    }
    func testRightTiltMovesFrontalAvatarCrownRight() {
        let result = Pose.scene(simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0)))
        let crown = result.act(SIMD3<Float>(0, 1, 0))
        XCTAssertEqual(crown.x, 1, accuracy: 0.00001)
    }
    func testWraparoundUsesShortestPath() {
        let a = simd_quatf(angle: 179 * .pi / 180, axis: SIMD3<Float>(0, 0, 1))
        let b = simd_quatf(angle: -179 * .pi / 180, axis: SIMD3<Float>(0, 0, 1))
        XCTAssertEqual(abs(Pose.degrees(Pose.relative(b, to: a)).x), 2, accuracy: 0.001)
    }
    @MainActor func testPausePreventsDemoUpdates() async throws {
        let store = MotionStore(); store.demo()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(store.canRecenter)
        store.recenter(); XCTAssertEqual(store.angles.x, 0)
        store.pause(); let snapshot = store.orientation
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(store.mode, .paused)
        XCTAssertEqual(store.orientation.vector, snapshot.vector)
        XCTAssertTrue(store.history.isEmpty)
        XCTAssertFalse(store.canRecenter)
    }
}
