---
module: feedback
layer: module-readme
source_files: [lib/pages/feedback/voice_input_page.dart, lib/pages/feedback/feedback_form.dart, lib/pages/feedback/device_select.dart, lib/pages/mine/feedback_edit.dart]
backend_apis: [feedback(POST), feedback/{id}(PUT), feedback/{id}(GET), feedback/attachments, feedback/attachments/{id}]
depends_on: [network, speech, chat-ai, widgets, state, i18n]
keywords: [创建反馈, 编辑反馈, 附件上传, 设备选择, 语音转写, 视频压缩]
---

# 反馈 feedback

## 职责
反馈工单的创建与编辑:选设备/反馈类型 → 第一页语音输入(可跳过,直接进文字输入)→ 填标题描述 → 上传图片/视频附件(两段式)→ 提交。是 App 最复杂的页面群。

## 文件清单
| 文件:行 | 职责 | 主要接口 |
|---|---|---|
| `pages/feedback/voice_input_page.dart` (461) | **第一页语音输入**(讯飞识别 + Kimi 整理;「跳过,直接文字输入」按钮;50s 自动停止,最后 10s 红色倒计时——讯飞 IAT 单次 60s 上限;多次语音按「1./2.…」序号追加到描述,标题为全部内容总结) | WS `ws/speech`、Kimi |
| `pages/feedback/feedback_form.dart` (1923) | **创建反馈**主表单(纯文字输入,无语音控件) | `feedback`(POST,:844)、`feedback/attachments`(:197)、`feedback/attachments/{id}` DELETE(:234) |
| `pages/feedback/device_select.dart` (155) | 选设备 + 反馈类型,跳转传参 | — |
| `pages/mine/feedback_edit.dart` (2053) | **编辑反馈**(仍保留语音转写) | `feedback/{id}`(GET :363 / PUT :1397)、附件上传(:528) |

## 对外入口(路由)
`/select-device` → `/voice-feedback`(`VoiceInputPage`)→ `/create-feedback`(`FeedbackForm`);`/feedback_edit`(`FeedbackEditPage`)。

## 依赖
- 网络:`HttpService.postMultipart/post/put/delete`。
- 语音:`SpeechRecognizer` → 仅 `voice_input_page.dart`(第一页)与 `feedback_edit.dart`(编辑页);创建表单 `feedback_form.dart` 已移除标题/描述的语音输入。
- 组件:`DeviceIdCard`、`AttachmentPreview`、`NetworkAttachmentPreview`、`LoadingButton`、`VideoPlay`、`ToastUtils`。
- 媒体:`image_picker`、`file_picker`、`video_compress`。

## 详细设计
见 [detail.md](detail.md)。
