import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// 语音识别 WebSocket 客户端
///
/// - 握手：HTTP Header 携带 `Authorization: Bearer <token>`（与 HttpService 保持一致）
/// - 音频：按 16kHz/16bit/单声道 PCM，建议 1280 bytes/帧（二进制消息）
/// - 结束：发送文本消息 `{"type":"end"}`
/// - 下行：文本 JSON（type: intermediate/final/error）
class SpeechRecognizer {
  /// 服务端要求的应用标识（用于 start 配置消息里的 header.app_id）
  final String appId;

  /// 旧版讯飞直连参数（当前接入的是中台 WebSocket 服务，保留字段不参与请求）
  final String apiKey;

  /// 旧版讯飞直连参数（当前接入的是中台 WebSocket 服务，保留字段不参与请求）
  final String apiSecret;

  /// 每帧建议大小：1280 bytes（16kHz * 16bit * 单声道 => 40ms 音频）
  final int frameSize = 1280;

  /// 录音器：采集 PCM16、16kHz、单声道
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  /// 录音流控制器：FlutterSoundRecorder 会将采样数据写入该 sink
  StreamController<Uint8List>? _streamController;

  /// 分帧缓冲区：将连续 PCM 数据累计到 frameSize 后再发送
  final List<int> _audioBuffer = [];
  int _audioBufferReadIndex = 0;

  /// WebSocket 通道：与服务端实时传输音频与结果
  WebSocketChannel? _channel;

  /// WebSocket 订阅：监听服务端消息/关闭/错误
  StreamSubscription? _channelSubscription;

  /// 用于等待 WebSocket 关闭（stopRecognition 时最多等待 3 秒）
  Completer<void>? _channelDoneCompleter;

  /// WebSocket 是否 ready（握手完成后才允许发送 start / 音频 / end）
  bool _isWsReady = false;

  /// 识别结果回调（服务端 intermediate / final 都会走这里，保持原业务“持续出字”的用法）
  Function(String)? onResult;

  /// 开始录音/识别回调
  Function()? onStart;

  /// 停止录音/识别回调
  Function()? onStop;

  /// 错误回调（连接、协议、服务端 error）
  Function(String)? onError;

  /// 本地音频落盘后的回调（wav 文件路径 + 时长秒）
  Function(String path, int duration)? onAudioSaved;

  /// 本地录音的 PCM 文件（原始音频）
  late File _pcmFile;

  /// PCM 文件写入流
  late IOSink _fileSink;

  /// PCM 转换后的 WAV 文件路径（用于播放/上传）
  late String _wavFilePath;

  /// 订阅录音流（StreamController.stream）
  StreamSubscription<Uint8List>? _streamSubscription;

  /// stopRecognition 结束流程后置为 true，用于阻止继续发送帧
  bool _isClosed = false;

  /// stopRecognition 执行中标记，防止重入
  bool _isStopping = false;

  /// 是否处于识别中（用于避免重复 start）
  bool _isRecognizing = false;

  /// WebSocket 是否已关闭/不可用
  bool _isChannelClosed = false;

  /// 会话自动重连执行中标记,防止重入
  bool _isReconnecting = false;

  /// WebSocket 握手进行中标记:握手失败会刷新 token 重试,
  /// 期间的连接错误不上报 UI、不触发会话重连
  bool _isHandshaking = false;

  /// 构造器：外部传入回调用于 UI/业务层处理结果与状态
  SpeechRecognizer({
    required this.appId,
    required this.apiKey,
    required this.apiSecret,
    this.onResult,
    this.onStart,
    this.onStop,
    this.onError,
    this.onAudioSaved, // 新增
  });

  /// 初始化：配置音频会话 + 打开录音器
  Future<void> init() async {
    await _configureAudioSession();
    await _recorder.openRecorder();
  }

  /// 释放资源：停止识别、取消订阅、关闭录音器
  Future<void> dispose() async {
    await stopRecognition();
    await _channelSubscription?.cancel();
    await _recorder.closeRecorder();
  }

  /// 开始识别：
  /// 1) 重置状态与缓冲
  /// 2) 建立 WebSocket（带 Authorization）
  /// 3) 等待 ready 成功后发送 start 配置消息
  /// 4) 启动录音并把 PCM 流切帧后通过二进制消息发送
  Future<void> startRecognition() async {
    if (_isRecognizing) return;

    await _configureAudioSession();
    onStart?.call();
    await _streamSubscription?.cancel();
    await _channelSubscription?.cancel();
    _streamController = StreamController<Uint8List>();
    _audioBuffer.clear();
    _audioBufferReadIndex = 0;
    _isClosed = false;
    _isStopping = false;
    _isRecognizing = true;
    _isChannelClosed = false;
    _isWsReady = false;
    _channelDoneCompleter = Completer<void>();
    // 获取临时目录，落盘保存 PCM/WAV（用于后续播放/上传）
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final pcmPath = '${dir.path}/recording_$timestamp.pcm';
    _wavFilePath = '${dir.path}/recording_$timestamp.wav';

    _pcmFile = File(pcmPath);
    _fileSink = _pcmFile.openWrite();

    try {
      // 建立连接并等待握手(token 过期会自动刷新重试一次)
      await _connectChannel();
      if (_isClosed || _isStopping || _isChannelClosed) return;
      _isWsReady = true;
      _log('Speech WebSocket connected: ${_createUrl()}');

      // 握手成功后先发送 start 配置消息（服务端会校验字段）
      _sendStartMessage();
    } catch (e) {
      // ready 超时/失败通常是：URL 不可达、被网关返回 200 JSON（未走 Upgrade）、token 无效等
      _log('Speech WebSocket connect failed: $e');
      onError?.call(e.toString());
      _isRecognizing = false;
      _isStopping = false;
      _isClosed = true;
      await _closeChannel();
      await _channelSubscription?.cancel();
      _channelSubscription = null;
      _channel = null;
      if (_streamController != null && !(_streamController!.isClosed)) {
        await _streamController?.close();
      }
      _streamController = null;
      await _fileSink.close();
      return;
    }

    _streamSubscription = _streamController!.stream.listen((Uint8List data) {
      if (_isClosed || _isStopping) return;
      // 保存原始 PCM 数据到本地，便于后续转 WAV / 上传
      _fileSink.add(data);
      _audioBuffer.addAll(data);

      while (!_isClosed &&
          !_isStopping &&
          (_audioBuffer.length - _audioBufferReadIndex) >= frameSize) {
        // 累计到一帧大小后发送，模拟实时流式输入
        final frame = _audioBuffer.sublist(
          _audioBufferReadIndex,
          _audioBufferReadIndex + frameSize,
        );
        _audioBufferReadIndex += frameSize;
        _sendAudioFrame(Uint8List.fromList(frame));
      }

      if (_audioBufferReadIndex >= 8192) {
        _audioBuffer.removeRange(0, _audioBufferReadIndex);
        _audioBufferReadIndex = 0;
      }
    });

    // 启动录音：采样参数需与服务端协议一致（16kHz/16bit/单声道）
    await _recorder.startRecorder(
      toStream: _streamController!.sink,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );
  }

  /// 停止识别：
  /// 1) 停止录音、取消录音流订阅
  /// 2) 发送剩余音频并发送 end
  /// 3) 等待 WebSocket 正常关闭（最多 3 秒）
  /// 4) PCM 转 WAV、计算时长并回调 onAudioSaved
  Future<void> stopRecognition() async {
    if (!_isRecognizing || _isStopping) return;

    _isStopping = true;

    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }

    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _sendFinalFrame();

    _isClosed = true;
    if (_streamController != null && !(_streamController!.isClosed)) {
      await _streamController?.close();
    }
    _streamController = null;
    await _fileSink.close();

    final channelDone = _channelDoneCompleter;
    if (channelDone != null && !channelDone.isCompleted) {
      try {
        await channelDone.future.timeout(const Duration(seconds: 3));
      } catch (_) {
        await _closeChannel();
      }
    }

    await _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;

    await _convertPcmToWav(_pcmFile.path, _wavFilePath);

    final audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(_wavFilePath);
    final duration = audioPlayer.duration;
    int seconds =
        duration != null && duration.inSeconds > 0 ? duration.inSeconds : 1;
    await audioPlayer.dispose();

    onAudioSaved?.call(_wavFilePath, seconds);
    onStop?.call();
    await AudioSession.instance.then((session) => session.setActive(false));
    _isRecognizing = false;
    _isStopping = false;
    _audioBuffer.clear();
    _audioBufferReadIndex = 0;
    _channelDoneCompleter = null;
  }

  /// 配置音频会话：保证录音在 iOS/Android 上以“语音通话/口语”模式运行（含蓝牙/外放）
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  /// 发送音频帧（二进制消息）
  ///
  /// 注意：必须在 WebSocket ready 且已发送 start 配置后再发送音频，否则服务端可能直接报参数/状态错误。
  void _sendAudioFrame(Uint8List frame) {
    if (_isClosed || _isChannelClosed || _channel == null) {
      return;
    }

    if (_isStopping) {
      return;
    }
    if (!_isWsReady) {
      return;
    }

    try {
      _channel?.sink.add(frame);
    } catch (_) {
      _isChannelClosed = true;
    }
  }

  /// 停止前的收尾发送：
  /// - 把缓冲区中剩余的 PCM 数据按 frameSize 切片发送
  /// - 再发送文本消息 `{"type":"end"}` 告知服务端结束
  Future<void> _sendFinalFrame() async {
    if (_isChannelClosed || _channel == null) return;
    if (!_isWsReady) return;

    final remaining = Uint8List.fromList(
      List<int>.from(_audioBuffer.sublist(_audioBufferReadIndex)),
    );
    _audioBuffer.clear();
    _audioBufferReadIndex = 0;

    if (remaining.isNotEmpty) {
      for (int i = 0; i < remaining.length; i += frameSize) {
        if (_isChannelClosed || _channel == null) break;
        final end = (i + frameSize) > remaining.length
            ? remaining.length
            : (i + frameSize);
        final frame = remaining.sublist(i, end);
        try {
          _channel?.sink.add(frame);
        } catch (_) {
          _isChannelClosed = true;
          break;
        }
      }
    }

    if (_isChannelClosed || _channel == null) return;
    try {
      _channel?.sink.add(json.encode({"type": "end"}));
    } catch (_) {
      _isChannelClosed = true;
    }
  }

  /// 发送 start 配置消息（文本 JSON）
  ///
  /// 服务端字段要求为下划线命名：header.app_id、payload.audio.sample_rate、payload.audio.bit_depth。
  void _sendStartMessage() {
    if (_isClosed || _isChannelClosed || _channel == null) return;
    try {
      _channel?.sink.add(
        json.encode({
          "header": {"app_id": appId},
          "payload": {
            "audio": {"sample_rate": 16000, "bit_depth": 16},
          },
        }),
      );
    } catch (_) {
      _isChannelClosed = true;
    }
  }

  /// 处理服务端消息（文本 JSON）：
  /// - intermediate：中间结果
  /// - final：最终结果（收到后主动关闭 WebSocket）
  /// - error：服务端错误（回调 onError 后关闭 WebSocket）
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
        if (text.isNotEmpty) {
          onResult?.call(text);
        }
        if (type == 'final') {
          if (_isStopping || _isClosed) {
            _closeChannel();
          } else {
            // 讲话停顿触发服务端 VAD 判停、提前下发 final 并结束会话,
            // 但用户仍在录音:自动开启新会话继续识别,文本由 onResult 持续累加
            _restartSession();
          }
        }
        return;
      }

      if (type == 'error') {
        final code = msg['code'];
        final String message = (msg['message'] ?? 'Unknown error').toString();
        final String errorText = code == null ? message : '$code: $message';
        onError?.call(errorText);
        _closeChannel();
        return;
      }
    } catch (e) {
      // 兜底：解析 JSON 失败或字段异常时，直接回调错误并关闭连接
      _log('Error processing message: $e');
      onError?.call(e.toString());
      _closeChannel();
    }
  }

  /// WebSocket 正常关闭回调
  void _onDone() {
    // 进入回调时通道标记仍为 false,说明不是我们主动关闭(服务端断开,
    // 如单会话时长上限),录音未结束则重连续上;握手期失败由 _connectChannel 处理
    final unexpected =
        !_isChannelClosed && !_isStopping && !_isClosed && !_isHandshaking;
    _isChannelClosed = true;
    if (!(_channelDoneCompleter?.isCompleted ?? true)) {
      _channelDoneCompleter?.complete();
    }
    _log('WebSocket closed.');
    if (unexpected && _isRecognizing) {
      _restartSession();
    }
  }

  /// 建立 WebSocket 并等待握手完成。
  /// 握手失败最常见原因是 access token 过期——网关不升级协议、直接返回
  /// HTTP 200 JSON;此时刷新 token 后重试一次,重试期间不向 UI 报错。
  Future<void> _connectChannel() async {
    Future<void> attempt() async {
      _isChannelClosed = false;
      _isWsReady = false;
      _channelDoneCompleter = Completer<void>();
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_createUrl()),
        headers: _createHeaders(),
      );
      _channelSubscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );
      // 等待 WebSocket 握手完成；否则可能出现服务端未完成握手就收到数据/或直接返回 HTTP 200 JSON
      await _channel!.ready.timeout(const Duration(seconds: 5));
    }

    _isHandshaking = true;
    try {
      try {
        await attempt();
      } catch (e) {
        _log('WS handshake failed, refresh token and retry: $e');
        await _channelSubscription?.cancel();
        _channelSubscription = null;
        _channel = null;
        final refreshed = await HttpService().refreshAccessToken();
        if (!refreshed || _isClosed || _isStopping) rethrow;
        await attempt();
      }
    } finally {
      _isHandshaking = false;
    }
  }

  /// 录音过程中服务端结束了会话(final/断开):关闭旧通道并开启新会话,
  /// 让识别跟随录音继续。重连期间的音频帧会被丢弃(通常是触发判停的静音段)。
  Future<void> _restartSession() async {
    if (_isReconnecting || _isClosed || _isStopping) return;
    _isReconnecting = true;
    try {
      await _closeChannel();
      await _channelSubscription?.cancel();
      _channelSubscription = null;
      _channel = null;
      if (_isClosed || _isStopping) return;

      await _connectChannel();
      if (_isClosed || _isStopping) {
        await _closeChannel();
        return;
      }
      _isWsReady = true;
      _sendStartMessage();
      _log('Speech session restarted, recognition continues.');
    } catch (e) {
      _log('Speech session restart failed: $e');
      onError?.call(e.toString());
    } finally {
      _isReconnecting = false;
    }
  }

  /// WebSocket 发生异常回调
  void _onError(error) {
    _isChannelClosed = true;
    if (!(_channelDoneCompleter?.isCompleted ?? true)) {
      _channelDoneCompleter?.complete();
    }
    _log('WebSocket error: $error');
    // 握手期错误(如 token 过期被拒)由 _connectChannel 刷新重试,不上报 UI
    if (!_isHandshaking) {
      onError?.call(error.toString());
    }
  }

  /// 主动关闭 WebSocket（包含竞争条件下的重复 close 保护）
  Future<void> _closeChannel() async {
    if (_isChannelClosed) return;
    _isChannelClosed = true;
    try {
      await _channel?.sink.close();
    } catch (_) {
      // Ignore close races.
    }
    if (!(_channelDoneCompleter?.isCompleted ?? true)) {
      _channelDoneCompleter?.complete();
    }
  }

  /// 生成 WebSocket 地址：
  /// - 从 HttpService.baseUrl 推导 host/port/path
  /// - token 走 Header，不放在 query 参数里
  String _createUrl() {
    final token = HttpService().token;
    if (token == null || token.isEmpty) {
      throw Exception("Token is null. Please login first.");
    }

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

  /// 生成 WebSocket 握手 Header（与 HttpService 的 HTTP 请求方式保持一致）
  Map<String, dynamic> _createHeaders() {
    final token = HttpService().token;
    if (token == null || token.isEmpty) {
      throw Exception("Token is null. Please login first.");
    }

    return {
      'Authorization': 'Bearer $token',
      'X-Language': HttpService().languageCode,
    };
  }

  /// PCM 转 WAV：
  /// - 录音流保存的是裸 PCM，便于上传/处理
  /// - 为了本地播放与业务复用，这里手工写 WAV 头并拼接 PCM 数据
  Future<void> _convertPcmToWav(String pcmPath, String wavPath) async {
    final pcmFile = File(pcmPath);
    final pcmData = await pcmFile.readAsBytes();

    final wavFile = File(wavPath);
    final wavSink = wavFile.openWrite();

    int sampleRate = 16000;
    int numChannels = 1;
    int byteRate = sampleRate * numChannels * 2; // 16-bit = 2 bytes

    // WAV header
    List<int> header = [
      ...ascii.encode('RIFF'),
      ..._intToBytes(36 + pcmData.length, 4),
      ...ascii.encode('WAVE'),
      ...ascii.encode('fmt '),
      ..._intToBytes(16, 4),
      ..._intToBytes(1, 2), // PCM format
      ..._intToBytes(numChannels, 2),
      ..._intToBytes(sampleRate, 4),
      ..._intToBytes(byteRate, 4),
      ..._intToBytes(numChannels * 2, 2), // block align
      ..._intToBytes(16, 2), // bits per sample
      ...ascii.encode('data'),
      ..._intToBytes(pcmData.length, 4),
    ];

    wavSink.add(Uint8List.fromList(header));
    wavSink.add(pcmData);
    await wavSink.close();
  }

  /// 小端序整数转字节数组（用于 WAV 头字段）
  List<int> _intToBytes(int value, int byteCount) {
    final result = <int>[];
    for (int i = 0; i < byteCount; i++) {
      result.add((value >> (8 * i)) & 0xFF);
    }
    return result;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SpeechRecognizer] $message');
    }
  }
}
