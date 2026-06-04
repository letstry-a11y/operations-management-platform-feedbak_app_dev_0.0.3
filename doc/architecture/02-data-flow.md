---
layer: architecture
keywords: [数据流, token, 刷新, 登录, 导航, SSE, WebSocket]
---

# 核心数据流

## 1. 登录 → Token 落地
```
LoginPage._submitLogin()              login_page.dart:54
  → HttpService().post('auth/login', {email, password})
  → 解析 accessToken / refreshToken
  → UserProvider.setAuthTokens(accessToken, refreshToken)   user_provider.dart:73
       ├─ HttpService().setToken(accessToken)
       ├─ HttpService().setRefreshToken(refreshToken)
       └─ SharedPreferences 保存
  → HttpService().get('user/info') → UserProvider.setProfile()
  → Navigator 跳 MainPage
```
应用重启恢复:`UserProvider.loadUserFromPrefs()`(`user_provider.dart:128`)从 prefs 读回 token 并回灌 `HttpService().setToken()`。

## 2. 请求 + Token 自动刷新重试(网络层核心)
所有 `get/post/put/delete` 都过 `HttpService._sendWithRetry()`(`http_service.dart:351`):
```
发起请求
 → 响应 401/403  或  body.status == 10506(Token过期)
     → _refreshAccessToken()  http_service.dart:441
         → POST auth/refresh {refreshToken}
         → 成功: 更新 _token/_refreshToken + 持久化 → 用新 token 重试原请求
         → 失败: _handleAuthError() → 跳登录
 → body.status == 10507(需重新登录)
     → _handleAuthError() → NavigationService.toLoginAndClear()
 → 正常: 返回 Response
```
- `_refreshing`(`Future<bool>?`)做**并发去重**,多请求同时 401 只刷新一次。
- 语言头:每个请求带 `X-Language: <languageCode>`。

## 3. AI 流式对话(SSE,不走 _sendWithRetry)
```
ChatPage.sendQuestion()
 → ChatStreamClient.askQuestion(question, token)     chat_stream_client.dart:23
   → POST {serverUrl}/structured/convert/stream
     Header: Authorization: Bearer <HttpService().token>, Accept: text/event-stream
   → 逐行解析 "data: {json}" → yield content
   → 遇 status 10506 且未重试: HttpService().refreshAccessToken() → 递归重试
   → 遇 status 10507: 抛 AuthExpiredException → _triggerAuthRedirect → 跳登录
 → ChatPage.slowStream() 每字符 delay 20ms(打字动画)→ setState 追加
```
注意:`ChatStreamClient` 自带一套与 `HttpService` 平行的 10506/10507 处理。

## 4. 语音识别(WebSocket)
```
SpeechRecognizer.startRecognition()                  speech_recognizer.dart
 → 连接 ws://<baseHost>/<basePath>ws/speech
     Header: Authorization: Bearer <HttpService().token>, X-Language
 → 发握手 {"type":"start", header:{app_id}}
 → FlutterSoundRecorder 采集 PCM(16k/16bit/mono)→ 按 frameSize(1280B) 分帧 sink.add
 → 下行 {"type":"intermediate"/"final"/"error", content} → onResult/onError
 → stopRecognition(): 发 {"type":"end"} → 关闭 → PCM 转 WAV → onAudioSaved
```
回调结果回填:`onResult(text)` → 反馈描述框 / 聊天输入框。

## 5. 反馈附件两段式提交
```
选文件/录视频 → _PendingAttachment(本地)
 → HttpService.postMultipart('feedback/attachments', file)  → 返回 attachmentId
 → 提交时收集所有 attachmentId
 → HttpService.post('feedback', {title, description, attachmentIds, productId, feedbackType})
```

## 6. 全局状态与导航
- `LanguageProvider.setLocale()` → 通知 → `MaterialApp.locale` 切换 + 同步 `HttpService.setLanguage`。
- `NavigationService.navigatorKey` 让服务层(拦截器/流客户端)能在无 `context` 时导航/弹 SnackBar。
