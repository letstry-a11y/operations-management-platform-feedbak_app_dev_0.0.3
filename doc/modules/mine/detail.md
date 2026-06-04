---
module: mine
layer: detail
source_files: [lib/pages/mine/feedback_list.dart, lib/pages/mine/feedback_detail.dart, lib/pages/mine/device_management_page.dart, lib/pages/mine/user_edit.dart]
keywords: [列表分页, 评价, 扫码绑定, 状态映射]
---

# 我的/工单 — 详细设计

## 反馈列表 FeedbackListPage (feedback_list.dart)
- 拉取:`POST feedback/page`(:215),分页参数(page/size/筛选条件)。
- 未读数:`GET feedback/unread-count`(:102)。
- 标记已读:`PUT feedback/{id}/read`。
- 状态展示:`StatusUtils`(`utils/status_utils.dart`)→ 文本+颜色。
- 交互:`pull_to_refresh` 下拉刷新 + 上拉加载;`flutter_slidable` 滑动操作。
- 点击 → `/feedback_detail`(传 id)。

## 反馈详情 FeedbackDetail (feedback_detail.dart)
- 加载:`GET feedback/{id}`(:81);进入即 `PUT feedback/{id}/read`(:141)。
- 附件预览:`NetworkAttachmentPreview` / `VideoPlay`。
- 评价:`POST feedback/{id}/evaluate`(:491)(评分/评论)。
- 可跳 `/feedback_edit` 编辑。

## 设备管理 DeviceManagementPage (device_management_page.dart, 1187 行)
- 列表:`POST device/list`(:146)。
- 绑定:`mobile_scanner` 扫码得设备码 → `POST device/bind`(:259);本地缓存 `DeviceBindingRepository`。
- 解绑:`DELETE device/unbind/{id}`(:288)。
- 组件:`DeviceIdCard`(`widgets/device_id_card.dart`)。

## 用户编辑 UserEditPage (user_edit.dart)
- 加载当前 `UserProvider` 资料 → 编辑 → `POST user/update`(:206)→ 成功后 `UserProvider.setProfile/updateFromMap` 同步。

## 注意
- 列表与详情共享状态码/已读语义;评价仅在工单完结态可用(以后端返回字段为准)。
- 扫码需相机权限(`Info.plist` 已声明)。
