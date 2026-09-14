# 接手记录

## 需求

AirPods 4 ANC 头部实时映射到 iPhone 上的 3D 头部、Xcode 26.6.2、GitHub Actions 未签名 IPA 与 Release、public 仓库、iOS 26 Liquid Glass、Plasma One 风格。版本差异见 README。

## 第一棒：Grok

会话 `01a09f2f-aa98-7521-b7a3-e01dc532d2b1`。停在 API 和 Plasma One 截图调研阶段，没有产出项目代码，GitHub 中也没有仓库。会话原始记录和截图保留在本机 Grok 目录，未上传到公共仓库。

## 第二棒：Codex

会话 `01a09f43-5cbc-7572-b1f0-b45fc7c77f20`。完成全部应用代码、公开仓库 `ZONGRUICHD/helix-head`、Actions 流水线（macos-26 + Xcode 26.6，未签名 IPA + SHA-256 + 可打开的 Xcode 工程）、图标、单元测试与模拟器 UI 测试。

配额耗尽停在发布收尾：

- 它自己发现正面头像不能沿用相机视角的旋转映射（抬头会变低头），于是在 `5b5d47f` 改成正面镜像映射并加了三项方向测试。
- 它想撤销带 bug 的旧发布运行，但 `gh run cancel` 返回 "Cannot cancel a workflow run that is completed"，**Release v1.0.0 已经用旧映射发出去了**（tag → `9deb7af`）。
- 它随后 dispatch 用 `release_tag=v1.0.0` 重发修复版，但该 tag 已存在，workflow 守卫按设计拒绝（"Manual release requires a new tag"），运行以 failure 结束。所以修复版构建+测试通过但没发布。

## 第三棒：ZCode

- 核对 Apple 官方耳机坐标轴插图，确认 X 右、Y 前、Z 上，`5b5d47f` 的映射几何正确（旧映射确实俯仰、偏航均反向）。
- 版本号从硬编码改为读 bundle，并升到 1.0.1，避免应用内版本与 Release 不一致。
- 推送 tag `v1.0.1` 走 tag 触发路径发布修复版；`v1.0.0` 不删除，在 Release 说明中标注为已知反向问题、由 v1.0.1 取代。

## 仍未完成

真机验收：运动权限允许/拒绝、AirPods 佩戴与断连重连、左右转头/点头/歪头的物理方向、后台恢复、长时间漂移。需要一台 Mac + Xcode 26.6 对 IPA 重新签名并装到 iPhone。模拟器测试不能替代。
