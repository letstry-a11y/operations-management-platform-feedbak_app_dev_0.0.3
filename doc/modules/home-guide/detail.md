---
module: home-guide
layer: detail
source_files: [lib/pages/main_page.dart, lib/pages/guide_page.dart, lib/pages/home_page.dart, lib/pages/profile_page.dart]
keywords: [导航, 卡片, 登出, 版本号]
---

# 首页/指南 — 详细设计

## MainPage (main_page.dart)
- `_selectedIndex` 控制 `_pages = [GuidePage, HomePage, ProfilePage]`。
- `_onItemTapped(index)` → `setState` 切页。
- 自绘底部导航(`_buildNavItem` / `_buildNavItemIcons`,后者用 `assets/images/navbar/` 切图区分选中态)。

## GuidePage (guide_page.dart)
- 引导/首页指南内容;语言切换(`LanguageProvider.setLocale`)。
- 登录入口(未登录引导去 `/login`);展示版本号(`package_info_plus`)。

## HomePage (home_page.dart)
- 功能卡片宫格,点击 `Navigator.pushNamed` 到:`/select-device`(创建反馈)、`/feedback_list`、`/device-management`、`/chat` 等。

## ProfilePage (profile_page.dart, 794 行)
- 进入刷新资料:`GET user/info`(:76)→ `UserProvider.setProfile`。
- 入口:`/user-edit`、`/device-management`、`/change-password`、`/destroy-account`、语言切换。
- 登出:`POST user/logout`(:319)→ `UserProvider.clearUser()` → 跳登录/引导。

## 注意
- 底部导航是自绘而非 `BottomNavigationBar` 默认样式,改图标改 `assets/images/navbar/`。
- `MainPage` 默认即入口(`main.dart initialRoute '/'`),不校验登录态(见 conventions)。
