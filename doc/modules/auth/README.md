---
module: auth
layer: module-readme
source_files: [lib/pages/login/login_page.dart, lib/pages/login/register_page.dart, lib/pages/login/forget_password.dart, lib/pages/login/reset_password.dart, lib/pages/login/change_password.dart, lib/pages/login/destroy_account.dart, lib/pages/login/country_picker.dart]
backend_apis: [auth/login, auth/refresh, auth/sendCode, auth/resetPwd, user/register, user/changePwd, user/destroy]
depends_on: [network, state, i18n, data]
keywords: [登录, 注册, 找回密码, 重置, 修改密码, 注销, 验证码, 国家选择]
---

# 登录鉴权 auth

## 职责
账户全生命周期:登录、注册、找回/重置/修改密码、注销账户,以及注册时的国家选择。

## 文件清单
| 文件:行 | 职责 | 主要接口 |
|---|---|---|
| `login_page.dart` (459) | 登录表单 → 存令牌 → 进主页 | `auth/login`、`user/info` |
| `register_page.dart` (1971) | 注册(邮箱验证码、密码、资料、国家) | `auth/sendCode`、`user/register` |
| `forget_password.dart` (214) | 忘记密码,发验证码 | `auth/sendCode` |
| `reset_password.dart` (356) | 通过验证码重置密码 | `auth/sendCode`、`auth/resetPwd` |
| `change_password.dart` (365) | 已登录改密码 | `user/changePwd` |
| `destroy_account.dart` (449) | 注销账户(二次确认) | `auth/sendCode`、`user/destroy` |
| `country_picker.dart` (313) | 国家/区号选择(azlistview) | — (用 `data/constants/all_countries.dart`) |

## 对外入口(路由)
`/login`、`/register`、`/forgot-password`、`/change-password`、`/destroy-account`、`/country-picker`。

## 依赖
- `HttpService`(请求)、`UserProvider.setAuthTokens/clearUser`、`S`(文案)、国家数据。

## 详细设计
见 [detail.md](detail.md)。
