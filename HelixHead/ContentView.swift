import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var motion: MotionStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab = 0
    @State private var showHelp = false
    private var backdrop: Color { Color(uiColor: .systemGroupedBackground) }
    var body: some View {
        TabView(selection: $tab) {
            Tab("跟踪", systemImage: "viewfinder", value: 0) { tracking }
            Tab("数据", systemImage: "waveform.path", value: 1) { telemetry }
            Tab("设置", systemImage: "slider.horizontal.3", value: 2) { settings }
        }
        .tint(colorScheme == .dark ? .white : .black)
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Image(systemName: "airpods").font(.system(size: 48))
                        Text("让你的动作，\n自然发生。").font(.largeTitle.bold())
                        Text("1. 戴好 AirPods 4 ANC，并通过系统蓝牙设置连接 iPhone。\n\n2. 轻点开始跟踪，允许访问运动与健身。\n\n3. 面向屏幕，轻点归零，再缓慢左右转头、点头或歪头。")
                        Text("没有耳机也可以体验演示。演示数据会明确标注，不会当作真实传感器数据。耳机只提供旋转姿态，不能测量头部在空间中的位置。").foregroundStyle(.secondary)
                    }.padding(24)
                }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showHelp = false } } }
            }.presentationDetents([.large])
        }
    }

    private var tracking: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("你的头部姿态").foregroundStyle(.secondary)
                        Text(motion.canRecenter ? String(format: "%+.1f°", motion.angles.x) : "—°")
                            .font(.system(size: 60, weight: .medium, design: .rounded)).monospacedDigit()
                            .minimumScaleFactor(0.5).lineLimit(1).accessibilityIdentifier("yawValue")
                        Label(motion.mode.rawValue, systemImage: motion.mode == .demo ? "play.circle" : "airpods")
                            .font(.subheadline).padding(.horizontal, 14).padding(.vertical, 8)
                            .background(.quaternary, in: Capsule()).accessibilityIdentifier("trackingStatus")
                    }.padding(.top, 12)
                    HStack(spacing: 12) {
                        Button { motion.running ? motion.pause() : motion.start() } label: {
                            Label(motion.running ? "暂停" : "开始跟踪", systemImage: motion.running ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity).frame(minHeight: 44)
                        }.buttonStyle(.glassProminent).tint(.black).accessibilityIdentifier("trackingToggle")
                        Button { motion.recenter() } label: {
                            Label("归零", systemImage: "scope").frame(maxWidth: .infinity).frame(minHeight: 44)
                        }.buttonStyle(.glass).disabled(!motion.canRecenter).accessibilityIdentifier("recenter")
                    }
                    VStack(spacing: 0) {
                        HStack {
                            Label("HELIX / ONE", systemImage: "circle.dotted").font(.caption.weight(.semibold)).tracking(2)
                            Spacer()
                            Text(motion.mode == .demo ? "DEMO" : motion.mode == .live ? "LIVE" : "STANDBY")
                                .font(.caption2.monospaced()).accessibilityIdentifier("sourceBadge")
                        }.padding(22)
                        HeadScene(orientation: motion.orientation).frame(height: 270)
                        HStack {
                            Circle().fill(motion.mode == .live ? .green : .white.opacity(0.5)).frame(width: 7, height: 7)
                            Text(motion.mode == .demo ? "模拟动作" : "AirPods 头部跟踪")
                            Spacer()
                            Image(systemName: "rotate.3d")
                        }.font(.caption).padding(22)
                    }
                    .foregroundStyle(.white)
                    .background(LinearGradient(colors: [Color(red: 0.24, green: 0.31, blue: 0.27), Color(red: 0.045, green: 0.075, blue: 0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
                    .accessibilityElement(children: .contain)
                    axes
                    Text(motion.detail).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    if !motion.running {
                        Button("体验演示模式") { motion.demo() }.frame(minHeight: 44).accessibilityIdentifier("startDemo")
                    }
                }.padding(.horizontal, 22).padding(.bottom, 28).frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
            }.background(backdrop)
                .navigationTitle("Helix Head").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showHelp = true } label: { Image(systemName: "questionmark") }.accessibilityLabel("使用帮助") } }
        }
    }
    private var axes: some View {
        HStack(spacing: 0) {
            axis("左右转头", value: motion.angles.x)
            Divider().frame(height: 34)
            axis("上下点头", value: motion.angles.y)
            Divider().frame(height: 34)
            axis("左右歪头", value: motion.angles.z)
        }.padding(.vertical, 20).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
    private func axis(_ label: String, value: Double) -> some View {
        VStack(spacing: 7) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%+.1f°", value)).font(.title3.weight(.medium)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
        }.frame(maxWidth: .infinity)
    }
    private var telemetry: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("每一个细微动作。").font(.largeTitle.weight(.medium))
                    Text(motion.mode == .demo ? "演示数据 · 非传感器读数" : motion.mode.rawValue).foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%.0f", motion.rate)).font(.system(size: 64, weight: .medium)).monospacedDigit()
                        Text("Hz 实测更新率").foregroundStyle(.secondary)
                    }
                    axes
                    VStack(alignment: .leading, spacing: 20) {
                        Text("转头轨迹").font(.headline)
                        if motion.history.isEmpty {
                            ContentUnavailableView("等待运动数据", systemImage: "waveform.path", description: Text("在跟踪页开始，或体验演示模式。"))
                        } else {
                            Canvas { context, size in
                                var path = Path()
                                for (i, value) in motion.history.enumerated() {
                                    let point = CGPoint(x: CGFloat(i) / CGFloat(max(1, motion.history.count - 1)) * size.width,
                                                        y: size.height / 2 - CGFloat(value / 180) * size.height / 2)
                                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                                }
                                context.stroke(path, with: .color(.primary), lineWidth: 2)
                            }.frame(height: 160).accessibilityLabel("最近 180 个采样点的转头角度曲线")
                        }
                        Text("仅显示当前会话最近 180 个采样点。暂停后清空，不保存或上传。").font(.footnote).foregroundStyle(.secondary)
                    }.padding(22).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
                }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }.background(backdrop).navigationTitle("运动数据")
        }
    }
    private var settings: some View {
        NavigationStack {
            Form {
                Section("跟踪体验") {
                    Toggle("平滑细微抖动", isOn: $motion.smoothing)
                    Text("使用四元数插值，避免旋转跨越 ±180° 时跳变。关闭后直接显示每次采样。").font(.footnote).foregroundStyle(.secondary)
                }
                Section("连接与权限") {
                    Button("连接使用指南") { showHelp = true }
                    Button("打开系统设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    Text("需要支持头部运动的 AirPods。传感器更新率由系统与耳机决定；切入后台会自动暂停。").font(.footnote).foregroundStyle(.secondary)
                }
                Section("关于") {
                    LabeledContent("Helix Head", value: "1.0.0")
                    Text("所有运动数据仅在设备内处理。没有账户、广告或网络上传。\n\n界面参考 Plasma One 的留白、胶囊操作和深绿卡片，使用 iOS 26 原生 Liquid Glass 控件。本项目与 Plasma 无关联。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("设置")
        }
    }
}
