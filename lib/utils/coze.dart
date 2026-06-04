import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String apiToken = 'pat_EhKzuH0qy57iOsO3EXVuMJUyBtrOcTlzObHX05FKiymaM0rGd3AhOWWd8rxII64D';
const String botId = '7507526535419674660';
const String userId = 'box';
const String apiBase = 'https://api.coze.cn/v3'; // 替换为你的 API 地址

Future<void> askBotStream(String question) async {
  final url = Uri.parse('$apiBase/chat');
  final headers = {
    'Authorization': 'Bearer $apiToken',
    'Content-Type': 'application/json',
  };

  final payload = jsonEncode({
    'bot_id': botId,
    'user_id': userId,
    'stream': true,
    'auto_save_history': true,
    'additional_messages': [
      {'role': 'user', 'content': question, 'content_type': 'text'}
    ],
  });

  final request = http.Request('POST', url)
    ..headers.addAll(headers)
    ..body = payload;

  final streamedResponse = await request.send();

  if (streamedResponse.statusCode != 200) {
    print('请求失败：${streamedResponse.statusCode}');
    return;
  }

  print('整理结果：');
  String event = '';
  await streamedResponse.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) {
        //  print(line);
    if (line.startsWith('event:')) {
      event = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final data = line.substring(5).trim();
      if (event == 'conversation.message.delta') {
        try {
          final parsed = jsonDecode(data);
          stdout.write(parsed['content'] ?? '');
        } catch (e) {
          // 忽略解析错误
        }
      }
    }
  });

  print('');
}

Future<void> main() async {
  print('=== 问题整理 ===\n输入 empty 或 Ctrl+C 退出\n');

  while (true) {
    stdout.write('你：');
    final input = stdin.readLineSync();
    if (input == null || input.trim().isEmpty) {
      break;
    }

    try {
      await askBotStream(input.trim());
    } catch (e) {
      print('发生错误：$e');
    }
  }

  print('\n已退出。');
}
