# Helix Head

原生 iOS 26 AirPods 头部跟踪应用。使用 `CMHeadphoneMotionManager` 的融合姿态，以四元数驱动程序化 3D 头部。无第三方运行时依赖。

## 使用

1. 在 iPhone 蓝牙设置中连接并戴好 AirPods 4 ANC。
2. 打开应用，点「开始跟踪」，授予运动与健身权限。
3. 面向手机点「归零」，缓慢转头、点头和歪头。
4. 「数据」页查看角度、实测采样率和最近 180 点轨迹；「设置」可关闭平滑。

「体验演示模式」不需要耳机，始终显示 DEMO。进入后台会暂停，回到前台后需主动开始。断连或超过两秒没有样本时显示等待状态；新连接首帧重新归零。跟踪的是相对启动/归零时的旋转，不是位置或绝对航向。

## 构建

需要 macOS、Xcode 26.6、[XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project HelixHead.xcodeproj -scheme HelixHead -sdk iphoneos -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build/device CODE_SIGNING_ALLOWED=NO build
```

打开生成的 `HelixHead.xcodeproj` 可在 Xcode 中选择自己的开发团队并签名到真机。将 `CODE_SIGNING_ALLOWED` 改为 `YES` 后使用自动签名。项目以 `project.yml` 为唯一工程配置来源。

GitHub Actions 对 main 分支编译和运行测试；推送 `v*` 标签还会打包 `Payload/HelixHead.app` 为未签名 IPA，生成 SHA-256 并发布 Release。测试失败不会发布。下载的 IPA 需要自行签名才能安装。

## Xcode 版本说明

原会话指定 Xcode 26.6.2。接手时 [GitHub macOS 26 运行器清单](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md) 列出 macOS 26.6.2 和 Xcode 26.6，未提供 Xcode 26.6.2。因此工作流明确选择 Xcode 26.6，不隐式回退；真实工具链版本随 Release 附件提供。

## 验证范围

- 单元测试：组合姿态归零、坐标轴变换、跨 ±180° 的相对旋转、暂停停止演示更新。
- UI 测试：演示 → 归零 → 数据 → 设置 → 暂停 → 帮助 → 空数据状态，并保存截图到 xcresult。
- 真机验收：运动权限允许/拒绝、AirPods 佩戴与断连重连、左右转头/点头/歪头的物理方向、后台恢复、长时间漂移。这些不由模拟器测试替代。

## 设计和数据

参考 Plasma One 官方截图的浅灰背景、大数字、黑白胶囊操作与深绿主卡片，重新用于头部跟踪。导航、按钮和弹层使用系统原生 iOS 26 材质。模型为代码生成，不包含 Plasma 品牌素材，也无品牌关联。

数据只保留在设备内存，无联网调用、账户、持久化或分析 SDK。首次主动开始时才请求运动权限。3D 姿态属于应用的核心内容，随输入即时更新；没有装饰性的自动背景动画。

API 参考：[Apple 耳机运动管理器](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)、[SwiftUI glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))。
