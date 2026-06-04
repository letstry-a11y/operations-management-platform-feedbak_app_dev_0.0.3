import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/utils/navigation_service.dart';

class AuthExpiredException implements Exception {
  final String message;
  AuthExpiredException(this.message);

  @override
  String toString() => message;
}

class ChatStreamClient {
  final String serverUrl;
  static bool _authRedirecting = false;

  ChatStreamClient({required this.serverUrl});

  /// 发起问题请求并接收 SSE 流数据
  Stream<String> askQuestion(
    String question, {
    String userId = 'flutter_user',
    String? token,
  }) async* {
    yield* _askQuestionInternal(
      question,
      userId: userId,
      token: token,
      retried: false,
    );
  }

  Stream<String> _askQuestionInternal(
    String question, {
    required String userId,
    String? token,
    required bool retried,
  }) async* {
    final url = Uri.parse('$serverUrl/structured/convert/stream');
    print("ChatStreamClient askQuestion url: $url");
    final client = http.Client();

    try {
      final authToken = token ?? HttpService().token;
      if (authToken == null || authToken.trim().isEmpty) {
        if (!retried && await HttpService().refreshAccessToken()) {
          yield* _askQuestionInternal(
            question,
            userId: userId,
            token: HttpService().token,
            retried: true,
          );
          return;
        }
        _triggerAuthRedirect('登录已过期，请重新登录');
        throw AuthExpiredException('Token is empty');
      }
      final request =
          http.Request('POST', url)
            ..headers['Content-Type'] = 'application/json'
            ..headers['Accept'] = 'text/event-stream'
            ..headers['Cache-Control'] = 'no-cache'
            ..headers['Authorization'] = 'Bearer $authToken'
            ..body = jsonEncode({'content': question});

      final response = await client.send(request);

      final contentType = (response.headers['content-type'] ?? '').toLowerCase();
      final isEventStream = contentType.contains('text/event-stream');
      if (!isEventStream) {
        final bodyText = await response.stream.bytesToString();
        try {
          final decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic>) {
            final status = decoded['status'];
            final message = decoded['message'];
            if (status == 10506 && !retried) {
              if (await HttpService().refreshAccessToken()) {
                yield* _askQuestionInternal(
                  question,
                  userId: userId,
                  token: HttpService().token,
                  retried: true,
                );
                return;
              }
            }
            if (status == 10507) {
              final messageText =
                  message is String && message.trim().isNotEmpty ? message : '登录已过期，请重新登录';
              _triggerAuthRedirect(messageText);
              throw AuthExpiredException(messageText);
            }
            if (status is int && status != 200) {
              final messageText =
                  message is String && message.trim().isNotEmpty ? message : '请求失败';
              if (_isAuthError(statusCode: null, jsonBody: decoded, bodyText: messageText)) {
                _triggerAuthRedirect(messageText);
                throw AuthExpiredException(messageText);
              }
              throw Exception(messageText);
            }
          }
        } catch (_) {}

        if (_isAuthError(statusCode: response.statusCode, bodyText: bodyText)) {
          final message = _extractAuthMessage(bodyText) ?? '登录已过期，请重新登录';
          _triggerAuthRedirect(message);
          throw AuthExpiredException(message);
        }

        throw Exception('服务端响应失败: ${response.statusCode} $bodyText');
      }

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        try {
          final decoded = jsonDecode(errorBody);
          if (decoded is Map<String, dynamic>) {
            final status = decoded['status'];
            final message = decoded['message'];
            if (status == 10506 && !retried) {
              if (await HttpService().refreshAccessToken()) {
                yield* _askQuestionInternal(
                  question,
                  userId: userId,
                  token: HttpService().token,
                  retried: true,
                );
                return;
              }
            }
            if (status == 10507) {
              final messageText =
                  message is String && message.trim().isNotEmpty ? message : '登录已过期，请重新登录';
              _triggerAuthRedirect(messageText);
              throw AuthExpiredException(messageText);
            }
          }
        } catch (_) {}
        if (_isAuthError(statusCode: response.statusCode, bodyText: errorBody)) {
          final message = _extractAuthMessage(errorBody) ?? '登录已过期，请重新登录';
          _triggerAuthRedirect(message);
          throw AuthExpiredException(message);
        }
        throw Exception('服务端响应失败: ${response.statusCode} $errorBody');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
            var printableLine =
                line.replaceAll(r'\r', '\r').replaceAll(r'\n', '\n').trim();
            if (printableLine.startsWith('"') || printableLine.startsWith('“')) {
              printableLine = printableLine.substring(1);
            }
            if (printableLine.endsWith('"') || printableLine.endsWith('”')) {
              printableLine = printableLine.substring(0, printableLine.length - 1);
            }
        if (!printableLine.startsWith('data:')) {
          continue;
        }

        final dataJson = printableLine.substring(5).trim();
        if (dataJson.isEmpty) {
          continue;
        }

        if (dataJson.contains('[DONE]')) {
          break;
        }

        try {
          final decoded = jsonDecode(dataJson);
          final Map<String, dynamic>? decodedMap;
          if (decoded is Map<String, dynamic>) {
            decodedMap = decoded;
          } else if (decoded is String) {
            final nested = jsonDecode(decoded);
            decodedMap = nested is Map<String, dynamic> ? nested : null;
          } else {
            decodedMap = null;
          }

          if (decodedMap == null) {
            yield decoded.toString();
            continue;
          }

          final status = decodedMap['status'];
          final message = decodedMap['message'];
          if (status == 10506 && !retried) {
            if (await HttpService().refreshAccessToken()) {
              yield* _askQuestionInternal(
                question,
                userId: userId,
                token: HttpService().token,
                retried: true,
              );
              return;
            }
          }
          if (status == 10507) {
            final messageText =
                message is String && message.trim().isNotEmpty ? message : '登录已过期，请重新登录';
            _triggerAuthRedirect(messageText);
            throw AuthExpiredException(messageText);
          }
          if (status is int && status != 200) {
            final messageText =
                message is String && message.trim().isNotEmpty ? message : '请求失败';
            if (_isAuthError(statusCode: null, jsonBody: decodedMap, bodyText: messageText)) {
              _triggerAuthRedirect(messageText);
              throw AuthExpiredException(messageText);
            }
            throw Exception(messageText);
          }

          final content = decodedMap['content'];
          if (content is String && content.isNotEmpty) {
            yield content;
          }
        } on FormatException {
          yield dataJson;
        }
      }
    } finally {
      client.close();
    }
  }

  bool _isAuthError({
    required int? statusCode,
    Map<String, dynamic>? jsonBody,
    String? bodyText,
  }) {
    if (statusCode == 401 || statusCode == 403) return true;
    final status = jsonBody?['status'];
    if (status == 10506 || status == 10507) return true;

    final message = (jsonBody?['message'] ?? bodyText)?.toString().toLowerCase();
    if (message == null || message.trim().isEmpty) return false;

    return message.contains('token') && (message.contains('expired') || message.contains('过期')) ||
        message.contains('unauthorized') ||
        message.contains('没有授权') ||
        message.contains('未登录') ||
        message.contains('登录失效') ||
        message.contains('forbidden');
  }

  String? _extractAuthMessage(String bodyText) {
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {}
    return null;
  }

  void _triggerAuthRedirect(String message) {
    if (_authRedirecting) return;
    _authRedirecting = true;
    HttpService().clearToken();
    NavigationService.showAuthExpiredMessage(message);
    NavigationService.toLoginAndClear();
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      _authRedirecting = false;
    });
  }
}
