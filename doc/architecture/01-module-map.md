---
layer: architecture
keywords: [模块, 依赖, 关系图]
---

# 模块划分与依赖关系

## 11 个模块
| 模块 | 目录/文件 | 一句话职责 |
|---|---|---|
| auth 登录鉴权 | `pages/login/` | 登录、注册、找回/重置/修改密码、注销、国家选择 |
| feedback 反馈 | `pages/feedback/feedback_form.dart`、`device_select.dart`、`pages/mine/feedback_edit.dart` | 创建/编辑反馈,附件上传与语音转写 |
| mine 我的/工单 | `pages/mine/` | 反馈列表/详情/评价、设备管理(扫码)、用户编辑 |
| home-guide 首页 | `pages/main_page.dart`、`guide_page.dart`、`home_page.dart`、`profile_page.dart` | 底部导航、首页卡片、引导、个人中心 |
| chat-ai AI 聊天 | `utils/chat_stream_client.dart`、`coze.dart`、`pages/feedback/chat_page.dart` | SSE 流式 AI 对话 |
| speech 语音 | `utils/speech_recognizer.dart`、`widgets/wechat_voice.dart`、`cuteVoice_button.dart`、`pages/feedback/speak_page.dart` | WebSocket 实时语音识别 |
| network 网络层 | `utils/http_service.dart`、`navigation_service.dart`、`device_binding_repository.dart`、`status_utils.dart` | 统一 HTTP 出口、Token 重试、全局导航 |
| state 状态管理 | `providers/` | 登录态、语言、持久化 |
| widgets 公共组件 | `widgets/` | 附件预览、视频、下拉、Toast 等 |
| i18n 国际化 | `l10n/`、`generated/`、`providers/language_provider.dart` | 中/英文案 |
| data 数据常量 | `data/`、`constants/`、`utils/contant.dart` | 国家/产品/模型 |

## 依赖关系图
```
                         main.dart (路由表 + MultiProvider)
                          │
        ┌─────────────────┼──────────────────┐
        ▼                 ▼                  ▼
  LanguageProvider    UserProvider       NavigationService
        │                 │                  ▲
        │ setLanguage      │ setToken/clear   │ toLoginAndClear
        ▼                 ▼                  │
   ┌──────────────────────────────────────── │ ─────────┐
   │                HttpService(单例)  ◄──────┘          │
   │   get/post/put/delete/postMultipart + _sendWithRetry │
   └───▲──────────▲───────────▲──────────▲───────────────┘
       │          │           │          │
   auth页面   feedback页面  mine页面   chat/speech
                  │                      │
                  ├─ widgets(附件/语音/视频/下拉…)
                  └─ ChatStreamClient / SpeechRecognizer
                         │ token/baseUrl/languageCode
                         └─→ HttpService(读属性)
```

## 依赖规则
- **所有网络请求只经 `HttpService`**(单例),页面不直接用 `http`。
- `ChatStreamClient` 与 `SpeechRecognizer` 不走 `HttpService` 的方法,但**读取其属性**:`token`、`refreshAccessToken()`、`baseUrl`、`languageCode`。
- 认证失效统一经 `NavigationService.toLoginAndClear()` 跳登录。
- UI 通过 `Provider.of/Consumer` 读 `UserProvider`/`LanguageProvider`。
- `widgets/` 为纯展示/交互组件,不持有业务状态(语音组件除外,自管录音状态)。
