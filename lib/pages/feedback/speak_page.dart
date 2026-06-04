import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
// import 'package:http_parser/http_parser.dart'; // For HttpDate.format
import 'package:medbot_ai_app/generated/l10n.dart';

class IflytekIatDemo extends StatefulWidget {
  const IflytekIatDemo({Key? key}) : super(key: key);

  @override
  _IflytekIatDemoState createState() => _IflytekIatDemoState();
}

/// 语音识别 WebSocket 调试页
///
/// - 握手：Header 携带 Authorization（与 HttpService 一致）
/// - 上行：二进制 PCM 分帧
/// - 下行：文本 JSON（intermediate/final/error）
class _IflytekIatDemoState extends State<IflytekIatDemo> {
  final String appId = '397dfc06';
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  WebSocketChannel? _channel;

  List<int> _audioBuffer = [];
  final int frameSize = 1280; // 每帧字节数，40ms音频

  late StreamController<Uint8List> _streamController;

  String recognizedText = '';

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
    _streamController = StreamController<Uint8List>();
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
  }

  String createUrl() {
    final baseUri = Uri.parse(HttpService().baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final wsPath = baseUri.path.endsWith('/')
        ? '${baseUri.path}ws/speech'
        : '${baseUri.path}/ws/speech';
    final uri = Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: wsPath,
    );
    return uri.toString();
  }

  Map<String, dynamic> createHeaders() {
    final token = HttpService().token;
    if (token == null || token.isEmpty) {
      throw Exception("Token is null. Please login first.");
    }
    return {
      'Authorization': 'Bearer $token',
      'X-Language': HttpService().languageCode,
    };
  }

  void _startRecognition() async {
    setState(() {
      recognizedText = '';
    });

    _audioBuffer.clear();
    _streamController = StreamController<Uint8List>(); // ✅ 关键：每次新建

    final url = createUrl();
    _channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: createHeaders(),
    );
    try {
      await _channel!.ready.timeout(const Duration(seconds: 5));
      debugPrint('Speech WebSocket connected: $url');
      _channel?.sink.add(
        json.encode({
          "header": {"app_id": appId},
          "payload": {
            "audio": {"sample_rate": 16000, "bit_depth": 16},
          },
        }),
      );
    } catch (e) {
      debugPrint('Speech WebSocket connect failed: $e');
      setState(() {
        recognizedText = e.toString();
      });
      return;
    }

    _channel!.stream.listen(_onMessage, onDone: _onDone, onError: _onError);

    _streamController.stream.listen((Uint8List data) {
      _audioBuffer.addAll(data);
      while (_audioBuffer.length >= frameSize) {
        var frame = _audioBuffer.sublist(0, frameSize);
        _audioBuffer.removeRange(0, frameSize);
        _sendAudioFrame(frame);
      }
    });

    await _recorder!.startRecorder(
      toStream: _streamController.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      _isRecording = true;
    });
  }

  void _sendAudioFrame(List<int> frame) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(Uint8List.fromList(frame));
  }

  void _stopRecognition() async {
    final channel = _channel;
    await _recorder!.stopRecorder();
    await _streamController.close(); // ✅ 确保资源释放
    if (channel != null) {
      final remaining = Uint8List.fromList(List<int>.from(_audioBuffer));
      _audioBuffer.clear();
      if (remaining.isNotEmpty) {
        for (int i = 0; i < remaining.length; i += frameSize) {
          final end = (i + frameSize) > remaining.length
              ? remaining.length
              : (i + frameSize);
          channel.sink.add(remaining.sublist(i, end));
        }
      }
      channel.sink.add(json.encode({"type": "end"}));
    }

    setState(() {
      _isRecording = false;
    });
  }

  void _onMessage(dynamic message) {
    try {
      final String textMessage = switch (message) {
        String s => s,
        List<int> bytes => utf8.decode(bytes),
        Uint8List bytes => utf8.decode(bytes),
        _ => message.toString(),
      };

      final Map<String, dynamic> msg = json.decode(textMessage);
      final String? type = msg['type']?.toString();

      if (type == 'intermediate' || type == 'final') {
        final String text = (msg['text'] ?? '').toString();
        setState(() {
          recognizedText = text;
        });
        if (type == 'final') {
          _channel?.sink.close();
        }
        return;
      }

      if (type == 'error') {
        final code = msg['code'];
        final String message = (msg['message'] ?? S.of(context).loadException)
            .toString();
        final String errorText = code == null ? message : '$code: $message';
        setState(() {
          recognizedText = errorText;
        });
        _channel?.sink.close();
        return;
      }
    } catch (e) {
      setState(() {
        recognizedText = e.toString();
      });
      _channel?.sink.close();
    }
  }

  void _onDone() {
    print(S.of(context).webSocketConnectionClosed);
  }

  void _onError(error) {
    print("${S.of(context).webSocketError}: $error");
    setState(() {
      recognizedText = S.of(context).loadException;
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _streamController.close();
    _recorder!.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).speak)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(recognizedText, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecognition : _startRecognition,
              child: Text(_isRecording ? S.of(context).stop : S.of(context).start),
            ),
          ],
        ),
      ),
    );
  }
}
