// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class HttpService {
//   static final HttpService _instance = HttpService._internal();

//   factory HttpService() => _instance;

//   HttpService._internal();

//   final String _baseUrl = 'http://139.196.125.119:8080/api/app/'; // 替换为你的 API 地址
//   String? _token;

//   /// 设置 token
//   void setToken(String token) {
//     _token = token;
//   }

//   /// 清除 token
//   void clearToken() {
//     _token = null;
//   }

//   Map<String, String> _headers({Map<String, String>? extraHeaders}) {
//     final headers = {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (_token != null) 'Authorization': 'Bearer $_token',
//       ...?extraHeaders,
//     };
//     return headers;
//   }

//   Future<http.Response> get(
//     String endpoint, {
//     Map<String, String>? params,
//   }) async {
//     final uri = Uri.parse(
//       '$_baseUrl$endpoint',
//     ).replace(queryParameters: params);
//     final response = await http.get(uri, headers: _headers());
//     _handleError(response);
//     return response;
//   }

//   Future<http.Response> post(String endpoint, {dynamic body}) async {
//     final uri = Uri.parse('$_baseUrl$endpoint');
//     final response = await http.post(
//       uri,
//       headers: _headers(),
//       body: jsonEncode(body),
//     );
//     _handleError(response);
//     return response;
//   }

//   Future<http.Response> put(String endpoint, {dynamic body}) async {
//     final uri = Uri.parse('$_baseUrl$endpoint');
//     final response = await http.put(
//       uri,
//       headers: _headers(),
//       body: jsonEncode(body),
//     );
//     _handleError(response);
//     return response;
//   }

//   Future<http.Response> delete(String endpoint, {dynamic body}) async {
//     final uri = Uri.parse('$_baseUrl$endpoint');
//     final response = await http.delete(
//       uri,
//       headers: _headers(),
//       body: jsonEncode(body),
//     );
//     _handleError(response);
//     return response;
//   }

//   /// 可选：处理 HTTP 错误
//   void _handleError(http.Response response) {
//     if (response.statusCode >= 400) {
//       throw HttpException(response.statusCode, response.body);
//     }
//   }
// }

// /// 自定义异常类
// class HttpException implements Exception {
//   final int _statusCode;
//   final String message;

//   HttpException(this._statusCode, this.message);

//   @override
//   String toString() => 'HttpException: [$_statusCode] $message';

//   int? get statusCode => _statusCode;
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medbot_ai_app/utils/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();

  factory HttpService() => _instance;

  HttpService._internal();

  final String _baseUrl = 'http://210.22.113.78:32899/microport-management/app/'; // 替换为你的 API 地址
  String get baseUrl => _baseUrl;

  String? _token;
  String? _refreshToken;
  Future<bool>? _refreshing;
  String _languageCode = 'en'; // 默认语言为英文
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  /// 设置 token
  void setToken(String token) {
    _token = token;
  }

  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  /// 清除 token
  void clearToken() {
    _token = null;
    _refreshToken = null;
  }

  /// 设置语言代码
  void setLanguage(String languageCode) {
    _languageCode = languageCode;
  }

  /// 获取当前语言代码
  String get languageCode => _languageCode;

  Map<String, String> _headers({Map<String, String>? extraHeaders}) {
    print("_token: Bearer $_token");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Language': _languageCode, // 添加语言请求头，默认为英文
      if (_token != null) 'Authorization': 'Bearer $_token',
      ...?extraHeaders,
    };
    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse(
        '$_baseUrl$endpoint',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());
      print("response: ${response.body}");
      return response;
    });
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      print("response: ${response.body}");
      print("uri: $uri");
      return response;
    });
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _headers(),
        body: jsonEncode(body),
      );
      return response;
    });
  }

  Future<http.Response> delete(String endpoint, {dynamic body}) async {
    return _sendWithRetry(() async {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response =
          body == null
              ? await http.delete(uri, headers: _headers())
              : await http.delete(
                uri,
                headers: _headers(),
                body: jsonEncode(body),
              );
      return response;
    });
  }

  /// 新增：支持 multipart/form-data 上传附件
  Future<http.StreamedResponse> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<File>? files,
    String fileFieldName = 'files',
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // 添加 Header（Authorization 和 X-Language）
    request.headers['X-Language'] = _languageCode; // 添加语言请求头，默认为英文
    request.headers['Accept'] = 'application/json';
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // 添加普通字段
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // 添加文件
    if (files != null) {
      for (final file in files) {
        final mimeType = _getMimeType(file.path);
        final fileName = file.path.split('/').last;

        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path,
            filename: fileName,
            contentType: mimeType,
          ),
        );
      }
    }

    final response = await request.send();
    if (response.statusCode >= 400) {
      final responseBody = await response.stream.bytesToString();
      throw HttpException(response.statusCode, responseBody);
    }

    final responseBody = await response.stream.bytesToString();
    Map<String, dynamic>? decoded;
    try {
      final any = jsonDecode(responseBody);
      if (any is Map<String, dynamic>) decoded = any;
    } catch (_) {}

    final status = decoded?['status'];
    if (status == 10506) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        _handleAuthError(_getErrorMessageFromJson(decoded) ?? responseBody);
        throw HttpException(401, _getErrorMessageFromJson(decoded) ?? responseBody);
      }

      final retryRequest = http.MultipartRequest('POST', uri);
      retryRequest.headers['X-Language'] = _languageCode;
      retryRequest.headers['Accept'] = 'application/json';
      if (_token != null) {
        retryRequest.headers['Authorization'] = 'Bearer $_token';
      }
      if (fields != null) {
        retryRequest.fields.addAll(fields);
      }
      if (files != null) {
        for (final file in files) {
          final mimeType = _getMimeType(file.path);
          final fileName = file.path.split('/').last;
          retryRequest.files.add(
            await http.MultipartFile.fromPath(
              fileFieldName,
              file.path,
              filename: fileName,
              contentType: mimeType,
            ),
          );
        }
      }
      return await retryRequest.send();
    }

    if (status == 10507) {
      _handleAuthError(_getErrorMessageFromJson(decoded) ?? responseBody);
      throw HttpException(401, _getErrorMessageFromJson(decoded) ?? responseBody);
    }

    if (decoded != null && status is int && status != 200) {
      final message = _getErrorMessageFromJson(decoded) ?? responseBody;
      throw HttpException(400, message);
    }

    final bytes = utf8.encode(responseBody);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([bytes]),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      contentLength: bytes.length,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      request: response.request,
    );
  }

  /// 根据文件后缀推断 MIME 类型
  MediaType _getMimeType(String path) {
    final normalizedPath = path.toLowerCase();

    if (normalizedPath.endsWith(".jpg") || normalizedPath.endsWith(".jpeg")) {
      return MediaType("image", "jpeg");
    } else if (normalizedPath.endsWith(".png")) {
      return MediaType("image", "png");
    } else if (normalizedPath.endsWith(".gif")) {
      return MediaType("image", "gif");
    } else if (normalizedPath.endsWith(".heic")) {
      return MediaType("image", "heic");
    } else if (normalizedPath.endsWith(".mp4")) {
      return MediaType("video", "mp4");
    } else if (normalizedPath.endsWith(".mov")) {
      return MediaType("video", "quicktime");
    } else if (normalizedPath.endsWith(".avi")) {
      return MediaType("video", "x-msvideo");
    } else if (normalizedPath.endsWith(".wav")) {
      return MediaType("application", "octet-stream");
    } else if (normalizedPath.endsWith(".aac")) {
      return MediaType("audio", "aac");
    } else if (normalizedPath.endsWith(".m4a")) {
      return MediaType("audio", "mp4");
    }
    return MediaType("application", "octet-stream");
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    final handled = await _handleResponseForRetry(response);
    if (handled != null) return handled;

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      final message = _getErrorMessage(response);
      _handleAuthError(message);
      throw HttpException(response.statusCode, message);
    }

    final retryResponse = await request();
    final retryHandled = await _handleResponseForRetry(retryResponse);
    if (retryHandled != null) return retryHandled;

    final message = _getErrorMessage(retryResponse);
    if (_isAuthInvalid(retryResponse)) {
      _handleAuthError(message);
    }
    throw HttpException(retryResponse.statusCode, message);
  }

  Future<http.Response?> _handleResponseForRetry(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return null;
    }

    Map<String, dynamic>? body;
    try {
      final any = jsonDecode(response.body);
      if (any is Map<String, dynamic>) body = any;
    } catch (_) {}

    final status = body?['status'];
    if (status == null) {
      if (response.statusCode >= 400) {
        throw HttpException(response.statusCode, response.body);
      }
      return response;
    }

    if (status == 200) return response;

    final message = _getErrorMessageFromJson(body) ?? response.body;

    if (status == 10506) {
      return null;
    }

    if (status == 10507) {
      _handleAuthError(message);
      throw HttpException(response.statusCode, message);
    }

    throw HttpException(response.statusCode, message);
  }

  bool _isAuthInvalid(http.Response response) {
    try {
      final any = jsonDecode(response.body);
      if (any is Map<String, dynamic>) {
        final status = any['status'];
        return status == 10507;
      }
    } catch (_) {}
    return response.statusCode == 401 || response.statusCode == 403;
  }

  String? _getErrorMessageFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final message = json['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    return null;
  }

  String _getErrorMessage(http.Response response) {
    try {
      final any = jsonDecode(response.body);
      if (any is Map<String, dynamic>) {
        return _getErrorMessageFromJson(any) ?? "Unknown error occurred";
      }
      return "Unknown error occurred";
    } catch (_) {
      return "Failed to parse error response";
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshing != null) return await _refreshing!;
    final future = _doRefreshAccessToken();
    _refreshing = future;
    try {
      return await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> refreshAccessToken() async {
    return _refreshAccessToken();
  }

  Future<bool> _doRefreshAccessToken() async {
    final refreshToken = _refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final uri = Uri.parse('$_baseUrl${'auth/refresh'}');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Language': _languageCode,
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    Map<String, dynamic>? body;
    try {
      final any = jsonDecode(response.body);
      if (any is Map<String, dynamic>) body = any;
    } catch (_) {}

    final status = body?['status'];
    if (status == 200) {
      final data = body?['data'];
      if (data is Map<String, dynamic>) {
        final accessToken = data['accessToken']?.toString().trim();
        final nextRefreshToken = data['refreshToken']?.toString().trim();
        if (accessToken != null && accessToken.isNotEmpty) {
          _token = accessToken;
          if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
            _refreshToken = nextRefreshToken;
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          if (_refreshToken != null && _refreshToken!.isNotEmpty) {
            await prefs.setString('refreshToken', _refreshToken!);
          }
          return true;
        }
      }
      return false;
    }

    if (status == 10507) {
      _handleAuthError(_getErrorMessageFromJson(body) ?? 'Token无效');
      return false;
    }

    return false;
  }

  void _handleAuthError(String errorMessage) {
    print(errorMessage);

    clearToken();
    Future<void>.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refreshToken');
    });
    NavigationService.showAuthExpiredMessage(errorMessage);
    NavigationService.toLoginAndClear();
  }
}

/// 自定义异常类
class HttpException implements Exception {
  final int _statusCode;
  final String message;

  HttpException(this._statusCode, this.message);

  @override
  String toString() => 'HttpException: [$_statusCode] $message';

  int get statusCode => _statusCode;
}
