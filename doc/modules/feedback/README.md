---
module: feedback
layer: module-readme
source_files: [lib/pages/feedback/feedback_form.dart, lib/pages/feedback/device_select.dart, lib/pages/mine/feedback_edit.dart]
backend_apis: [feedback(POST), feedback/{id}(PUT), feedback/{id}(GET), feedback/attachments, feedback/attachments/{id}]
depends_on: [network, speech, chat-ai, widgets, state, i18n]
keywords: [创建反馈, 编辑反馈, 附件上传, 设备选择, 语音转写, 视频压缩]
---

# 反馈 feedback

## 职责
反馈工单的创建与编辑:选设备/反馈类型 → 填标题描述(支持语音转写)→ 上传图片/视频附件(两段式)→ 提交。是 App 最复杂的页面群。

## 文件清单
| 文件:行 | 职责 | 主要接口 |
|---|---|---|
| `pages/feedback/feedback_form.dart` (2537) | **创建反馈**主表单 | `feedback`(POST,:1226)、`feedback/attachments`(:342)、`feedback/attachments/{id}` DELETE(:380) |
| `pages/feedback/device_select.dart` (155) | 选设备 + 反馈类型,跳转传参 | — |
| `pages/mine/feedback_edit.dart` (2053) | **编辑反馈** | `feedback/{id}`(GET :363 / PUT :1397)、附件上传(:528) |

## 对外入口(路由)
`/select-device` → `/create-feedback`(`FeedbackForm`);`/feedback_edit`(`FeedbackEditPage`)。

## 依赖
- 网络:`HttpService.postMultipart/post/put/delete`。
- 语音:`SpeechRecognizer` → 描述框转写。
- 组件:`DeviceIdCard`、`AttachmentPreview`、`NetworkAttachmentPreview`、`WeChatVoiceInput`、`CuteVoiceButton`、`LoadingButton`、`VideoPlay`、`ToastUtils`。
- 媒体:`image_picker`、`file_picker`、`video_compress`。

## 详细设计
见 [detail.md](detail.md)。
