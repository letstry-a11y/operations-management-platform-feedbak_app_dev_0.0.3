import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kimi(Anthropic 兼容)整理客户端。
///
/// ⚠️ 交互期临时方案:API Key 直接内置在 App 内。
/// 移动端可被反编译,密钥存在泄露风险。**正式版必须把此调用迁移到后端**
/// (由后端持有密钥,App 仅调用后端 /structured/convert 接口)。
class KimiClient {
  static const String _apiKey =
      'sk-kimi-AKKdjtFINegKJCEHmh23UfBhxLnhLizCsApXqiY2gjrYIYWcQnW4SrEenzlxs8xS';
  static const String _endpoint = 'https://api.kimi.com/coding/v1/messages';
  static const String _model = 'kimi-for-coding';

  /// 把用户口述/合并后的内容整理为结构化反馈字段。
  /// 返回 Map(可能含 title / description / occurTime);
  /// 解析失败时返回 {description: 原文, _fallback: true}。
  Future<Map<String, dynamic>> organizeToFeedback(String content) async {
    final now = DateTime.now();
    final nowStr = _formatNow(now);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];

    final prompt = '''你是医疗设备售后反馈整理助手。请把用户口述的反馈整理为结构化 JSON。

当前时间:$nowStr($weekday)。

要求:
1. "title" 和 "description" 必须使用与"用户口述内容"相同的语言书写,不要翻译。
   例如用户用英文口述,就用英文整理输出;用中文口述就用中文输出。
2. 只输出一个 JSON 对象,不要任何解释文字,不要使用 markdown 代码块。
3. 字段:
   - "title": 简短的问题标题(尽量简洁,中文不超过 20 字,英文不超过 12 词)
   - "description": 完整、通顺的问题描述
   - "occurTime": 提取用户提到的"问题发生时间",解析为绝对时间,格式 "yyyy-MM-dd HH:mm:ss"。
       · 需支持相对/口语表达并基于"当前时间"换算成具体时间,例如:
         "今天/昨天/前天/大前天"、"N天前"、"上周三/这周一"、"上个月X号"、
         "早上/上午/中午/下午/傍晚/晚上/凌晨X点"、"半小时前/两小时前"等;
         英文如 "today/yesterday/last Wednesday/2 hours ago/this morning" 等同样支持。
       · 若只说了日期没说具体时刻,时间部分用 00:00:00。
       · 若只说了时刻没说哪天,默认取当天日期。
       · 若用户完全没提到发生时间,输出空字符串 ""。
4. 修正明显的口语和错别字,但不要编造用户未提及的信息。

用户口述内容:
$content''';

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Kimi ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    String text = '';
    if (decoded is Map && decoded['content'] is List) {
      final list = decoded['content'] as List;
      for (final part in list) {
        if (part is Map && part['type'] == 'text') {
          text += (part['text']?.toString() ?? '');
        }
      }
    }

    final map = _extractJson(text);
    if (map != null) return map;
    // 回退:整段文本作为描述
    return {
      'description': text.trim().isEmpty ? content : text.trim(),
      '_fallback': true,
    };
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatNow(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} '
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  Map<String, dynamic>? _extractJson(String text) {
    var t = text
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
        .replaceAll('```', '')
        .trim();
    final s = t.indexOf('{');
    final e = t.lastIndexOf('}');
    if (s == -1 || e == -1 || e <= s) return null;
    try {
      final d = json.decode(t.substring(s, e + 1));
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return d.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }
}
