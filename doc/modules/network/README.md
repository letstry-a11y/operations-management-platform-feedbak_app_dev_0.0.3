---
module: network
layer: module-readme
source_files: [lib/utils/http_service.dart, lib/utils/navigation_service.dart, lib/utils/device_binding_repository.dart, lib/utils/status_utils.dart]
backend_apis: [统一出口,所有接口]
depends_on: [state]
keywords: [HTTP, 单例, Token刷新, 重试, Multipart, 全局导航]
---

# 网络层 network

## 职责
应用统一网络出口与基础设施:单例 HTTP 客户端、Token 自动刷新与重试、Multipart 文件上传、全局导航(无 context 跳转)、工单状态映射、设备 ID 本地缓存。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `utils/http_service.dart` (532) | 单例 `HttpService`,get/post/put/delete/postMultipart + `_sendWithRetry` + Token 刷新 |
| `utils/navigation_service.dart` (29) | 全局 `navigatorKey`、`showSnack`、`showAuthExpiredMessage`、`toLoginAndClear` |
| `utils/device_binding_repository.dart` (31) | 设备绑定 ID 的本地存储 CRUD |
| `utils/status_utils.dart` (37) | 工单状态 → 文本/颜色映射 |

## 对外入口
- `HttpService()`(工厂单例)→ `get/post/put/delete/postMultipart`、属性 `token/refreshToken/baseUrl/languageCode`、`setToken/setRefreshToken/clearToken/setLanguage/refreshAccessToken`。
- `NavigationService.navigatorKey`(挂到 `MaterialApp`)、`toLoginAndClear()`。

## 依赖
- 被**所有页面**与 `ChatStreamClient`、`SpeechRecognizer` 依赖。
- 刷新失败/10507 时调用 `NavigationService.toLoginAndClear()`。

## 详细设计
见 [detail.md](detail.md)。
