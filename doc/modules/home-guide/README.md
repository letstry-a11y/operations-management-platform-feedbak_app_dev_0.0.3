---
module: home-guide
layer: module-readme
source_files: [lib/pages/main_page.dart, lib/pages/guide_page.dart, lib/pages/home_page.dart, lib/pages/profile_page.dart]
backend_apis: [user/info, user/logout]
depends_on: [network, state, i18n, widgets]
keywords: [底部导航, 首页, 引导, 个人中心, 功能卡片, 登出]
---

# 首页/指南 home-guide

## 职责
应用主框架与一级页面:底部导航容器、首页功能卡片、引导页(语言切换/登录入口)、个人中心(资料/设备入口/登出)。

## 文件清单
| 文件:行 | 职责 | 主要接口 |
|---|---|---|
| `main_page.dart` (154) | `BottomNavigationBar`,切换 Guide/Home/Profile | — |
| `guide_page.dart` (395) | 引导/首页指南、语言选择、登录入口、版本号 | — |
| `home_page.dart` (288) | 首页功能卡片(创建反馈/我的反馈/设备管理等入口) | — |
| `profile_page.dart` (794) | 个人资料、跳用户编辑/设备管理、登出 | `user/info`(:76)、`user/logout`(:319) |

## 对外入口(路由)
`/`(`MainPage`)、`/guide`、`/profile`。其余页面由卡片/按钮 `Navigator.pushNamed` 进入。

## 依赖
- `UserProvider`(登录态/资料)、`LanguageProvider`(语言)、`HttpService`、`package_info_plus`(版本号)。

## 详细设计
见 [detail.md](detail.md)。
