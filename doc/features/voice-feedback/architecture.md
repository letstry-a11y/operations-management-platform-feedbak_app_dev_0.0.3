---
feature: voice-feedback
doc_type: architecture
status: approved
related: [SRS.md, dev-plan.md]
source_files: [lib/pages/feedback/voice_input_page.dart, lib/pages/feedback/feedback_form.dart, lib/utils/speech_recognizer.dart, lib/utils/chat_stream_client.dart, lib/main.dart]
keywords: [架构, 导航流, 时序, 数据契约, 复用]
---

# 软件架构设计 — 语音反馈双页功能

## 1. 总体
沿用项目现有分层(UI / 状态 / 服务 / 数据)。本期仅**新增一个页面 + 改造一处表单**,服务层全部复用,无新增网络封装。

## 2. 页面与导航流
```
入口(home_page / device_select)
   → /voice-feedback  [VoiceInputPage 第一页]
        语音 → ASR(讯飞) → LLM 整理 → 结构化 JSON
   → /create-feedback [FeedbackForm 第二页, AI 预填]
        ├─ 设备ID 扫码补充(保留现有)
        ├─「继续补充」→ pop 回 VoiceInputPage(补充模式)→ 回传合并 JSON
        └─ 提交 POST feedback(不变)
```

## 3. 组件与职责
| 组件 | 类型 | 职责 | 复用/新增 |
|---|---|---|---|
| `VoiceInputPage` | 新页面 `lib/pages/feedback/voice_input_page.dart` | 录音交互、实时文本、调用 ASR+LLM、产出 JSON、跳转/回传 | 新增 |
| `SpeechRecognizer` | 服务 `utils/speech_recognizer.dart` | 语音 → 文本(ws/speech) | 复用 |
| `ChatStreamClient` | 服务 `utils/chat_stream_client.dart:23` | 文本 → 结构化(SSE) | 复用 |
| `FeedbackForm` | 改造 `pages/feedback/feedback_form.dart` | 接收 AI 预填 + 继续补充入口 | 改造 |
| `CuteVoiceButton`/`WeChatVoiceInput` | 组件 | 大按钮视觉参考 | 复用/参考 |
| i18n `S` | 生成 | 新文案 | 扩充 |

## 4. 关键时序
**主流程**
```
用户长按/点击 → SpeechRecognizer.start → onResult 累积 _transcript(实时显示)
结束 → _analyzeAndGo()
        → ChatStreamClient.askQuestion(_transcript) 累积 SSE 全文
        → 清洗 + jsonDecode → Map(title/description/occurTime/…)
        → Navigator.pushReplacementNamed('/create-feedback',
             arguments:{product_id, feedback_type, ai_fields:Map, raw_transcript})
FeedbackForm.didChangeDependencies → 用 ai_fields 预填控制器
```
**继续补充(AI 合并)**
```
第二页「继续补充」→ Navigator.pushNamed('/voice-feedback',
    arguments:{from_supplement:true, existing_content:{title,description}, 透传参数})
VoiceInputPage 录新语音 → content = existing_content + "\n补充:" + 新transcript
    → askQuestion(content) → 合并去重后的完整 JSON
    → Navigator.pop(mergedMap)
第二页 await 接收 → 覆盖/合并填入控制器 → setState
```

## 5. 数据契约
- **AI 输入**:`{ "content": <文本> }`(现接口,不变)。
- **AI 输出(假设,待 Step 0 实测)**:结构化 JSON,如 `{title, description, occurTime?, deviceType?}`;若被 ```json 包裹先剥离再 `jsonDecode`。
- **提交载荷(不变)**:title / feedbackType / deviceType / deviceUdi / description / occurTime / attachmentIds / titleAudio / descriptionAudio(见 `feedback_form.dart` 的 `_submit`)。

## 6. 接口复用清单(零改动)
`/structured/convert/stream`(整理)、`ws/speech`(识别)、`POST feedback`(提交)、`feedback/attachments`(附件)。

## 7. 设计决策与权衡
- 继续补充用 **pop 回传**而非重建第二页 → 保留第二页已填状态(设备ID/附件)。
- 合并交给 **AI 语义去重**(既有内容 + 新语音一起送)→ 智能但会覆盖手动编辑(已确认接受)。
- ASR 沿用讯飞 → 改动最小、符合"不改接口";成本维持现状。

## 8. 错误处理与回退
- ASR 错误 → SnackBar 提示,可重录。
- AI 非 JSON / 超时 → 全文回退填 description,Toast 告知"已按原文填入"。
- 鉴权失效 → 复用 `ChatStreamClient` 既有 10506/10507 → 跳登录逻辑。
