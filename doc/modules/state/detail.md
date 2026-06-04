---
module: state
layer: detail
source_files: [lib/providers/user_provider.dart, lib/providers/language_provider.dart]
keywords: [Provider, 登录态, 语言, 持久化]
---

# 状态管理 — 详细设计

## UserProvider (providers/user_provider.dart)
### 字段
`_token`、`_refreshToken`、`_profile(Map)`,以及散字段 `id/email/username/fullName/role/organization/country/whatsapp`。
- `bool get isLoggedIn => _token != null`。

### 方法
| 方法 | 行 | 作用 |
|---|---|---|
| `token / refreshToken` getter | 19/20 | 读令牌 |
| `updateFromMap(data)` | 25 | 逐字段解析资料 + `notifyListeners` |
| `setToken(token)` | 55 | 存 token → `HttpService().setToken` + prefs |
| `setRefreshToken(token)` | 64 | 存 refreshToken + prefs |
| `setAuthTokens({accessToken, refreshToken})` | 73 | **登录主入口**:双令牌一次写入 + 回灌 HttpService + 持久化 |
| `setProfile(profile)` | 88 | 存资料 + 同步 |
| `setUser(token, profile)` | 96 | token + 资料一并写 |
| `clearUser()` | 107 | **登出**:清空所有 + `HttpService().clearToken` + 清 prefs |
| `loadUserFromPrefs()` | 128 | 启动恢复:读 prefs → 回灌 `HttpService().setToken`(138) |

### 持久化键
`SharedPreferences` 中保存 `token`、`refreshToken`、`user`(JSON 字符串)。

## LanguageProvider (providers/language_provider.dart)
| 成员 | 行 | 作用 |
|---|---|---|
| `_locale` | 5 | 默认 `Locale('en')` |
| `locale` getter | 8 | 当前语言 |
| `loadLanguage()` | 11 | 从 prefs 读语言码 |
| `setLocale(languageCode)` | 18 | 切换 + 持久化 + `notifyListeners` |

驱动链:`setLocale` → 通知 → `main.dart` 的 `Consumer<LanguageProvider>` rebuild → `HttpService().setLanguage()` + `MaterialApp.locale`。

## 扩展点
- 新增持久化用户字段:在 `updateFromMap`/`toMap` 与 prefs 序列化处同步增字段。
- 读登录态:`Provider.of<UserProvider>(context).isLoggedIn`。
