---
module: feedback
layer: detail
source_files: [lib/pages/feedback/feedback_form.dart, lib/pages/mine/feedback_edit.dart, lib/pages/feedback/device_select.dart]
keywords: [创建反馈, 编辑, 附件, 两段式上传, 语音]
---

# 反馈 — 详细设计

## 创建反馈 FeedbackForm (feedback_form.dart, 2537 行)
`StatefulWidget`,含 `TickerProviderStateMixin`(动画)。

### 入参
经 `/create-feedback` 路由 `arguments` 传入:`product_id`、`feedback_type`(来自 `device_select.dart`)。

### 核心状态
- `_PendingAttachment`(:31-58):一个待上传/已上传附件的状态机
  - `file`、`attachmentId`(上传后)、`presignedUrl`、`isUploading`、`isRemoved`(补偿删除)。
- `_pendingAttachments: List<_PendingAttachment>`。
- 文本控制器:标题、描述。

### 两段式附件上传
```
1. 选图/拍视频/选文件 → File → _PendingAttachment(isUploading=true) 入列
2. _uploadAttachment(file):
   HttpService.postMultipart('feedback/attachments', {'file': file})  :342
   → data{ attachmentId, presignedUrl, filename, fileType }
   → 回填 attachmentId, isUploading=false
3. 删除已上传附件:DELETE feedback/attachments/{attachmentId}  :380
```
视频先 `video_compress` 压缩再上传。

### 语音转写
`SpeechRecognizer.onResult(text)` → 追加到描述 `TextEditingController`。

### 提交
```
收集 {title, description, attachmentIds[], productId, feedbackType}
→ HttpService.post('feedback', body)  :1226
→ status==200 → 跳 /feedback_list
```

## 编辑反馈 FeedbackEditPage (feedback_edit.dart, 2053 行)
- 加载:`GET feedback/{id}`(:363)→ 回填表单 + 已有网络附件。
- 附件:网络已有(可删)+ 新增本地(`postMultipart` :528)。
- 保存:`PUT feedback/{id}`(:1397)。

## 设备选择 DeviceSelectionPage (device_select.dart)
- 选产品型号(`constants/product_options.dart`)+ 反馈类型 → `Navigator.pushNamed('/create-feedback', arguments:{...})`。

## 注意 / 扩展点
- 附件 ID 与本地文件解耦,删除走补偿(`isRemoved`),提交时只收集有效 `attachmentId`。
- 新增附件类型:扩展 `_uploadAttachment` 与预览组件映射。
- 该文件超大,定位功能时建议按「附件 / 语音 / 提交 / UI 段」分区搜索关键词。
