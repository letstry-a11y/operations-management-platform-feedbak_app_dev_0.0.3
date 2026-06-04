# 文档总索引 (INDEX)

> 检索约定:遇到「读取某模块」需求时,**先在本表定位 → 进 `README.md`(架构层)→ 按需 `detail.md`(详细设计层)**。
> 全局/跨模块问题先看 `architecture/`。

## 一、架构层文档(先读)

| 文档 | 内容 |
|---|---|
| [architecture/00-overview.md](architecture/00-overview.md) | 系统总览、技术栈、分层、运行方式 |
| [architecture/01-module-map.md](architecture/01-module-map.md) | 模块划分 + 依赖关系图 |
| [architecture/02-data-flow.md](architecture/02-data-flow.md) | 核心数据流:HTTP / Token 刷新 / 导航 / 状态 |
| [architecture/03-conventions.md](architecture/03-conventions.md) | 路由表、后端约定、状态码、命名规范、注意点 |

## 二、模块检索表

| 模块 | 文档目录 | 主要源码 | 涉及后端接口 | 关键词 |
|---|---|---|---|---|
| 登录鉴权 auth | [modules/auth/](modules/auth/README.md) | `pages/login/*` | auth/login, auth/refresh, auth/sendCode, auth/resetPwd, user/register, user/changePwd, user/destroy | 登录/注册/找回密码/注销/验证码/国家选择 |
| 反馈 feedback | [modules/feedback/](modules/feedback/README.md) | `pages/feedback/feedback_form.dart`, `device_select.dart`, `mine/feedback_edit.dart` | feedback(POST), feedback/{id}(PUT), feedback/attachments | 创建反馈/编辑/附件上传/设备选择/语音转写 |
| 我的/工单 mine | [modules/mine/](modules/mine/README.md) | `pages/mine/*` | feedback/page, feedback/{id}, feedback/{id}/read, feedback/{id}/evaluate, feedback/unread-count, device/*, user/update | 反馈列表/详情/评价/设备管理/扫码绑定/用户编辑 |
| 首页/指南 home-guide | [modules/home-guide/](modules/home-guide/README.md) | `pages/main_page.dart`, `guide_page.dart`, `home_page.dart`, `profile_page.dart` | user/info, user/logout | 底部导航/首页卡片/引导/个人中心 |
| AI 聊天 chat-ai | [modules/chat-ai/](modules/chat-ai/README.md) | `utils/chat_stream_client.dart`, `coze.dart`, `pages/feedback/chat_page.dart` | /structured/convert/stream (SSE) | 流式对话/SSE/Coze/打字动画 |
| 语音识别 speech | [modules/speech/](modules/speech/README.md) | `utils/speech_recognizer.dart`, `widgets/wechat_voice.dart`, `cuteVoice_button.dart`, `pages/feedback/speak_page.dart` | WebSocket `ws/speech` | 录音/PCM分帧/WAV/WebSocket/实时转写 |
| 网络层 network | [modules/network/](modules/network/README.md) | `utils/http_service.dart`, `navigation_service.dart`, `device_binding_repository.dart`, `status_utils.dart` | (全部,统一出口) | 单例HTTP/Token重试/Multipart/全局导航 |
| 状态管理 state | [modules/state/](modules/state/README.md) | `providers/user_provider.dart`, `language_provider.dart` | user/info | Provider/登录态/语言/持久化 |
| 公共组件 widgets | [modules/widgets/](modules/widgets/README.md) | `widgets/*` | — | 附件预览/视频/下拉/Toast/加载按钮/设备卡 |
| 国际化 i18n | [modules/i18n/](modules/i18n/README.md) | `l10n/*.arb`, `generated/*`, `providers/language_provider.dart` | — | intl/ARB/S.of(context)/语言切换 |
| 数据与常量 data | [modules/data/](modules/data/README.md) | `data/*`, `constants/*`, `utils/contant.dart` | — | 国家列表/产品选项/模型 |

## 三、Feature 设计文档

| Feature | 文档 | 状态 |
|---|---|---|
| 语音反馈双页(voice-feedback) | [SRS](features/voice-feedback/SRS.md) · [架构](features/voice-feedback/architecture.md) · [开发计划](features/voice-feedback/dev-plan.md) | 已批准,待开发 |

## 四、后端接口速查(完整)

| Method | Endpoint | 用途 | 调用位置 |
|---|---|---|---|
| POST | `auth/login` | 登录 | login_page.dart:54 |
| POST | `auth/refresh` | 刷新 Token | http_service.dart(_doRefreshAccessToken) |
| GET | `auth/sendCode` | 发送验证码 | forget/register/reset |
| POST | `auth/resetPwd` | 重置密码 | reset_password.dart:147 |
| GET | `user/info` | 用户信息 | profile/guide/login |
| POST | `user/register` | 注册 | register_page.dart:255 |
| POST | `user/update` | 更新资料 | user_edit.dart:206 |
| POST | `user/changePwd` | 修改密码 | change_password.dart:128 |
| POST | `user/destroy` | 注销账户 | destroy_account.dart:167 |
| POST | `user/logout` | 登出 | profile_page.dart:319 |
| POST | `feedback` | 创建反馈 | feedback_form.dart:1226 |
| POST | `feedback/page` | 反馈分页列表 | feedback_list.dart:215 |
| GET | `feedback/{id}` | 反馈详情 | feedback_detail/edit |
| PUT | `feedback/{id}` | 更新反馈 | feedback_edit.dart:1397 |
| PUT | `feedback/{id}/read` | 标记已读 | feedback_list/detail |
| POST | `feedback/{id}/evaluate` | 评价反馈 | feedback_detail.dart:491 |
| GET | `feedback/unread-count` | 未读数 | feedback_list.dart:102 |
| POST(multipart) | `feedback/attachments` | 上传附件 | feedback_form.dart:342 |
| DELETE | `feedback/attachments/{id}` | 删除附件 | feedback_form.dart:380 |
| POST | `device/list` | 设备列表 | device_management_page.dart:146 |
| POST | `device/bind` | 绑定设备 | device_management_page.dart:259 |
| DELETE | `device/unbind/{id}` | 解绑设备 | device_management_page.dart:288 |
| WS | `{baseUri.path}ws/speech` | 语音识别 | speech_recognizer.dart:466 |
| SSE | `{serverUrl}/structured/convert/stream` | AI 流式对话 | chat_stream_client.dart:42 |

> 后端基址:`http://210.22.113.78:32899/microport-management/app/`(见 `http_service.dart:114`)
