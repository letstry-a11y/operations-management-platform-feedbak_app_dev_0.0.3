---
module: data
layer: detail
source_files: [lib/data/, lib/constants/, lib/utils/contant.dart]
keywords: [常量, 模型, 产品, 国家]
---

# 数据与常量 — 详细设计

## 产品选项 (utils/contant.dart / constants/product_options.dart)
`List<Map<String,dynamic>> productOptions`,label/value 对:
| label | value |
|---|---|
| 图迈多孔 | 101 |
| 图迈单孔 | 102 |
| 蜻蜓眼 | 103 |
| 鸿鹄 | 104 |
| Rone | 105 |
| 蒙娜丽莎 | 106 |
| 其他 | 107 |
> 对应微创手术机器人产品线。`value` 即提交反馈的 `product_id`。
> 注意 `contant.dart` 与 `constants/product_options.dart` 内容重叠,使用时确认引用来源。

## 国家 (data/)
- `models/country.dart`:`Country{ name, dialCode/code, ... }`。
- `constants/all_countries.dart`:完整国家列表,供 `azlistview` A-Z 索引(配 `lpinyin`)。
- `constants/user_options.dart`:用户资料相关枚举选项。

## 约定
- 纯数据,改动无副作用;新增产品型号在此加一行并同步后端 `product_id` 约定。
- 文案展示仍建议经 i18n(若需多语言),当前部分 label 为中文硬编码。
