---
layer: architecture
keywords: [总览, 技术栈, 分层, 运行]
---

# 系统总览

## 是什么
**medbot_ai_app** — 面向微创手术机器人(Medbot)设备的**售后/运维反馈 App**。用户登录后选择设备,通过「文字 + 图片/视频 + 语音」提交问题反馈,可借助 AI 流式对话辅助,并管理自己的反馈工单与绑定设备。

- 框架:Flutter(Dart SDK ^3.7.2),跨平台(iOS / Android / Web / macOS / Windows / Linux),主目标 iOS。
- 版本:`1.0.0+14`(`pubspec.yaml`)
- 包名:`com.medbotsurgical.medbotAiApp`

## 技术栈
| 关注点 | 选型 |
|---|---|
| 状态管理 | `provider`(ChangeNotifier) |
| 路由 | `MaterialApp` 命名路由 + 全局 `navigatorKey` |
| 网络 | `http`(自封装单例 `HttpService`) |
| 国际化 | `intl` + `intl_utils`,ARB → 生成 `S` 类(中/英,主语言 zh) |
| 持久化 | `shared_preferences` |
| 音视频 | `flutter_sound`/`record`(录音)、`just_audio`、`video_player`/`chewie`、`video_compress` |
| 文件/媒体 | `image_picker`、`file_picker`、`photo_view`、`cached_network_image` |
| 实时通信 | `web_socket_channel`(语音识别)、SSE(AI 对话,手写解析) |
| 其他 | `permission_handler`、`mobile_scanner`(扫码)、`flutter_markdown`、`flutter_slidable` |

## 分层结构
```
UI 层      pages/ + widgets/        页面与可复用组件
状态层     providers/               UserProvider / LanguageProvider
服务层     utils/                   HttpService / NavigationService / ChatStreamClient / SpeechRecognizer
数据层     data/ + constants/       模型与静态常量
生成层     generated/               国际化产物(勿手改)
```

## 入口与启动
- 入口:`lib/main.dart` → `main()` 设置状态栏样式 → `runApp(MyApp())`。
- `MyApp` 用 `MultiProvider` 注入 `LanguageProvider..loadLanguage()` 与 `UserProvider..loadUserFromPrefs()`。
- `Consumer<LanguageProvider>` 每次 build 同步 `HttpService().setLanguage(...)`。
- `initialRoute: '/'` → `MainPage`。
  - ⚠️ 注:基于登录态选择 `MainPage`/`GuidePage` 的逻辑当前被注释掉(`main.dart` 路由表上方),默认直接进主页。

## 运行方式
```bash
flutter pub get
# iOS 模拟器(本机已装 iOS 26.5 运行时, iPhone 17 Pro 模拟器)
open -a Simulator
flutter run -d <iPhone-simulator-id>
# 其他
flutter run -d macos      # 桌面(需联网权限,见 conventions)
flutter run -d chrome     # 浏览器
```
国际化更新:`flutter pub run intl_utils:generate`

## 关键注意点(详见 03-conventions)
1. 后端为**明文 HTTP**;iOS 已在 `ios/Runner/Info.plist` 加 `NSAppTransportSecurity / NSAllowsArbitraryLoads` 例外。
2. `HttpService._headers` 中有 `print("_token: Bearer …")`,明文打印 token,生产应移除。
3. Token 自动刷新依赖后端业务状态码 `10506`(过期)/`10507`(需重新登录)。
