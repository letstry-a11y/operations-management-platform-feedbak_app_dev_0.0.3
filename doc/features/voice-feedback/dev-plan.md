---
feature: voice-feedback
doc_type: dev-plan
status: approved
related: [SRS.md, architecture.md]
keywords: [开发计划, 步骤, 里程碑, 验证, 风险]
---

# 分步骤开发计划 — 语音反馈双页功能

> 每步含:产出、改动文件、验证。按序提交,逐步可验证。

## Step 0 · 实测 AI 返回结构(前置,关键)
- 模拟器登录后,对 `/structured/convert/stream` 发样例反馈文本,记录真实返回(是否结构化 JSON、字段名)。
- 产出:确定 `ai_fields` 字段映射;若非 JSON,启用回退(只填 description)。

## Step 1 · i18n 文案
- 改 `lib/l10n/intl_zh.arb` + `intl_en.arb`,新增:`voiceInputTitle / voicePreliminaryHint / tapOrHoldToSpeak / listening / analyzing / continueSupplement` 等。
- 运行 `flutter pub run intl_utils:generate`。
- 验证:`S.of(context).voicePreliminaryHint` 可用,中英正确。

## Step 2 · 新建 VoiceInputPage(录音 + 实时文本)
- 新建 `lib/pages/feedback/voice_input_page.dart`:大按钮 + 三种交互 + 实时识别文本 + 容错提示。
- 复用 `SpeechRecognizer`(参考 `feedback_form.dart:209`)。
- 验证:三种交互均能起停录音并显示文本(暂不接 AI)。

## Step 3 · 接 AI 整理 + SSE→JSON
- 实现 `_callStructuredConvert(content)`:累积 `ChatStreamClient.askQuestion` 全文 → 清洗 → `jsonDecode`(含 ```json 剥离 + 回退)。
- 结束后 `_analyzeAndGo()`:分析中 loading → `pushReplacementNamed('/create-feedback', arguments)`。
- 验证:说一段 → 得到结构化 Map。

## Step 4 · 第二页接收预填
- 改 `feedback_form.dart` 的 `didChangeDependencies`:解析 `ai_fields` → 预填 `_titleController / _descriptionController / _selectedDateTime / deviceType`(非空才填)。
- 验证:从语音页跳入,字段被填入且可编辑;设备ID 仍扫码。

## Step 5 · 继续补充 + AI 合并
- 第二页加「继续补充」按钮 → `pushNamed('/voice-feedback', {from_supplement, existing_content})`。
- VoiceInputPage 补充模式:合并 content → 取合并 JSON → `Navigator.pop(map)`。
- 第二页 `await` 接收 → 合并填入 → `setState`。
- 验证:补充重复语句,描述合并且去重。

## Step 6 · 路由与入口
- `main.dart` 加 `'/voice-feedback'`;把 `device_select.dart` / `home_page.dart` 原指向 `/create-feedback` 的入口改为先进 `/voice-feedback`;保留旧直达路径。
- 验证:正式入口走两页式;旧路径仍可用。

## Step 7 · 权限与端到端回归
- 沿用讯飞,无需新增语音权限;麦克风权限已有。
- 端到端跑通 SRS 验收项;中英切换;异常回退。

## 风险
- **R1**:AI 返回非稳定 JSON → Step 0 实测 + 回退兜底。
- **R2**:合并覆盖用户手动编辑 → 已确认接受;必要时后续加"合并前确认"。
- **R3**:讯飞识别中文专业词误差 → 容错提示已覆盖,AI 整理可纠偏。

## 验证(总)
`flutter run -d <iPhone-26.5-sim>` → 三种录音交互 → 自动分析跳转预填 → 设备扫码 → 继续补充合并去重 → 提交成功 → 中英切换 → 异常回退不崩。

## 进度跟踪
- [ ] Step 0 实测 AI 返回
- [ ] Step 1 i18n
- [ ] Step 2 VoiceInputPage 录音
- [ ] Step 3 AI 整理 + JSON
- [ ] Step 4 第二页预填
- [ ] Step 5 继续补充合并
- [ ] Step 6 路由入口
- [ ] Step 7 回归
