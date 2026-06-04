---
module: mine
layer: module-readme
source_files: [lib/pages/mine/feedback_list.dart, lib/pages/mine/feedback_detail.dart, lib/pages/mine/device_management_page.dart, lib/pages/mine/user_edit.dart]
backend_apis: [feedback/page, feedback/{id}, feedback/{id}/read, feedback/{id}/evaluate, feedback/unread-count, device/list, device/bind, device/unbind/{id}, user/update]
depends_on: [network, state, widgets, i18n]
keywords: [反馈列表, 详情, 评价, 设备管理, 扫码绑定, 用户编辑]
---

# 我的/工单 mine

## 职责
"我的"下的工单与资料管理:反馈列表(分页/未读)、反馈详情与评价、设备管理(扫码绑定/解绑)、用户信息编辑。

## 文件清单
| 文件:行 | 职责 | 主要接口 |
|---|---|---|
| `feedback_list.dart` (956) | 反馈分页列表、未读数、筛选、标记已读 | `feedback/page`(:215)、`feedback/unread-count`(:102)、`feedback/{id}/read` |
| `feedback_detail.dart` (805) | 反馈详情、附件预览、评价 | `feedback/{id}`(:81)、`feedback/{id}/read`(:141)、`feedback/{id}/evaluate`(:491) |
| `device_management_page.dart` (1187) | 设备列表、扫码绑定、解绑 | `device/list`(:146)、`device/bind`(:259)、`device/unbind/{id}`(:288) |
| `user_edit.dart` (491) | 编辑用户资料 | `user/update`(:206) |

## 对外入口(路由)
`/feedback_list`、`/feedback_detail`、`/device-management`、`/user-edit`。

## 依赖
- `HttpService`、`UserProvider`、`StatusUtils`(状态色)、`mobile_scanner`(扫码)、`DeviceBindingRepository`、附件/视频组件、`flutter_slidable`(列表滑动)。

## 详细设计
见 [detail.md](detail.md)。
