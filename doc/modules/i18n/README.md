---
module: i18n
layer: module-readme
source_files: [lib/l10n/intl_zh.arb, lib/l10n/intl_en.arb, lib/generated/l10n.dart, lib/generated/intl/, lib/providers/language_provider.dart]
backend_apis: []
depends_on: [state]
keywords: [国际化, intl, ARB, S.of, 语言切换, 中英]
---

# 国际化 i18n

## 职责
中/英双语文案管理与运行期切换。主语言 `zh`,通过 `intl_utils` 从 ARB 生成 `S` 类。

## 文件清单
| 文件 | 职责 |
|---|---|
| `lib/l10n/intl_zh.arb` | 中文文案源(主语言) |
| `lib/l10n/intl_en.arb` | 英文文案源 |
| `lib/generated/l10n.dart` (2283) | 生成的 `S` 类,`S.of(context).xxx` |
| `lib/generated/intl/messages_{zh,en,all}.dart` | 生成的翻译表(勿手改) |
| `lib/providers/language_provider.dart` | 运行期语言状态(见 state 模块) |

## 对外入口
- `S.of(context).<key>` 取文案;`S.delegate` 注册于 `MaterialApp.localizationsDelegates`。
- 切换语言:`LanguageProvider.setLocale('zh'|'en')`(同步 `HttpService.setLanguage` 影响 `X-Language` 头)。

## 配置
`pubspec.yaml` 的 `flutter_intl`:`class_name: S`、`main_locale: zh`、`arb_dir: lib/l10n`、`output_dir: lib/generated`。

## 详细设计
见 [detail.md](detail.md)。
