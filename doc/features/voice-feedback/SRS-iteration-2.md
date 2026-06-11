---
feature: voice-feedback
doc_type: SRS
iteration: 2
status: implemented
date: 2026-06-11
related: [SRS.md, architecture.md, dev-plan.md]
source_files:
  [
    lib/pages/feedback/voice_input_page.dart,
    lib/pages/feedback/feedback_form.dart,
    lib/utils/speech_recognizer.dart,
    lib/utils/kimi_client.dart,
    lib/l10n/intl_zh.arb,
    lib/l10n/intl_en.arb,
  ]
keywords: [跳过语音, 序号记录, 标题总结, 50秒自动停止, 倒计时, 会话续连, occurTime防幻觉]
---

# 软件需求规格说明(SRS)— 语音反馈双页 · 第二期迭代

## 1. 背景与目标

第一期(见 [SRS.md](SRS.md))已落地「语音输入页 + 文字输入页」两页式反馈。本期针对试用反馈做六项改进:

1. 语音不是必选项——允许直接跳到文字输入;
2. 文字输入页职责单一化——移除页内残留的语音录音控件;
3. 多次语音补充的内容要可追溯——按序号分条记录,不再整体合并改写;
4. 录音时长要受控——讯飞 IAT 单会话 60s 硬限制,需提前自动停止并提示;
5. 修复「界面显示录音中、实际识别已断」的缺陷;
6. 修复「未提及发生时间却被 AI 自动填充」的缺陷。

**约束不变:零后端接口改动。**

## 2. 范围

**In(本期)**
- 语音输入页(`VoiceInputPage`)新增「跳过,直接文字输入」入口(首次/补充两种模式)。
- 创建反馈表单(`FeedbackForm`)删除标题、问题描述的语音输入界面与全部相关代码。
- 多次语音 → 问题描述按「1. / 2. …」序号分条追加;标题始终为全部内容的 AI 总结。
- 录音 50s 自动停止;最后 10s 状态文字倒计时提示。
- 识别会话被服务端结束(VAD 判停 / 时长上限 / 断连)时自动重连续上。
- `occurTime` 防幻觉双层校验。

**Out(不做)**
- 不改编辑页(`feedback_edit.dart`)的语音功能(仍保留原有录音控件与 50s 限制)。
- 不改后端接口、提交载荷、附件与扫码逻辑。
- 不替换语音识别引擎(沿用讯飞 `ws/speech` 中台代理)。

## 3. 功能需求(FR)

| 编号 | 需求 | 实现要点 | 验收要点 |
|---|---|---|---|
| FR2-1 | 语音页可跳过语音直接文字输入 | `_skipToTextInput()`:首次模式 `pushReplacementNamed('/create-feedback')` 并透传 `product_id`/`feedback_type`;补充模式直接 `pop()` 返回表单且不改动已填内容;录音中点击先静默停止识别;AI 分析中按钮禁用 | 语音页底部有「跳过,直接文字输入」按钮(键盘图标);首次/补充两种模式下均显示、行为正确 |
| FR2-2 | 表单页删除标题/描述语音输入 | 删除 `_MicButton`/`_VoiceBar`/`_RecognizingIndicator` 组件类及 `SpeechRecognizer`、`FlutterSoundPlayer`、`ChatStreamClient` 等全部相关状态与方法;提交体不再含 `titleAudio`/`descriptionAudio`;文件 2537 行精简至约 1923 行 | 「问题标题」「问题描述」无麦克风按钮、无录音条;顶部「继续补充」(回语音页)保留;提交正常 |
| FR2-3 | 多次语音按序号分条记录 | 首次:描述填 `1. <AI 整理结果>`;补充:取已有描述最大序号 +1 追加 `N. <本次整理结果>`,不改写已有记录;手动输入的无编号描述整体视作第 1 条 | 第一次、第二次语音的内容在问题描述中分别以 `1.`、`2.` 列出;第三次及以后继续编号 |
| FR2-4 | 标题为全部内容的总结 | 补充模式提示词:`description` 只整理本次新口述;`title` 综合「已有记录 + 本次补充」总结(中文 ≤20 字 / 英文 ≤12 词) | 每次补充后标题更新为覆盖全部记录的总结语句 |
| FR2-5 | 录音 50s 自动停止 | `Timer.periodic` 计时,`_maxRecordSeconds = 50`(讯飞 IAT 单会话 60s 上限留 10s 余量,与编辑页一致);到点自动走「停止 → AI 整理」流程 | 持续录音到 50s 自动收尾,已说内容正常进入整理 |
| FR2-6 | 最后 10s 倒计时提示 | 前 40s 状态栏仅显示「正在聆听…」(不计时);剩余 ≤10s 显示「N 秒后将自动停止」,每秒刷新;字体颜色、大小与常态一致(不用红色) | 录音第 41s 起出现倒计时文字,样式与平时一致 |
| FR2-7 | 识别会话自动续连(缺陷修复) | 服务端因 VAD 判停下发 `final`、或意外断开(60s 上限/网络)而用户仍在录音时,`SpeechRecognizer` 自动重建 WebSocket 并重发 start 配置,识别文本经 `onResult` 持续累加;重连期间丢弃的音频帧为触发判停的静音段;用户主动停止/页面销毁不受影响;重连失败走 `onError` 复位界面 | 讲话中途停顿数秒后继续讲,后续内容仍能识别出字;UI 录音态与实际识别状态一致 |
| FR2-8 | occurTime 防幻觉(缺陷修复) | ① 提示词:仅当口述明确出现时间表达才输出 `occurTime`,严禁以「当前时间」填充;并要求逐字摘录时间原话到 `occurTimeQuote`;② App 校验:摘录为空或在本次口述文本中找不到时丢弃 `occurTime`(日志打印 `drop occurTime`) | 口述未提时间 → 表单「发生时间」保持未选;口述「昨天下午三点」→ 正确换算填入 |
| FR2-9 | 语音连接 token 过期自动刷新(缺陷修复) | access token 有效期 900s;HTTP 请求过期由 `HttpService` 自动刷新,但 WS 握手不走该机制,过期后网关不升级协议、直接回 HTTP 200 JSON 导致连接报错。新增 `_connectChannel()`:握手失败时调用 `HttpService().refreshAccessToken()` 刷新后自动重试一次(首次连接与会话续连共用);重试期间错误不上报 UI、不误触发重连,刷新仍失败才报错 | 登录超过 15 分钟后再录音/补录,连接成功无报错;refresh token 失效时才提示错误 |

## 4. 非功能需求(NFR)

- **NFR2-1 i18n**:新增文案 `skipToTextInput`、`autoStopCountdown`(带 `{seconds}` 占位符)中英齐备,走 `S.of(context)`。
- **NFR2-2 兼容**:直接进 `/create-feedback` 的旧路径不受影响;编辑页语音功能不受影响(会话续连对其同样生效且向后兼容)。
- **NFR2-3 资源安全**:录音计时器在手动停止、自动停止、识别出错、跳过、页面销毁时均正确取消,无泄漏。
- **NFR2-4 容错**:AI 整理失败时,本次口述原文按序号追加为新记录,已有标题不被覆盖。
- **NFR2-5 约束**:零后端接口改动;`POST feedback` 载荷中 `titleAudio`/`descriptionAudio` 字段不再发送(后端字段为可选,不影响兼容)。

## 5. 修改文件清单

| 文件 | 变更 |
|---|---|
| `lib/pages/feedback/voice_input_page.dart` | 跳过按钮(FR2-1)、序号记录(FR2-3)、50s 计时与倒计时(FR2-5/6)、occurTime 校验(FR2-8) |
| `lib/pages/feedback/feedback_form.dart` | 删除语音输入界面与代码(FR2-2) |
| `lib/utils/speech_recognizer.dart` | 会话自动续连 `_restartSession()`(FR2-7);握手 token 刷新重试 `_connectChannel()`(FR2-9) |
| `lib/utils/kimi_client.dart` | 补充模式提示词(FR2-4)、occurTime/occurTimeQuote 规则(FR2-8) |
| `lib/l10n/intl_zh.arb` / `intl_en.arb` | 新增 `skipToTextInput`、`autoStopCountdown` |
| `doc/INDEX.md`、`doc/modules/feedback/*` | 文档同步 |

## 6. 验收标准

1. 语音页(首次/补充)均可一键跳到文字输入,补充模式跳过不改动表单;
2. 表单页标题/描述无任何语音控件,提交成功;
3. 两次语音后描述呈 `1. … / 2. …` 分条,标题为总结语句;
4. 录音 41s 起出现常规样式倒计时,50s 自动停止并完成 AI 整理;
5. 讲话停顿后继续讲,后续内容识别不丢;
6. 不提时间则「发生时间」不被自动填充,提到相对时间可正确换算;
7. 登录超过 15 分钟后录音/补录,语音连接不报 token 过期错误;
8. 中英文切换文案正常;`flutter analyze` 无新增错误。
