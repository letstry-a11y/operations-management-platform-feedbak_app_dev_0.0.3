---
layer: architecture
keywords: [约定, 路由, 状态码, 规范, 注意点, 安全]
---

# 约定与规范

## 路由表(main.dart:157-182)
| 路由 | 页面 | 说明 |
|---|---|---|
| `/` | `MainPage` | 底部导航(Guide/Home/Profile) |
| `/guide` | `GuidePage` | 引导/首页指南 |
| `/speak` | `IflytekIatDemo` | 语音识别演示页 |
| `/chat` | `ChatPage` | AI 对话 |
| `/select-device` | `DeviceSelectionPage` | 选设备 → 创建反馈 |
| `/create-feedback` | `FeedbackForm` | 创建反馈 |
| `/profile` | `ProfilePage` | 个人中心 |
| `/feedback_list` | `FeedbackListPage` | 反馈列表 |
| `/feedback_detail` | `FeedbackDetail` | 反馈详情 |
| `/feedback_edit` | `FeedbackEditPage` | 编辑反馈 |
| `/device-management` | `DeviceManagementPage` | 设备管理 |
| `/login` | `LoginPage` | 登录 |
| `/user-edit` | `UserEditPage` | 编辑资料 |
| `/forgot-password` | `ForgotPasswordPage` | 忘记密码 |
| `/change-password` | `ChangePasswordPage` | 修改密码 |
| `/destroy-account` | `AccountDeletionPage` | 注销账户 |
| `/register` | `RegisterPage` | 注册 |
| `/country-picker` | `CountryPickerPage` | 国家选择 |

## 后端业务状态码约定
- 响应体形如 `{ "status": <int>, "message": "...", "data": {...} }`。
- `status == 200`:成功。
- `status == 10506`:accessToken 过期 → 触发 `refreshAccessToken()` 重试。
- `status == 10507`:需重新登录 → 清状态跳 `/login`。
- HTTP `401/403` 也触发刷新逻辑。

## 命名/代码约定
- 页面类:`XxxPage`(部分历史命名不一致,如 `FeedbackDetail`、`IflytekIatDemo`、`AccountDeletionPage`)。
- 单例:`HttpService()`、`NavigationService`(全 static)。
- 文案:一律走 `S.of(context).xxx`,勿硬编码;新增文案改 `lib/l10n/intl_zh.arb` + `intl_en.arb` 后重新生成。
- 注意仓库存在 `._*.dart`(macOS AppleDouble 垃圾文件)与 `attachment_preview copy.dart`(冗余副本),非有效源码。

## 安全/运维注意点
1. **明文 HTTP** 后端:`http://210.22.113.78:32899/microport-management/app/`(`http_service.dart:114`)。iOS 已加 ATS 例外。
2. **Token 明文打印**:`http_service.dart:148` `print("_token: Bearer $_token")`,以及多处 `print`,生产需清理。
3. 入口登录态判断被注释,默认直接进主页(`main.dart` 路由表上方注释块)。
4. macOS 运行需补 `com.apple.security.network.client` entitlement 才能联网。

## 文档维护约定
- 改动某模块代码后,同步更新对应 `doc/modules/<x>/README.md` 与必要的 `detail.md`,并核对 `INDEX.md` 的接口/行号。
- 行号会随代码漂移,**以函数名/类名为准**,行号仅作快速定位参考。
