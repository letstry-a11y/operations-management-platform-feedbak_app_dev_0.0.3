import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medbot_ai_app/utils/chat_stream_client.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/utils/speech_recognizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:medbot_ai_app/widgets/network_attachment_preview.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/widgets/video_play.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_compress/video_compress.dart';

const _brandColor = Color(0xFF042A72);
const _accentColor = Color(0xFF12A594);
const _pageBackground = Color(0xFFF6F8FB);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF697386);
const _borderColor = Color(0xFFD8DEE9);

class _UploadedAttachmentResult {
  const _UploadedAttachmentResult({
    required this.attachmentId,
    required this.presignedUrl,
    required this.filename,
    required this.fileType,
  });

  final int attachmentId;
  final String? presignedUrl;
  final String? filename;
  final int? fileType;
}

// 产品选项和反馈类型选项将在 build 方法中动态生成

class FeedbackEditPage extends StatefulWidget {
  const FeedbackEditPage({super.key});
  @override
  State<FeedbackEditPage> createState() => _FeedbackEditPageState();
}

class _FeedbackEditPageState extends State<FeedbackEditPage>
    with TickerProviderStateMixin {
  // 表单验证key
  final _formKey = GlobalKey<FormState>();
  // 标题输入框控制器
  final _titleController = TextEditingController();
  // 描述输入框控制器
  final _descriptionController = TextEditingController();

  // 用于管理键盘显示的焦点节点
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  // 产品相关参数
  String? productId; // 产品ID
  String? feedbackType; // 反馈类型（1:缺陷反馈, 2:需求反馈, 3:其他反馈）
  String? feedbackTypeText; // 反馈类型文本显示
  String? productText; // 产品文本显示
  bool _isParamsLoaded = false; // 参数是否已加载（防止重复加载）
  late String issueId; // 反馈问题ID
  String? _deviceUdi;

  // 时间选择相关
  DateTime? _selectedDateTime; // 选中的日期时间

  // 附件相关
  List<MediaItem> attachmentsMedia = []; // 网络附件列表

  // 音频录制和播放器
  FlutterSoundRecorder? _recorder; // 录音器
  FlutterSoundPlayer? _player; // 播放器

  // 语音文件路径
  String? _voicePathTitle; // 标题语音文件路径
  String? _voicePathDescription; // 描述语音文件路径
  int? _voiceAttachmentIdTitle;
  int? _voiceAttachmentIdDescription;

  // 语音时长
  int? _voiceDurationTitle; // 标题语音时长（秒）
  int? _voiceDurationDescription; // 描述语音时长（秒）

  // 录音和播放状态
  bool _isRecordingTitle = false; // 是否正在录制标题语音
  bool _isRecordingDescription = false; // 是否正在录制描述语音
  bool _isPlaying = false; // 是否正在播放
  bool _isSubmitting = false; // 是否正在提交
  String? _playingPath; // 正在播放的音频路径

  // 麦克风按钮动画控制器
  late AnimationController _micAnimationTitle; // 标题麦克风动画
  late AnimationController _micAnimationDescription; // 描述麦克风动画

  // 科大讯飞语音识别配置
  final String appId = '397dfc06';
  final String apiKey = '';
  final String apiSecret = '';

  // AI问答接口客户端
  late final ChatStreamClient client;
  bool _isRecognizing = false; // 是否正在识别语音并调用问答接口
  // 语音识别类型（'title' 或 'description'）
  String _speechRecognizerType = "";

  // 用于节流流式输出的缓冲区，减少重建和GC
  final StringBuffer _descBuffer = StringBuffer(); // 描述文本缓冲区
  Timer? _flushTimer; // 刷新定时器
  final Duration _flushInterval = const Duration(milliseconds: 120); // 刷新间隔

  // 缓存最新识别结果，直到录音停止
  String _recognizedDescription = ''; // 识别的描述文本

  // 自动停止录音的时长限制（秒）
  static const int _maxRecordSeconds = 50; // 在50秒时停止，以保持在60秒API限制内
  Timer? _recordTimeoutTimer; // 录音超时定时器

  SpeechRecognizer? _speechRecognizer; // 语音识别器
  @override
  void initState() {
    super.initState();
    final baseUrl = HttpService().baseUrl;
    final normalizedBaseUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    client = ChatStreamClient(serverUrl: normalizedBaseUrl);
    // 初始化录音器和播放器
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    // 初始化音频功能（请求权限等）
    _initAudio();

    // 添加焦点监听器，用于键盘管理
    _titleFocusNode.addListener(_onTitleFocusChange);
    _descriptionFocusNode.addListener(_onDescriptionFocusChange);

    // 初始化标题麦克风按钮动画控制器（呼吸效果）
    _micAnimationTitle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true); // 循环反向播放，形成呼吸动画

    // 初始化描述麦克风按钮动画控制器（呼吸效果）
    _micAnimationDescription = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true); // 循环反向播放，形成呼吸动画

    // 初始化科大讯飞语音识别器
    _speechRecognizer = SpeechRecognizer(
      appId: appId,
      apiKey: apiKey,
      apiSecret: apiSecret,
      // 语音识别结果回调
      onResult: (text) {
        if (_speechRecognizerType == 'title') {
          // 标题识别：直接更新标题输入框
          _titleController.text = text;
        } else {
          // 描述识别：仅缓存识别文本，等录音停止(onAudioSaved)后再触发问答接口
          if (text.isNotEmpty) {
            _recognizedDescription += text;
          } else {
            // 识别内容为空，提示用户重新输入
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).contentEmptyPleaseReenter)),
            );
          }
        }
      },
      // 录音开始回调
      onStart: () {
        // setState(() => _isRecordingTitle = true);
      },
      // 录音停止回调
      onStop: () {
        // setState(() => _isRecordingTitle = false);
      },
      // 识别错误回调
      onError:
          (e) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${S.of(context).recognitionError}: $e')),
          ),
      // 音频保存成功回调（录音完成后触发）
      onAudioSaved: (path, duration) {
        // 更新录音状态和保存音频路径
        setState(() {
          if (_speechRecognizerType == 'title') {
            _isRecordingTitle = false; // 停止标题录音状态
            _voicePathTitle = path; // 保存标题语音文件路径
            _voiceDurationTitle = duration; // 保存标题语音时长
          } else {
            _isRecordingDescription = false; // 停止描述录音状态
            _voicePathDescription = path; // 保存描述语音文件路径
            _voiceDurationDescription = duration; // 保存描述语音时长
          }
        });
        _uploadVoiceAttachment(path, _speechRecognizerType);
        // 仅在描述录音完成后，使用缓存的识别结果触发问答接口
        if (_speechRecognizerType == 'description' &&
            _recognizedDescription.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isRecognizing = true; // 设置识别中状态，禁止再次录音
              _descriptionController.text = ''; // 清空描述输入框，准备接收AI回答
            });
          }
          // 调用AI问答接口，使用慢流方式减少UI刷新频率
          slowStream(
            client.askQuestion(
              _recognizedDescription,
              token: HttpService().token,
            ),
          ).listen(
            // 接收AI返回的流式文本
            (word) {
              // 将单词写入缓冲区
              _descBuffer.write(word);
              // 如果定时器不存在或未激活，创建新的定时器来批量更新UI
              if (_flushTimer == null || !_flushTimer!.isActive) {
                _flushTimer = Timer(_flushInterval, () {
                  if (!mounted) return;
                  // 批量更新描述输入框，减少重建频率
                  _descriptionController.text += _descBuffer.toString();
                  _descBuffer.clear(); // 清空缓冲区
                });
              }
            },
            // 问答接口错误处理
            onError: (e) {
              if (mounted) {
                setState(() {
                  // 如果AI回答失败，使用原始识别的文本
                  _descriptionController.text = _recognizedDescription;
                  _isRecognizing = false; // 结束识别状态
                });
              }
            },
            // 问答接口完成回调
            onDone: () {
              // 处理缓冲区中剩余的文本
              if (_descBuffer.isNotEmpty) {
                _descriptionController.text += _descBuffer.toString();
                _descBuffer.clear();
              }
              if (mounted) {
                setState(() {
                  _isRecognizing = false; // 结束识别状态，允许再次录音
                  _recognizedDescription = ''; // 清空识别的描述文本缓存
                });
              }
            },
          );
        }
      },
    );
    _speechRecognizer!.init();
  }

  /// 标题输入框焦点变化处理
  void _onTitleFocusChange() {
    if (_titleFocusNode.hasFocus) {
      // 当标题输入框获得焦点时，强制显示键盘
      _showKeyboard();
    }
  }

  /// 描述输入框焦点变化处理
  void _onDescriptionFocusChange() {
    if (_descriptionFocusNode.hasFocus) {
      // 当描述输入框获得焦点时，强制显示键盘
      _showKeyboard();
    }
  }

  /// 强制显示键盘（解决某些设备上键盘不弹出的问题）
  void _showKeyboard() {
    if (!mounted) return;

    // 确保在下一帧后执行，让焦点先设置完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 方法1：延迟后通过系统通道强制显示键盘
      Future.delayed(Duration(milliseconds: 150), () {
        if (!mounted) return;
        try {
          // 通过系统通道尝试显示键盘
          SystemChannels.textInput.invokeMethod('TextInput.show').catchError((
            e,
          ) {
            debugPrint('TextInput.show failed: $e');
          });
        } catch (e) {
          debugPrint('Force show keyboard exception: $e');
        }
      });

      // 方法2：再次延迟尝试（有些设备需要更长时间）
      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput
              .invokeMethod('TextInput.show')
              .catchError((_) {});
        } catch (e) {
          // 忽略第二次尝试的错误
        }
      });
    });
  }

  /// 隐藏键盘（通过移除所有输入框的焦点）
  void _hideKeyboard() {
    if (!mounted) return;
    // 移除当前焦点，隐藏键盘
    FocusScope.of(context).unfocus();
    // 同时尝试通过系统通道隐藏键盘
    try {
      SystemChannels.textInput
          .invokeMethod('TextInput.hide')
          .catchError((_) {});
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 只加载一次参数，防止重复调用
    if (!_isParamsLoaded) {
      // 从路由参数中获取反馈问题ID
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        issueId = args; // 保存问题ID
        // 获取反馈详情数据
        fetchFeedbackDetail(issueId);
      } else {
        // 缺少问题ID，显示错误并返回上一页
        ToastUtils.showError(context, S.of(context).missingIssueId);
        Navigator.pop(context);
      }

      _isParamsLoaded = true; // 标记参数已加载，防止多次调用
    }
  }

  /// 获取反馈详情数据
  /// [id] 反馈问题ID
  Future<void> fetchFeedbackDetail(String id) async {
    try {
      final response = await HttpService().get(
        'feedback/$id',
        // params: {'id': id},
      );
      final result = jsonDecode(response.body);
      if (!mounted) return;
      if (result["status"] == 200) {
        final data = result['data'];
        if (data is! Map<String, dynamic>) {
          ToastUtils.showError(context, S.of(context).loadFailed);
          Navigator.pop(context);
          return;
        }

        _titleController.text = data['title']?.toString() ?? '';
        _descriptionController.text = data['description']?.toString() ?? '';
        _deviceUdi = data['deviceUdi']?.toString().trim();

        final titleAudioId = data['titleAudio']?.toString().trim() ?? '';
        final descriptionAudioId =
            data['descriptionAudio']?.toString().trim() ?? '';
        final excludedAttachmentIds = <String>{
          if (titleAudioId.isNotEmpty) titleAudioId,
          if (descriptionAudioId.isNotEmpty) descriptionAudioId,
        };

        final attachmentsRaw = data['attachments'];
        final nextAttachments =
            attachmentsRaw is List
                ? attachmentsRaw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .map<MediaItem>((item) {
                      final rawUrl = item['presignedUrl']?.toString();
                      final url =
                          rawUrl == null
                              ? null
                              : rawUrl.replaceAll('`', '').trim();
                      final fileTypeValue = item['fileType'];
                      final fileType =
                          fileTypeValue is int
                              ? fileTypeValue
                              : int.tryParse(fileTypeValue?.toString() ?? '');
                      final type =
                          fileType == 1
                              ? 'image'
                              : fileType == 2
                              ? 'audio'
                              : fileType == 3
                              ? 'video'
                              : 'file';
                      return MediaItem(
                        url: url,
                        type: type,
                        id: item['id']?.toString(),
                      );
                    })
                    .where((item) => item.type != 'audio')
                    .where((item) => (item.url ?? '').isNotEmpty)
                    .where(
                      (item) =>
                          !excludedAttachmentIds.contains(item.id?.trim() ?? ''),
                    )
                    .toList()
                : <MediaItem>[];

        setState(() {
          attachmentsMedia = nextAttachments;
          feedbackType = data['feedbackType']?.toString();
          productId = data['deviceType']?.toString();
          _selectedDateTime = _parseServerDateTime(
            data['occurTime']?.toString(),
          );
          _voiceAttachmentIdTitle = int.tryParse(titleAudioId);
          _voiceAttachmentIdDescription = int.tryParse(descriptionAudioId);
        });
      } else {
        ToastUtils.showError(
          context,
          result["message"] ?? S.of(context).loadFailed,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Load feedback edit data failed: $e");
      if (!mounted) return;
      ToastUtils.showError(context, S.of(context).loadException);
      Navigator.pop(context);
    }
  }

  DateTime? _parseServerDateTime(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw);
    } catch (_) {
      return null;
    }
  }

  bool _isVideoFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return const {'mp4', 'mov', 'avi', 'webm', 'mkv'}.contains(ext);
  }

  String _videoTranscodingLabel(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang.startsWith('zh')) return '正在转码为 H.264...';
    return 'Transcoding to H.264...';
  }

  Future<File> _transcodeVideoIfNeeded(
    File file, {
    void Function(String text, double? progress)? onProgress,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return file;
    final ext = file.path.split('.').last.toLowerCase();
    const videoExts = {'mp4', 'mov', 'avi', 'webm', 'mkv'};
    if (!videoExts.contains(ext)) return file;

    File candidate = file;
    try {
      onProgress?.call(S.of(context).videoCompressing, 0);
      dynamic sub;
      try {
        sub = VideoCompress.compressProgress$.subscribe((raw) {
          final numeric = raw is num ? raw.toDouble() : 0.0;
          final normalized = numeric > 1 ? (numeric / 100).clamp(0.0, 1.0) : numeric;
          onProgress?.call(S.of(context).videoCompressing, normalized);
        });
        final mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          includeAudio: true,
          deleteOrigin: false,
        );
        final outputPath = mediaInfo?.path;
        if (outputPath == null || outputPath.isEmpty) return candidate;
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          candidate = outputFile;
        }
      } finally {
        sub?.unsubscribe();
      }
    } catch (_) {
    }
    return candidate;
  }

  Future<_UploadedAttachmentResult> _uploadAttachmentFile(
    File file, {
    void Function(String text, double? progress)? onVideoProgress,
  }) async {
    final fileToUpload = await _transcodeVideoIfNeeded(
      file,
      onProgress: onVideoProgress,
    );
    if (onVideoProgress != null && _isVideoFile(file)) {
      onVideoProgress(S.of(context).uploading, null);
    }
    final response = await HttpService().postMultipart(
      'feedback/attachments',
      files: [fileToUpload],
      fileFieldName: 'file',
    );
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody);
    if (json is! Map<String, dynamic>) {
      throw Exception('Invalid upload response');
    }
    final status = json['status'];
    if (status is! int || status != 200) {
      final message = json['message'];
      throw Exception(
        message is String && message.isNotEmpty ? message : status,
      );
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid upload data');
    }
    final attachmentId = data['attachmentId'];
    if (attachmentId is! int) {
      throw Exception('Missing attachmentId');
    }
    return _UploadedAttachmentResult(
      attachmentId: attachmentId,
      presignedUrl:
          data['presignedUrl'] is String
              ? data['presignedUrl'] as String
              : null,
      filename: data['filename'] is String ? data['filename'] as String : null,
      fileType: data['fileType'] is int ? data['fileType'] as int : null,
    );
  }

  String _mediaTypeFromFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(ext) ? 'image' : 'video';
  }

  Future<T> _runWithVideoProgressDialog<T>({
    String? initialText,
    required Future<T> Function(void Function(String, double?)) task,
  }) async {
    StateSetter? dialogSetState;
    String text = initialText ?? S.of(context).videoCompressing;
    double? progress;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              dialogSetState = setState;
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 14),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${(progress! * 100).round()}%',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    try {
      return await task((nextText, nextProgress) {
        if (!mounted) return;
        dialogSetState?.call(() {
          text = nextText;
          progress = nextProgress;
        });
      });
    } finally {
      if (mounted) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
      }
    }
  }

  Future<void> _addPickedFiles(List<File> files) async {
    for (final file in files) {
      try {
        final result = await _runWithVideoProgressDialog<_UploadedAttachmentResult>(
          initialText:
              _isVideoFile(file) ? S.of(context).videoCompressing : S.of(context).uploading,
          task: (onProgress) async {
            return _uploadAttachmentFile(file, onVideoProgress: onProgress);
          },
        );
        if (!mounted) return;
        final url =
            result.presignedUrl == null
                ? null
                : result.presignedUrl!.replaceAll('`', '').trim();
        setState(() {
          attachmentsMedia.add(
            MediaItem(
              file: file,
              url: url,
              id: result.attachmentId.toString(),
              type: _mediaTypeFromFile(file),
            ),
          );
        });
      } catch (e) {
        if (!mounted) return;
        ToastUtils.showError(context, '${S.of(context).uploadFailed}: $e');
      }
    }
  }

  Future<void> _uploadVoiceAttachment(String path, String target) async {
    final file = File(path);
    if (!await file.exists()) return;

    if (!mounted) return;
    setState(() {
      if (target == 'title') {
        _voiceAttachmentIdTitle = null;
      } else {
        _voiceAttachmentIdDescription = null;
      }
    });

    try {
      final result = await _uploadAttachmentFile(file);
      if (!mounted) return;
      setState(() {
        if (target == 'title') {
          _voiceAttachmentIdTitle = result.attachmentId;
        } else {
          _voiceAttachmentIdDescription = result.attachmentId;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, '${S.of(context).uploadFailed}: $e');
    }
  }

  Future<void> _removeVoiceAttachment(String target) async {
    final path = target == 'title' ? _voicePathTitle : _voicePathDescription;

    if (path != null && _playingPath == path) {
      try {
        await _player?.stopPlayer();
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      if (target == 'title') {
        _voicePathTitle = null;
        _voiceDurationTitle = null;
        _voiceAttachmentIdTitle = null;
      } else {
        _voicePathDescription = null;
        _voiceDurationDescription = null;
        _voiceAttachmentIdDescription = null;
      }
      if (_playingPath == path) {
        _isPlaying = false;
        _playingPath = null;
      }
    });
  }

  List<Map<String, dynamic>> get productOptions {
    return [
      {"label": S.of(context).all, "value": "100"},
      {"label": S.of(context).tumaiMultiPort, "value": "101"},
      {"label": S.of(context).tumaiSinglePort, "value": "102"},
      {"label": S.of(context).dragonflyEye, "value": "103"},
      {"label": S.of(context).honghu, "value": "104"},
      {"label": S.of(context).rone, "value": "105"},
      {"label": S.of(context).monaLisa, "value": "106"},
      {"label": S.of(context).other, "value": "107"},
    ];
  }

  List<Map<String, dynamic>> get feedbackTypes {
    return [
      {"label": S.of(context).defectFeedback, "value": "1"},
      {"label": S.of(context).requirementFeedback, "value": "2"},
      {"label": S.of(context).otherFeedback, "value": "3"},
    ];
  }

  String getProductLabel(String productId) {
    return productOptions.firstWhere(
      (item) => item['value'] == productId,
      orElse: () => {'label': S.of(context).unknown},
    )['label'];
  }

  String getFeedbackTypeLabel(String? type) {
    return feedbackTypes.firstWhere(
      (item) => item['value'] == type,
      orElse: () => {'label': S.of(context).unknownType},
    )['label'];
  }

  /// 慢速流式输出（用于减少UI刷新频率和GC压力）
  Stream<String> slowStream(Stream<String> input) async* {
    await for (final word in input) {
      yield word;
      // 稍微延迟以减少UI刷新频率和GC压力
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  /// 初始化音频功能（请求录音权限）
  Future<void> _initAudio() async {
    try {
      var microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus.isDenied) {
        microphoneStatus = await Permission.microphone.request();
      }
      if (!mounted) return;
      if (microphoneStatus.isGranted) {
        await _recorder!.openRecorder();
        await _player!.openPlayer();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('需要录音权限才能使用语音功能')));
      }
    } catch (e) {
      // ignore
    }
  }

  /// 开始录音
  /// [target] 录音目标：'title' 标题 或 'description' 描述
  Future<void> _startRecording(String target) async {
    // 如果在问答接口调用过程中，禁止描述模块的录音，但允许标题模块录音
    if (_isRecognizing && target == 'description') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).voiceRecognizingHint)),
      );
      return;
    }
    if (_isRecordingTitle || _isRecordingDescription) {
      // 说明当前已经存在正在录制的声音
      // _stopRecording(_speechRecognizerType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).currentlyRecognizing),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.pinkAccent.withAlpha(230),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    _speechRecognizer?.startRecognition();
    setState(() {
      if (target == 'title') {
        _isRecordingTitle = true;
      } else {
        _isRecordingDescription = true;
      }
      _speechRecognizerType = target;
    });

    // Auto-stop after 50s with notice
    _recordTimeoutTimer?.cancel();
    _recordTimeoutTimer = Timer(Duration(seconds: _maxRecordSeconds), () async {
      if (!mounted) return;
      final isStill =
          (target == 'title' && _isRecordingTitle) ||
          (target == 'description' && _isRecordingDescription);
      if (isStill) {
        await _stopRecording(target);
        if (!mounted) return;
        final isZh = Localizations.localeOf(context).languageCode == 'zh';
        final msg =
            isZh
                ? '单次录制不能超过60秒，已自动停止'
                : 'Recording cannot exceed 60s, stopped automatically';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  /// 停止录音
  /// [target] 录音目标：'title' 标题 或 'description' 描述
  Future<void> _stopRecording(String target) async {
    _speechRecognizer?.stopRecognition();
    _recordTimeoutTimer?.cancel();
    setState(() {
      if (target == 'title') {
        _isRecordingTitle = false;
        // _voicePathTitle = result;
        // _voiceDurationTitle = seconds;
      } else {
        _isRecordingDescription = false;
        // _voicePathDescription = result;
        // _voiceDurationDescription = seconds;
      }
    });
  }

  /// 播放语音文件
  /// [path] 语音文件路径
  Future<void> _playVoice(String? path) async {
    if (path == null) return;

    if (_isPlaying && _playingPath == path) {
      await _player!.stopPlayer();
      setState(() {
        _isPlaying = false;
        _playingPath = null;
      });
      return;
    }

    if (_isPlaying) {
      await _player!.stopPlayer();
    }

    setState(() {
      _isPlaying = true;
      _playingPath = path;
    });

    await _player!.startPlayer(
      fromURI: path,
      whenFinished: () {
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
      },
    );
  }

  /// 构建麦克风按钮（带呼吸动画效果）
  /// [isRecording] 是否正在录音
  /// [controller] 动画控制器
  /// [onTap] 点击回调
  Widget _buildMicButton({
    required bool isRecording,
    required AnimationController controller,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pulse = isRecording ? controller.value : 0.0;
        return GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isEnabled
                      ? Color.lerp(_accentColor, const Color(0xFFD64545), pulse)
                      : const Color(0xFFCCD3DF),
              boxShadow:
                  isRecording
                      ? [
                        BoxShadow(
                          color: const Color(0x47D64545),
                          blurRadius: 18,
                          spreadRadius: 2 + pulse * 5,
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceBar(
    String label,
    String target,
    String? path,
    int? duration,
  ) {
    final isPlayingThis = _isPlaying && _playingPath == path;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _playVoice(path),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlayingThis
                          ? Icons.graphic_eq_rounded
                          : Icons.play_arrow_rounded,
                      color: _brandColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$label (${duration ?? 0}")',
                      style: const TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeVoiceAttachment(target),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: _brandColor,
              splashRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeField() {
    final hasValue = _selectedDateTime != null;

    return InkWell(
      onTap: () {
        _hideKeyboard();
        if (_titleFocusNode.hasFocus) {
          _titleFocusNode.unfocus();
        }
        if (_descriptionFocusNode.hasFocus) {
          _descriptionFocusNode.unfocus();
        }
        Future.microtask(() {
          if (mounted) {
            _pickDateTime();
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined, color: _textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formattedDateTime,
                style: TextStyle(
                  color: hasValue ? _textPrimary : _textSecondary,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPicker() {
    final count = attachmentsMedia.length;
    final text =
        count == 0
            ? S.of(context).clickToUploadImageOrVideo
            : '${S.of(context).uploadAttachment} ($count)';

    return InkWell(
      onTap: _uploadAttachment,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: _accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  /// 获取格式化的日期时间字符串
  String get formattedDateTime {
    if (_selectedDateTime == null) return S.of(context).pleaseSelectTime;
    return DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
  }

  /// 选择日期时间（先选择日期，再选择时间）
  Future<void> _pickDateTime() async {
    // 在打开选择器之前确保键盘已隐藏
    _hideKeyboard();

    // 移除所有输入框的焦点
    if (_titleFocusNode.hasFocus) {
      _titleFocusNode.unfocus();
    }
    if (_descriptionFocusNode.hasFocus) {
      _descriptionFocusNode.unfocus();
    }

    // 等待片刻，确保键盘完全隐藏
    await Future.delayed(Duration(milliseconds: 100));
    if (!mounted) return;

    // 显示日期选择器
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // 确保日期选择器显示时键盘已隐藏
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _hideKeyboard();
        });
        return child!;
      },
    );

    // 如果用户选择了日期，继续选择时间
    if (date != null) {
      // 在显示时间选择器之前确保键盘已隐藏
      _hideKeyboard();
      // 再次移除所有输入框的焦点
      if (_titleFocusNode.hasFocus) {
        _titleFocusNode.unfocus();
      }
      if (_descriptionFocusNode.hasFocus) {
        _descriptionFocusNode.unfocus();
      }

      // 等待片刻后再显示时间选择器
      await Future.delayed(Duration(milliseconds: 100));
      if (!mounted) return;

      // 显示时间选择器
      final time = await showTimePicker(
        context: context,
        initialTime:
            _selectedDateTime != null
                ? TimeOfDay.fromDateTime(_selectedDateTime!)
                : TimeOfDay.now(),
        builder: (context, child) {
          // 确保时间选择器显示时键盘已隐藏
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _hideKeyboard();
            // 强制移除所有输入框的焦点，防止键盘弹出
            if (_titleFocusNode.hasFocus) {
              _titleFocusNode.unfocus();
            }
            if (_descriptionFocusNode.hasFocus) {
              _descriptionFocusNode.unfocus();
            }
          });
          // 返回子组件（Flutter默认使用时钟模式）
          return child!;
        },
      );

      // 如果用户选择了时间，保存日期时间
      if (time != null) {
        if (mounted) {
          setState(() {
            // 合并日期和时间，保存选中的日期时间
            _selectedDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
          // 确保选择完成后键盘保持隐藏状态
          _hideKeyboard();
        }
      }
    }
  }

  /// 上传附件（显示底部选择菜单：相册、拍照、录像）
  Future<void> _uploadAttachment() async {
    // 在打开底部选择菜单之前隐藏键盘
    _hideKeyboard();

    // 等待片刻，确保键盘完全隐藏
    await Future.delayed(Duration(milliseconds: 100));
    if (!mounted) return;

    // 显示底部选择菜单
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                // 从相册选择文件（支持多选）
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text(S.of(context).selectFromGallery),
                  onTap: () async {
                    Navigator.pop(context); // 关闭底部菜单
                    try {
                      final files = <File>[];

                      if (Platform.isIOS || Platform.isAndroid) {
                        final media = await ImagePicker().pickMultipleMedia();
                        for (final item in media) {
                          final persistedFile = await _persistPickedFile(
                            item.path,
                          );
                          if (persistedFile != null) {
                            files.add(persistedFile);
                          }
                        }
                      } else {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowMultiple: true,
                          allowedExtensions: [
                            'jpg',
                            'jpeg',
                            'png',
                            'gif',
                            'mp4',
                            'mov',
                            'avi',
                          ],
                        );

                        if (result != null) {
                          for (final item in result.files) {
                            final path = item.path;
                            if (path == null || path.isEmpty) continue;
                            final persistedFile = await _persistPickedFile(
                              path,
                              originalFileName: item.name,
                            );
                            if (persistedFile != null) {
                              files.add(persistedFile);
                            }
                          }
                        }
                      }

                      if (!mounted || files.isEmpty) return;
                      await _addPickedFiles(files);
                    } catch (e) {
                      if (!mounted) return;
                      ToastUtils.showError(
                        context,
                        '${S.of(context).uploadFailed}: $e',
                      );
                    }
                  },
                ),
                // 拍照
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text(S.of(context).takePhoto),
                  onTap: () async {
                    Navigator.pop(context); // 关闭底部菜单
                    // 打开相机拍照
                    final XFile? photo = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) {
                      final persistedFile = await _persistPickedFile(
                        photo.path,
                      );
                      if (persistedFile == null || !mounted) return;
                      await _addPickedFiles([persistedFile]);
                    }
                  },
                ),
                // 录像
                ListTile(
                  leading: Icon(Icons.videocam),
                  title: Text(S.of(context).recordVideo),
                  onTap: () async {
                    Navigator.pop(context); // 关闭底部菜单
                    // 打开相机录制视频
                    final XFile? video = await ImagePicker().pickVideo(
                      source: ImageSource.camera,
                    );
                    if (video != null) {
                      final persistedFile = await _persistPickedFile(
                        video.path,
                      );
                      if (persistedFile == null || !mounted) return;
                      await _addPickedFiles([persistedFile]);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<File?> _persistPickedFile(
    String sourcePath, {
    String? originalFileName,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final sourceName = (originalFileName ?? sourcePath).split('/').last;
    final safeFileName = '${DateTime.now().microsecondsSinceEpoch}_$sourceName';
    final targetPath = '${documentsDirectory.path}/$safeFileName';

    if (sourceFile.path == targetPath) {
      return sourceFile;
    }

    return sourceFile.copy(targetPath);
  }

  /// 提交反馈表单（更新反馈）
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _hideKeyboard();
      String title = _titleController.text;
      String desc = _descriptionController.text;
      setState(() => _isSubmitting = true);
      // 显示加载提示框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        if (feedbackType == null || feedbackType!.toString().trim().isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ToastUtils.showError(context, S.of(context).loadFailed);
          return;
        }
        if (productId == null || productId!.toString().trim().isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ToastUtils.showError(context, S.of(context).loadFailed);
          return;
        }

        final hasUploadingVoice =
            (_voicePathTitle != null && _voiceAttachmentIdTitle == null) ||
            (_voicePathDescription != null &&
                _voiceAttachmentIdDescription == null);
        if (hasUploadingVoice) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ToastUtils.showError(context, S.of(context).uploadFailed);
          return;
        }

        final attachmentIds = <int>[
          ...attachmentsMedia
              .map((item) => int.tryParse(item.id?.toString() ?? ''))
              .whereType<int>(),
          if (_voiceAttachmentIdTitle != null) _voiceAttachmentIdTitle!,
          if (_voiceAttachmentIdDescription != null)
            _voiceAttachmentIdDescription!,
        ];

        final occurTime =
            _selectedDateTime == null
                ? ''
                : DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDateTime!);

        print(
          "body : ${{'title': title.trim(), 'feedbackType': int.tryParse(feedbackType ?? '') ?? 0, 'deviceType': productId ?? '', 'deviceUdi': _deviceUdi ?? '', 'occurTime': occurTime, 'attachmentIds': attachmentIds, 'titleAudio': _voiceAttachmentIdTitle, 'descriptionAudio': _voiceAttachmentIdDescription}}",
        );

        final response = await HttpService().put(
          'feedback/$issueId',
          body: {
            'title': title.trim(),
            // 'feedbackType': int.tryParse(feedbackType ?? '') ?? 0,
            // 'deviceType': productId ?? '',
            // 'deviceUdi': _deviceUdi ?? '',
            'description': desc.trim(),
            'occurTime': occurTime,
            'attachmentIds': attachmentIds,
            if (_voiceAttachmentIdTitle != null)
              'titleAudio': _voiceAttachmentIdTitle,
            if (_voiceAttachmentIdDescription != null)
              'descriptionAudio': _voiceAttachmentIdDescription,
          },
        );

        final json = jsonDecode(response.body);
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭 loading
        if (json['status'] == 200) {
          // 成功提示
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text(S.of(context).success),
                  content: Text(S.of(context).updateSuccess),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // 关闭提示框
                        Navigator.of(context).pop(); // 返回上一页
                      },
                      child: Text(S.of(context).ok),
                    ),
                  ],
                ),
          );
        } else {
          ToastUtils.showError(
            context,
            json['message'] ?? S.of(context).updateFailed,
          );
        }
      } catch (e) {
        debugPrint("Update feedback failed: $e");
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭 loading
        ToastUtils.showError(context, '${S.of(context).uploadFailed}: $e');
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    // 移除焦点监听器，防止内存泄漏
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _descriptionFocusNode.removeListener(_onDescriptionFocusChange);

    // 关闭录音器和播放器
    _recorder?.closeRecorder();
    _player?.closePlayer();

    // 释放动画控制器
    _micAnimationTitle.dispose();
    _micAnimationDescription.dispose();

    // 取消所有定时器
    _flushTimer?.cancel(); // 刷新定时器
    _recordTimeoutTimer?.cancel(); // 录音超时定时器

    // 释放焦点节点
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();

    super.dispose();
  }

  // 图片预览
  void _previewImageInDialog(dynamic imageSource) {
    final isNetwork = imageSource is String;

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                PhotoView(
                  imageProvider:
                      isNetwork
                          ? NetworkImage(imageSource)
                          : FileImage(imageSource) as ImageProvider,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // 视频预览
  // void _previewVideoInDialog(File videoFile) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return Dialog(
  //         backgroundColor: Colors.black,
  //         insetPadding: EdgeInsets.all(0),
  //         child: VideoPlayerDialogContent(videoFile: videoFile),
  //       );
  //     },
  //   );
  // }
  void _previewVideoInDialog(dynamic videoSource) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: VideoPlayerDialogContent(videoFile: videoSource),
        );
      },
    );
  }

  List<MediaItem> convertFilesToMediaItems(List<File> files) {
    return files
        .where((file) {
          final name = file.path.split('/').last;
          final ext =
              name.contains('.')
                  ? name.split('.').last.split('?').first.toLowerCase()
                  : '';

          return ext != 'wav'; // 过滤掉 .wav 文件
        })
        .map((file) {
          final ext = file.path.split('.').last.toLowerCase();
          final type =
              ['jpg', 'jpeg', 'png', 'gif'].contains(ext) ? 'image' : 'video';
          return MediaItem(file: file, type: type);
        })
        .toList();
  }

  Future<void> _deleteNetworkAttachment(MediaItem item) async {
    if (item.id == null) {
      ToastUtils.showError(context, S.of(context).attachmentInfoException);
      return;
    }

    if (!mounted) return;
    setState(() {
      attachmentsMedia.removeWhere((media) => media.id == item.id);
    });
    ToastUtils.showSuccess(context, S.of(context).deleteSuccess);
  }

  void _previewMediaItem(MediaItem item) {
    if (item.type == 'image') {
      if (item.file != null) {
        _previewImageInDialog(item.file!);
      } else if (item.url != null) {
        _previewImageInDialog(item.url!);
      }
      return;
    }

    if (item.file != null) {
      _previewVideoInDialog(item.file!);
    } else if (item.url != null) {
      _previewVideoInDialog(item.url!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productLabel =
        productId == null ? S.of(context).unknown : getProductLabel(productId!);
    final feedbackLabel = getFeedbackTypeLabel(feedbackType);

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true, // 确保键盘弹出时页面会调整
      body: GestureDetector(
        onTap: () {
          final focusScope = FocusScope.of(context);
          if (focusScope.hasFocus) {
            _hideKeyboard();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          top: true,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 420 ? 16.0 : 24.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeedbackEditHeader(
                    title: S.of(context).edit,
                    subtitle: S.of(context).pleaseFillInfo,
                    horizontalPadding: horizontalPadding,
                    onBack: () {
                      _hideKeyboard();
                      Navigator.of(context).maybePop();
                    },
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          10,
                          horizontalPadding,
                          24,
                        ),
                        children: [
                          _ContextHeader(
                            productText: productLabel,
                            feedbackTypeText: feedbackLabel,
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 2),
                          _Section(
                            title: '${S.of(context).problemTitle} *',
                            titleTrailing: _buildMicButton(
                              isRecording: _isRecordingTitle,
                              controller: _micAnimationTitle,
                              onTap:
                                  () =>
                                      _isRecordingTitle
                                          ? _stopRecording('title')
                                          : _startRecording('title'),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  focusNode: _titleFocusNode,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  enableInteractiveSelection: true,
                                  decoration: InputDecoration(
                                    hintText:
                                        S.of(context).pleaseEnterProblemTitle,
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? S.of(context).pleaseEnterTitle
                                              : null,
                                  onTap: () {
                                    Future.microtask(() {
                                      _titleFocusNode.requestFocus();
                                      _showKeyboard();
                                    });
                                  },
                                  onFieldSubmitted: (_) {
                                    _descriptionFocusNode.requestFocus();
                                  },
                                ),
                                if (_voicePathTitle != null)
                                  _buildVoiceBar(
                                    S.of(context).titleRecording,
                                    'title',
                                    _voicePathTitle,
                                    _voiceDurationTitle,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: '${S.of(context).problemDescription} *',
                            titleTrailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isRecognizing)
                                  _RecognizingIndicator(
                                    text: S.of(context).voiceRecognizing,
                                  ),
                                if (_isRecognizing) const SizedBox(width: 10),
                                _buildMicButton(
                                  isRecording: _isRecordingDescription,
                                  controller: _micAnimationDescription,
                                  isEnabled: !_isRecognizing,
                                  onTap:
                                      () =>
                                          _isRecordingDescription
                                              ? _stopRecording('description')
                                              : _startRecording('description'),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _descriptionController,
                                  focusNode: _descriptionFocusNode,
                                  minLines: 5,
                                  maxLines: 10,
                                  enabled: !_isRecognizing,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  enableInteractiveSelection: true,
                                  decoration: InputDecoration(
                                    hintText:
                                        _isRecognizing
                                            ? S.of(context).voiceRecognizingHint
                                            : S.of(context).pleaseEnterContent,
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.isEmpty
                                              ? S
                                                  .of(context)
                                                  .pleaseEnterProblemContent
                                              : null,
                                  onTap: () {
                                    if (!_isRecognizing) {
                                      Future.microtask(() {
                                        _descriptionFocusNode.requestFocus();
                                        _showKeyboard();
                                      });
                                    }
                                  },
                                ),
                                if (_voicePathDescription != null)
                                  _buildVoiceBar(
                                    S.of(context).descriptionRecording,
                                    'description',
                                    _voicePathDescription,
                                    _voiceDurationDescription,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: '${S.of(context).occurTime} *',
                            child: _buildDateTimeField(),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: S.of(context).uploadAttachment,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAttachmentPicker(),
                                if (attachmentsMedia.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  MediaList(
                                    mediaItems: attachmentsMedia,
                                    onDelete: _deleteNetworkAttachment,
                                    onPreview: _previewMediaItem,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                      : Text(
                        S.of(context).submit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackEditHeader extends StatelessWidget {
  const _FeedbackEditHeader({
    required this.title,
    required this.subtitle,
    required this.horizontalPadding,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final double horizontalPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back_rounded,
                  color: _brandColor,
                  size: isIOS ? 20 : 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({
    required this.productText,
    required this.feedbackTypeText,
  });

  final String productText;
  final String feedbackTypeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_note_rounded, color: _brandColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(text: productText, color: _brandColor),
                _InfoChip(text: feedbackTypeText, color: _accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.titleTrailing,
  });

  final String title;
  final Widget child;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (titleTrailing != null) titleTrailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RecognizingIndicator extends StatelessWidget {
  const _RecognizingIndicator({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD64545),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
