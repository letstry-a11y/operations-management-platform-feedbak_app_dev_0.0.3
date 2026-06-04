---
module: chat-ai
layer: module-readme
source_files: [lib/utils/chat_stream_client.dart, lib/utils/coze.dart, lib/pages/feedback/chat_page.dart]
backend_apis: ["/structured/convert/stream (SSE)"]
depends_on: [network, speech, i18n]
keywords: [流式对话, SSE, Coze, 打字动画, Token刷新]
---

# AI 聊天 chat-ai

## 职责
AI 流式对话:用户提问 → 服务端 Server-Sent Events 逐字返回 → 打字动画展示。支持语音输入,内置 Token 过期自动刷新重试。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `utils/chat_stream_client.dart` (276) | `ChatStreamClient`:SSE 流解析 + 10506/10507 处理 + 递归重试 |
| `utils/coze.dart` (81) | Coze API 示例(演示 SSE,非主链路) |
| `pages/feedback/chat_page.dart` (408) | 对话 UI、消息列表、语音输入、`slowStream` 打字动画 |

## 对外入口
路由 `/chat`(`ChatPage`);核心类 `ChatStreamClient(serverUrl).askQuestion(question, token)` 返回 `Stream<String>`。

## 依赖
- `HttpService.token` / `refreshAccessToken()`;`NavigationService`(认证失效跳转);`SpeechRecognizer`(语音输入)。

## 详细设计
见 [detail.md](detail.md)。
