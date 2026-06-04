---
module: widgets
layer: detail
source_files: [lib/widgets/]
keywords: [组件, 用法]
---

# 公共组件 — 详细设计

按需取用,均为无状态或轻状态组件。常用契约:

| 组件 | 关键入参 | 回调/输出 | 用在 |
|---|---|---|---|
| `AttachmentPreview` | 附件列表(本地/已上传) | 点击预览、删除回调 | feedback_form |
| `NetworkAttachmentPreview` | 网络附件 URL 列表 | 点击大图/播放 | feedback_detail / edit |
| `VideoPlay` | 视频 URL/File | 播放控制(chewie) | 附件视频 |
| `DeviceIdCard` | 设备信息 model | 绑定/解绑回调 | device_management |
| `DropdownSelector` | options(label/value) | onChanged(value) | device_select / 表单 |
| `LoadingButton` | text、isLoading、onPressed | 点击 | 各提交按钮 |
| `ToastUtils` | static showError/showSuccess(context,msg) | — | 全局提示 |
| `SystemFeedbackSection` | 区块数据 | — | 详情/表单区块 |
| `AuditCard` | 审计记录 model | — | 详情 |

## 约定
- 文案走 `S.of(context)`;颜色取主题(主色 `#042A72`)。
- 新增组件放 `widgets/`,无业务网络调用(需网络的逻辑留在页面/服务层)。
- 语音类组件(`wechat_voice`/`cuteVoice_button`)归属 [speech 模块](../speech/detail.md)。
