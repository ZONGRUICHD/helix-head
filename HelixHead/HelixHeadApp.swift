import SwiftUI

@main struct HelixHeadApp: App {
    @StateObject private var motion = MotionStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(motion)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background && motion.running { motion.pause() }
                }
        }
    }
}
