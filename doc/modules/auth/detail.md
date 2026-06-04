---
module: auth
layer: detail
source_files: [lib/pages/login/login_page.dart, lib/pages/login/register_page.dart, lib/pages/login/reset_password.dart, lib/pages/login/change_password.dart, lib/pages/login/destroy_account.dart]
keywords: [登录, 注册, 密码, 验证码, 注销]
---

# 登录鉴权 — 详细设计

## 登录 LoginPage (login_page.dart)
- `_submitLogin()`(:42 起,调用在 :54):
  ```
  HttpService().post('auth/login', {email, password})
   → status==200 → 取 accessToken/refreshToken
   → UserProvider.setAuthTokens(...)
   → HttpService().get('user/info')(:76) → UserProvider.setProfile()
   → Navigator.pushReplacementNamed('/')
  ```
- 失败:`ToastUtils` 提示 `message`。

## 注册 RegisterPage (register_page.dart, 1971 行)
- 流程:填邮箱 → `GET auth/sendCode` 获取验证码 → 校验 → 填密码/资料/国家(`/country-picker`)→ `POST user/register`(:255)。
- 体量最大,含多步表单与校验;细节直接读源码对应区段。

## 重置/找回密码
- `forget_password.dart`:`auth/sendCode`(:75/117/198 多处发码模式)。
- `reset_password.dart`:`auth/sendCode` → `POST auth/resetPwd`(:147)。

## 修改密码 ChangePasswordPage (change_password.dart)
- `POST user/changePwd`(:128),需旧密码 + 新密码,已登录态。

## 注销 AccountDeletionPage (destroy_account.dart)
- 二次确认 + 验证码 → `POST user/destroy`(:167) → 成功后 `UserProvider.clearUser()` 跳登录。

## 国家选择 CountryPickerPage (country_picker.dart)
- 用 `azlistview` + `lpinyin` 做 A-Z 索引;数据源 `data/constants/all_countries.dart`,模型 `data/models/country.dart`。
- 选中后通过 `Navigator.pop(country)` 回传给注册页。

## 注意
- 所有令牌写入统一走 `UserProvider.setAuthTokens`(勿直接 setToken 漏写 refreshToken)。
- 验证码接口 `auth/sendCode` 为 GET,多页面复用。
