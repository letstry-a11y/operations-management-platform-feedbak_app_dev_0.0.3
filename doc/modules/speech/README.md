---
module: speech
layer: module-readme
source_files: [lib/utils/speech_recognizer.dart, lib/widgets/wechat_voice.dart, lib/widgets/cuteVoice_button.dart, lib/pages/feedback/speak_page.dart]
backend_apis: ["WebSocket: {baseUri.path}ws/speech"]
depends_on: [network]
keywords: [录音, PCM, 分帧, WAV, WebSocket, 实时转写, 麦克风]
---

# 语音识别 speech

## 职责
WebSocket 实时语音识别:采集 PCM → 分帧上行 → 接收中间/最终识别文本;同时本地落盘 WAV。供反馈描述、AI 聊天的语音输入复用。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `utils/speech_recognizer.dart` (540) | `SpeechRecognizer`:录音 + WebSocket + PCM/WAV |
| `widgets/wechat_voice.dart` (200) | 微信风格录音输入组件(时长/播放) |
| `widgets/cuteVoice_button.dart` (69) | 语音按钮(激活/非激活样式) |
| `pages/feedback/speak_page.dart` (243) | 独立语音识别演示页(路由 `/speak`,类 `IflytekIatDemo`) |

## 对外入口
`SpeechRecognizer(appId, ...)` + 回调 `onResult/onStart/onStop/onError/onAudioSaved`;`startRecognition()` / `stopRecognition()`。

## 依赖
- `HttpService.baseUrl`(推导 WS 地址)、`token`、`languageCode`;`flutter_sound`(录音)、`just_audio`(回放)、`permission_handler`(麦克风)。

## 详细设计
见 [detail.md](detail.md)。
