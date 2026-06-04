---
module: speech
layer: detail
source_files: [lib/utils/speech_recognizer.dart, lib/widgets/wechat_voice.dart, lib/widgets/cuteVoice_button.dart]
keywords: [PCM, 分帧, WAV, WebSocket]
---

# 语音识别 — 详细设计

## SpeechRecognizer (utils/speech_recognizer.dart, 540 行)
### 构造参数
`appId`(如 `'397dfc06'`)、`apiKey`/`apiSecret`(WS 模式保留未用)、`frameSize=1280`(40ms 音频字节数)。

### 回调
`onResult(String)`、`onStart()`、`onStop()`、`onError(String)`、`onAudioSaved(path, duration)`。

### 内部组件
`FlutterSoundRecorder _recorder`(PCM 16kHz/16bit/mono)、`StreamController<Uint8List>`、`WebSocketChannel _channel`、`IOSink _fileSink`(PCM 落盘)、PCM→WAV 转换。

### 流程
| 阶段 | 说明 |
|---|---|
| `init()` | 申请麦克风权限 + 初始化录音器 + 建本地 PCM 文件 |
| `startRecognition()` | 连 WS → 发握手 → 等 ready → 启动录音流 |
| WS 地址 | `'${baseUri.path}ws/speech'`(:466-467,由 `HttpService().baseUrl` 推导) |
| WS 头 | `Authorization: Bearer <token>`、`X-Language` |
| 握手 | `{"type":"start","header":{"app_id":appId}, ...}` |
| 上行 | `_onRecordingData`:累积到 `frameSize` → `_channel.sink.add(frame)`,同时写 `_fileSink` |
| 下行 | `{"type":"intermediate"\|"final"\|"error","content":...}` → `onResult/onError` |
| `stopRecognition()` | 发 `{"type":"end"}` → 关 WS/录音/sink → PCM 转 WAV → `onAudioSaved` |

## 关联组件
- `WeChatVoiceInput`(wechat_voice.dart):自管录制状态,显示时长,`just_audio` 回放,回调 `onRecordingStateChanged`/`onVoiceRecorded`。
- `CuteVoiceButton`(cuteVoice_button.dart):`isActive` → 粉色「正在聆听」/ 青绿「点击说话」,`onTap` 回调。

## 使用方
- `ChatPage`:`onResult`→输入框,`onStop`→`sendQuestion()`。
- `FeedbackForm`:`onResult`→描述框追加。
- `speak_page.dart`(`IflytekIatDemo`):独立演示,实时显示 `recognizedText`。

## 注意
- WS 地址依赖 `baseUrl` 结构(http→ws 同主机/路径),改后端时一并核对 :466。
- 需麦克风权限(`NSMicrophoneUsageDescription` 已声明)。
