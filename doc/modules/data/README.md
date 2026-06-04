---
module: data
layer: module-readme
source_files: [lib/data/models/country.dart, lib/data/constants/all_countries.dart, lib/data/constants/user_options.dart, lib/constants/product_options.dart, lib/utils/contant.dart]
backend_apis: []
depends_on: []
keywords: [国家列表, 产品选项, 模型, 常量]
---

# 数据与常量 data

## 职责
静态数据与领域常量:国家/区号列表、产品型号选项、用户选项、通用常量、数据模型。无网络与状态。

## 文件清单
| 文件:行 | 职责 |
|---|---|
| `data/models/country.dart` (18) | 国家模型(名称/区号/code) |
| `data/constants/all_countries.dart` (253) | 全球国家列表(注册/区号选择用) |
| `data/constants/user_options.dart` (26) | 用户相关下拉选项 |
| `constants/product_options.dart` (19) | 产品型号选项 |
| `utils/contant.dart` (9) | `productOptions`:图迈多孔/单孔、蜻蜓眼、鸿鹄、Rone、蒙娜丽莎、其他(label/value) |

## 使用方
- `country_picker.dart`/`register_page.dart` → 国家数据。
- `device_select.dart`/下拉选择器 → 产品选项。

## 详细设计
见 [detail.md](detail.md)。
