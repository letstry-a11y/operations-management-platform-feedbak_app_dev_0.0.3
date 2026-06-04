---
module: widgets
layer: module-readme
source_files: [lib/widgets/]
backend_apis: []
depends_on: [network, i18n]
keywords: [组件, 附件预览, 视频, 下拉, Toast, 加载按钮, 设备卡]
---

# 公共组件 widgets

## 职责
可复用 UI 组件库,供各页面拼装。纯展示/交互为主(语音组件自管录音状态,详见 speech 模块)。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `attachment_preview.dart` (142) | 附件网格预览(图片/视频缩略) |
| `network_attachment_preview.dart` (246) | 网络附件预览增强版(缓存加载、详情用) |
| `video_play.dart` (146) | 视频播放器(`chewie` 包装) |
| `device_id_card.dart` (236) | 设备卡片(展示 + 绑定/解绑按钮) |
| `dropdown_selector.dart` (203) | 通用下拉选择器(产品/反馈类型) |
| `loading_button.dart` (51) | 带 loading 态的提交按钮 |
| `toast_utils.dart` (38) | `ToastUtils` SnackBar 快捷方法(showError/showSuccess) |
| `system_feedback_section.dart` (145) | 系统反馈区块 |
| `audit_card.dart` (68) | 审计记录卡片 |
| `wechat_voice.dart` (200) | 微信风格语音输入 → 见 [speech 模块](../speech/README.md) |
| `cuteVoice_button.dart` (69) | 语音按钮 → 见 [speech 模块](../speech/README.md) |

> ⚠️ `attachment_preview copy.dart` 为冗余副本,非有效组件。

## 使用方
- 反馈/详情页:附件预览、视频、下拉、加载按钮、Toast。
- 设备管理:`DeviceIdCard`。

## 详细设计
见 [detail.md](detail.md)。
