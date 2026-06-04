---
module: chat-ai
layer: detail
source_files: [lib/utils/chat_stream_client.dart, lib/pages/feedback/chat_page.dart]
keywords: [SSE, 流式, 重试, 打字动画]
---

# AI 聊天 — 详细设计

## ChatStreamClient (utils/chat_stream_client.dart)
- 构造:`ChatStreamClient({required serverUrl})`(:20)。serverUrl 形如 `http://…/api/app`。
- `AuthExpiredException`(:8):认证失效异常。

### askQuestion → _askQuestionInternal
| 成员 | 行 | 说明 |
|---|---|---|
| `askQuestion(question, token)` | 23 | 对外入口,`yield*` 委托内部实现 |
| `_askQuestionInternal(question, userId, token, retried)` | 36 | 真正逻辑 |
| URL | 42 | `Uri.parse('$serverUrl/structured/convert/stream')` |
| token 为空 | 49 | 先 `refreshAccessToken()`,仍空抛 `AuthExpiredException('Token is empty')`(59) |

### SSE 流解析与状态码
请求头:`Authorization: Bearer <token>`、`Accept: text/event-stream`。
- 非 200:解析 body `{status, message}`:
  - `status==10506 && !retried` → `HttpService().refreshAccessToken()` 成功则递归 `_askQuestionInternal(..., retried=true)`(:80-90、125、195)。
  - `status==10507` → 抛 `AuthExpiredException`(:91/136/206)。
- 200 且 `text/event-stream`:按行读,`data: {json}` → 解析 `content` → `yield content`;`data: [DONE]` 结束。
- `_isAuthError(status)`(:242):10506/10507 判定。
- `_triggerAuthRedirect()`(:270 附近):`NavigationService.showAuthExpiredMessage()` + 跳登录。

## ChatPage (pages/feedback/chat_page.dart)
- `initState`:构造 `ChatStreamClient(serverUrl=...)` 与 `SpeechRecognizer`。
- `sendQuestion()`(:81):
  ```
  取输入 → messages 追加[用户消息 + 空AI消息]
  → slowStream(client.askQuestion(q, HttpService().token))
  ```
- `slowStream(stream)`(:74):每字符 `delay 20ms`,模拟打字。
- `_subscription`(:97):订阅 → `onData` 逐字追加到 `messages.last` → `setState`;`onError` 弹 SnackBar。
- 数据类 `_ChatMessage{text, isUser, timestamp}`;状态 `_isThinking/_isVoiceMode/_voiceActive`。

## 注意 / 扩展点
- `ChatStreamClient` 的 serverUrl 与 `HttpService.baseUrl` 是**两套地址**,接入新 AI 后端时注意区分。
- SSE 手写解析,若后端帧格式变更需改 :152-229 的行解析逻辑。
- `coze.dart` 仅示例,不在主链路。
