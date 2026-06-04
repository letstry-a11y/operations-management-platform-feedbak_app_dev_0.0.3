# CLAUDE.md

本文件供 Claude Code 快速掌握本项目。**遇到模块相关任务时,务必先走文档检索,再读源码。**

## 项目速览
- **medbot_ai_app** — 微创手术机器人(Medbot)设备的售后/运维反馈 App。
- Flutter(Dart ^3.7.2)跨平台,主目标 iOS;包名 `com.medbotsurgical.medbotAiApp`;版本 `1.0.0+14`。
- 状态管理 `provider`;命名路由;自封装单例 `HttpService`;`intl` 中英国际化(主语言 zh)。
- 后端基址(明文 HTTP):`http://210.22.113.78:32899/microport-management/app/`。

## 📚 文档检索规约(重要)
所有模块知识在 `doc/`。检索顺序:
1. **先看 [`doc/INDEX.md`](doc/INDEX.md)** — 模块→文档→源码→后端接口的总表,定位目标模块。
2. **架构层** [`doc/architecture/`](doc/architecture/) — 全局/跨模块问题先读:
   - `00-overview.md` 总览 / `01-module-map.md` 模块与依赖 / `02-data-flow.md` 数据流 / `03-conventions.md` 路由+状态码+规范。
3. **模块层** `doc/modules/<模块>/`:
   - 先 `README.md`(架构摘要:职责/文件/入口/依赖/接口)
   - 需要细节再 `detail.md`(类/函数/调用链/接口/异常)。

> 当用户说「读取 X 模块」:打开 `doc/modules/X/README.md` 即可获得该模块全貌;深入实现再看 `detail.md`;涉及源码改动时,以文档里的 file:line 为入口跳转。

### 模块目录速查
`auth`(登录鉴权) `feedback`(反馈创建/编辑) `mine`(列表/详情/设备/用户) `home-guide`(导航/首页/个人中心) `chat-ai`(SSE 流式对话) `speech`(WebSocket 语音) `network`(HttpService/导航) `state`(providers) `widgets`(公共组件) `i18n`(国际化) `data`(常量/模型)。

## 文档维护
改动某模块代码后,同步更新 `doc/modules/<x>/README.md`(必要时 `detail.md`)与 `doc/INDEX.md`。行号会漂移,**以类名/函数名为准**,行号仅供快速定位。

## 运行
```bash
flutter pub get
open -a Simulator && flutter run -d <iPhone-simulator-id>   # iOS(已装 iOS 26.5 运行时)
flutter run -d chrome    # 或浏览器
```
国际化:`flutter pub run intl_utils:generate`(改 `lib/l10n/*.arb` 后必须执行)。

## 注意点(详见 doc/architecture/03-conventions.md)
1. 后端明文 HTTP;iOS 已加 ATS 例外(`ios/Runner/Info.plist`)。
2. `http_service.dart` 多处 `print` 明文 token,生产需移除。
3. Token 自动刷新依赖后端状态码 `10506`(过期)/`10507`(需重新登录)。
4. 入口登录态校验当前被注释,默认直接进 `MainPage`。
5. 仓库含 `._*.dart`(macOS 垃圾文件)与 `attachment_preview copy.dart`(冗余),非有效源码。
