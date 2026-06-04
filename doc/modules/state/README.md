---
module: state
layer: module-readme
source_files: [lib/providers/user_provider.dart, lib/providers/language_provider.dart]
backend_apis: [user/info]
depends_on: [network]
keywords: [Provider, 登录态, 语言, 持久化, SharedPreferences]
---

# 状态管理 state

## 职责
全局应用状态(`ChangeNotifier` + `provider`):用户登录态/令牌/资料、语言设置,均持久化到 `SharedPreferences`,并与 `HttpService` 同步。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `providers/user_provider.dart` (155) | `UserProvider`:token/refreshToken/profile + 登录态 `isLoggedIn` |
| `providers/language_provider.dart` (36) | `LanguageProvider`:`Locale`(en/zh)切换与持久化 |

## 对外入口
- 在 `main.dart` 的 `MultiProvider` 注入;启动时 `..loadUserFromPrefs()` / `..loadLanguage()`。
- UI:`Provider.of<UserProvider>(context)` / `Consumer<LanguageProvider>`。

## 依赖
- 写令牌时回灌 `HttpService().setToken/setRefreshToken/clearToken`。
- `LanguageProvider` 变更同步 `HttpService().setLanguage()` 并驱动 `MaterialApp.locale`。

## 详细设计
见 [detail.md](detail.md)。
