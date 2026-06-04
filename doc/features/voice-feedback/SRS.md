---
feature: voice-feedback
doc_type: SRS
status: approved
related: [architecture.md, dev-plan.md]
source_files: [lib/pages/feedback/feedback_form.dart, lib/utils/speech_recognizer.dart, lib/utils/chat_stream_client.dart]
keywords: [语音反馈, 两页式, AI整理, 结构化, 继续补充, 需求]
---

# 软件需求规格说明(SRS)— 语音反馈双页功能

## 1. 背景与目标
现有反馈为单页表单 `lib/pages/feedback/feedback_form.dart`,字段多、填写门槛高。
目标:改为「**语音输入页 + 信息展示页**」两页式——用户口述即可生成结构化反馈草稿,降低门槛、提升效率。**不修改任何后端接口。**

## 2. 范围
**In(本期)**
- 新增第一页语音输入页(`VoiceInputPage`)。
- 第二页沿用现有表单设计,支持 AI 结构化结果预填、可编辑。
- 「继续补充」:回第一页再语音,新内容 AI 智能合并去重进第二页。
- 路由与入口调整;新增中英 i18n 文案。

**Out(不做)**
- 不改后端接口;不改第二页视觉设计;不改设备扫码/附件/提交逻辑。
- 不替换语音识别引擎(沿用讯飞 `ws/speech`)。

## 3. 角色与用户故事
- **设备使用者(医院 / 运维工程师)**
  - US1:长按按钮说完问题,自动生成反馈草稿。
  - US2:生成的内容可再编辑后提交。
  - US3:补充内容时新信息自动并入且不重复。

## 4. 功能需求(FR)
| 编号 | 需求 | 验收要点 |
|---|---|---|
| FR-1 | 第一页提供醒目大语音按钮 | 居中显著,有"录音中/空闲"视觉态 |
| FR-2 | 三种录音交互并存 | ①长按说话、松手自动结束 ②点击开始/再点结束 ③大按钮点击切换 |
| FR-3 | 实时显示识别文本 | 录音中增量显示 ASR 文本 |
| FR-4 | 容错提示 | 文案:"这只是初步识别,后续会通过 AI 更精准分析"(中/英) |
| FR-5 | 结束后自动分析并跳转 | 松手/结束 → 调 `/structured/convert/stream` → 解析 JSON → 自动进第二页 |
| FR-6 | 第二页 AI 预填 | title/description/occurTime 等按 AI JSON 自动填入,字段可编辑 |
| FR-7 | 设备ID 第二页扫码补充 | 保留现有扫码逻辑,设备ID 不由语音生成 |
| FR-8 | 继续补充 | 第二页可快速回第一页再语音 |
| FR-9 | AI 智能合并去重 | 新语音 + 第二页现有内容一起送 AI,返回合并去重后的完整结构覆盖第二页 |
| FR-10 | 提交沿用现有接口 | `POST feedback` 载荷与字段不变 |

## 5. 非功能需求(NFR)
- **NFR-1 容错**:ASR 允许误差;AI 返回非 JSON 或网络失败时,识别全文回退填入描述,不崩溃。
- **NFR-2 i18n**:全部新文案走 `S.of(context)`,中/英齐备。
- **NFR-3 兼容**:不破坏直接进 `/create-feedback` 的旧路径。
- **NFR-4 性能**:分析期有 loading 态;SSE 增量展示,避免长时间白屏。
- **NFR-5 约束**:**零后端接口改动**。

## 6. 约束与假设
- 假设 `/structured/convert/stream` 返回结构化 JSON(含 title/description/occurTime,可能 deviceType)。**开发 Step 0 须实测确认确切 schema**。
- 语音识别沿用 `SpeechRecognizer`(讯飞,付费,已知)。

## 7. 验收标准
三种录音交互可用;说完自动分析并跳转、第二页字段被预填;设备ID 扫码可补;继续补充能合并去重;提交成功(接口不变);中英切换正常;异常回退不崩。详见 [dev-plan.md](dev-plan.md) 的"验证"。
