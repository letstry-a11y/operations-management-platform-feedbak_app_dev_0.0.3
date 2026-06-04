---
module: network
layer: detail
source_files: [lib/utils/http_service.dart, lib/utils/navigation_service.dart]
keywords: [HTTP, Token刷新, 重试, Multipart]
---

# 网络层 — 详细设计

## HttpService (utils/http_service.dart)
单例:`static final _instance`,`factory HttpService()`。

### 字段
| 字段 | 行 | 说明 |
|---|---|---|
| `_baseUrl` | 114 | `http://210.22.113.78:32899/microport-management/app/`,只读 `baseUrl` getter(115) |
| `_token` / `_refreshToken` | 117/118 | 当前令牌 |
| `_refreshing` (`Future<bool>?`) | 119 | 刷新去重,防并发重复刷新 |
| `_languageCode` | 120 | 默认 `'en'`,请求头 `X-Language` |

### 关键方法
| 方法 | 行 | 作用 |
|---|---|---|
| `setToken/setRefreshToken/clearToken` | 125/129/134 | 令牌读写 |
| `setLanguage / languageCode` | 140/145 | 语言头 |
| `_headers({extra})` | 147 | 组装请求头(含 Bearer + X-Language)。⚠️ 148 行 `print` 明文 token |
| `get/post/put/delete` | 159/173/187/199 | 基础请求,均经 `_sendWithRetry` |
| `postMultipart(endpoint, fields, files)` | 215 | 文件上传(附件) |
| `_sendWithRetry(requestFn)` | 351 | **核心**:发请求 → 判断 401/403/10506 → 刷新重试;10507 → 跳登录 |
| `_handleResponseForRetry(resp)` | 376 | 解析响应,决定是否需刷新 |
| `_getErrorMessageFromJson / _getErrorMessage` | 422/429 | 错误信息提取 |
| `_refreshAccessToken / refreshAccessToken` | 441/452 | 刷新入口(public 供 ChatStreamClient/SpeechRecognizer 复用) |
| `_doRefreshAccessToken()` | 456 | 实刷新:POST `auth/refresh {refreshToken}` → 更新令牌 + 持久化 |
| `_handleAuthError(msg)` | 507 | 清状态 + `NavigationService.toLoginAndClear()` |

### 重试时序
```
请求 → 2xx 且 status==200 ────────────► 返回
      └ 401/403 或 status==10506 → _refreshAccessToken()
                                     ├ 成功 → 用新 token 重发一次 → 返回
                                     └ 失败 → _handleAuthError → 跳登录 → 抛 HttpException
      └ status==10507 ──────────────► _handleAuthError → 跳登录
```
异常:失败抛 `HttpException`(`http_service.dart:522`,含 statusCode/message)。

## NavigationService (utils/navigation_service.dart)
| 成员 | 行 | 作用 |
|---|---|---|
| `navigatorKey` | 4 | 全局 Key,挂 `MaterialApp.navigatorKey` |
| `context` getter | 6 | `navigatorKey.currentContext` |
| `showSnack(msg)` | 8 | 弹 SnackBar |
| `showAuthExpiredMessage(msg)` | 14 | 认证过期提示(ChatStreamClient 调用) |
| `toLoginAndClear()` | 24 | `pushNamedAndRemoveUntil('/login', …)` 清栈跳登录 |

## 扩展点 / 注意
- 新增接口:直接 `HttpService().post('xxx', body)`,自动获得重试+刷新。
- 切后端地址改 `_baseUrl`(114)。
- 上线前移除所有 `print`(token 泄露)。
- `DeviceBindingRepository`/`StatusUtils` 为轻量工具,按需查源码即可。
