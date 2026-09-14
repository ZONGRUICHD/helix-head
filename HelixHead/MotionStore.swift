import CoreMotion
import SwiftUI
import Combine
import simd

@MainActor final class MotionStore: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    enum Mode: String { case idle = "尚未开始", waiting = "等待 AirPods", live = "实时跟踪", demo = "演示模式", paused = "已暂停", denied = "运动权限未开启", failed = "连接中断" }
    @Published private(set) var mode: Mode = .idle
    @Published private(set) var orientation = Pose.identity
    @Published private(set) var angles = SIMD3<Double>.zero
    @Published private(set) var rate = 0.0
    @Published private(set) var detail = "戴好 AirPods，在蓝牙设置中连接，然后开始跟踪。"
    @Published private(set) var history: [Double] = []
    @Published var smoothing = true
    private let manager = CMHeadphoneMotionManager()
    private var reference: simd_quatf?
    private var raw = Pose.identity
    private var filtered = Pose.identity
    private var lastTimestamp: Double?
    private var lastArrival = Date.distantPast
    private var timer: Timer?
    private var generation = 0
    private var wantsLive = false
    private var hasSample = false
    var running: Bool { wantsLive || mode == .demo }
    var canRecenter: Bool { hasSample && (mode == .live || mode == .demo) }

    override init() { super.init(); manager.delegate = self }

    func start() {
        stopResources()
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .denied, .restricted:
            mode = .denied; detail = "请在系统设置中允许 Helix Head 访问运动与健身。"; return
        default: break
        }
        wantsLive = true
        mode = .waiting
        detail = "等待耳机运动数据。请佩戴支持头部跟踪的 AirPods，并连接这台设备。"
        let token = generation
        // Start even when unavailable: Core Motion can begin delivering after connection.
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, self.generation == token, self.wantsLive else { return }
            if let error {
                self.stopResources()
                self.mode = CMHeadphoneMotionManager.authorizationStatus() == .denied ? .denied : .failed
                self.detail = error.localizedDescription
                return
            }
            guard let motion else { return }
            let q = motion.attitude.quaternion
            self.receive(simd_quatf(ix: Float(q.x), iy: Float(q.y), iz: Float(q.z), r: Float(q.w)), timestamp: motion.timestamp)
            self.mode = .live
            self.detail = "动作正在实时映射。面向屏幕，轻点归零设置正前方。"
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.wantsLive else { return }
                if self.mode == .live && Date().timeIntervalSince(self.lastArrival) > 2 {
                    self.mode = .waiting; self.rate = 0; self.hasSample = false
                    self.reference = nil; self.lastTimestamp = nil
                    self.detail = "数据已停止。检查耳机佩戴和蓝牙连接，恢复后将自动重新归零。"
                }
            }
        }
    }

    func demo() {
        stopResources(); mode = .demo
        detail = "这是模拟动作，不是 AirPods 传感器数据。"
        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.mode == .demo else { return }
                let t = Date().timeIntervalSince(start)
                let yaw = simd_quatf(angle: Float(sin(t * 0.7)) * 0.65, axis: SIMD3(0, 0, 1))
                let pitch = simd_quatf(angle: Float(sin(t * 1.1)) * 0.25, axis: SIMD3(1, 0, 0))
                let roll = simd_quatf(angle: Float(sin(t * 0.5)) * 0.18, axis: SIMD3(0, 1, 0))
                self.receive(yaw * pitch * roll, timestamp: t)
            }
        }
    }

    func pause() { stopResources(); mode = .paused; detail = "已停止读取运动数据。轻点开始跟踪以继续。" }
    func recenter() {
        guard canRecenter else { return }
        reference = raw; filtered = Pose.identity; orientation = Pose.identity; angles = .zero; history = []
    }
    private func receive(_ q: simd_quatf, timestamp: Double) {
        guard q.vector.x.isFinite, q.vector.y.isFinite, q.vector.z.isFinite, q.vector.w.isFinite, simd_length(q.vector) > 0.001 else { return }
        raw = simd_normalize(q)
        if reference == nil { reference = raw }
        let dt = lastTimestamp.map { timestamp - $0 } ?? 0
        if dt > 0 && dt < 1 { rate = rate == 0 ? 1 / dt : rate * 0.9 + (1 / dt) * 0.1 }
        let relative = Pose.relative(raw, to: reference!)
        let alpha = smoothing && dt > 0 ? Float(1 - exp(-dt / 0.035)) : 1
        filtered = simd_slerp(filtered, relative, alpha)
        orientation = Pose.scene(filtered); angles = Pose.degrees(filtered)
        lastTimestamp = timestamp; lastArrival = Date(); hasSample = true
        history.append(angles.x); if history.count > 180 { history.removeFirst(history.count - 180) }
    }
    private func stopResources() {
        generation += 1; wantsLive = false; timer?.invalidate(); timer = nil
        manager.stopDeviceMotionUpdates(); reference = nil; lastTimestamp = nil
        rate = 0; hasSample = false; history = []; filtered = Pose.identity
    }
    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor [weak self] in
            guard let self, self.wantsLive else { return }
            self.mode = .waiting; self.rate = 0; self.hasSample = false; self.reference = nil; self.lastTimestamp = nil
            self.detail = "AirPods 已断开。重新连接后将自动恢复。"
        }
    }
    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {}
}
