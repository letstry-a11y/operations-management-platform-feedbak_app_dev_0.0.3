---
module: i18n
layer: detail
source_files: [lib/l10n/, lib/generated/]
keywords: [intl, ARB, 生成, 流程]
---

# 国际化 — 详细设计

## 工作流
```
编辑 lib/l10n/intl_zh.arb + intl_en.arb   (新增/改 key)
        │
        ▼
flutter pub run intl_utils:generate        (生成)
        │
        ▼
lib/generated/l10n.dart (S 类) + intl/messages_*.dart
        │
        ▼
代码中 S.of(context).<key>
```

## 接入点(main.dart)
```dart
localizationsDelegates: [
  S.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: [Locale('en',''), Locale('zh','')],
locale: languageProvider.locale,   // 由 LanguageProvider 驱动
```

## 切换语言时序
```
用户切换 → LanguageProvider.setLocale(code)
  → 持久化 + notifyListeners
  → Consumer<LanguageProvider> rebuild
      ├─ HttpService().setLanguage(code)   // 后续请求带 X-Language
      └─ MaterialApp.locale = locale       // UI 文案切换
```

## 规则
- **禁止硬编码中文/英文**,统一加 key 到两个 ARB。
- 改完务必重新 `generate`,否则 `S` 类缺 key 编译报错。
- `generated/` 为产物,**不手改、不评审**。
