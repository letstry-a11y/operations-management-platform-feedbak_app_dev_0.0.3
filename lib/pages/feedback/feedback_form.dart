import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/chat_stream_client.dart';
import 'package:medbot_ai_app/utils/device_binding_repository.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/utils/speech_recognizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:medbot_ai_app/widgets/device_id_card.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/widgets/video_play.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_compress/video_compress.dart';

const _brandColor = Color(0xFF042A72);
const _accentColor = Color(0xFF12A594);
const _pageBackground = Color(0xFFF6F8FB);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF697386);
const _borderColor = Color(0xFFD8DEE9);

class _PendingAttachment {
  // 页面内的“待上传/已上传附件”状态对象：
  // - file：本地文件
  // - attachmentId：上传接口返回的 id（提交反馈时只提交这个 id 列表）
  // - isUploading：是否正在上传（用于 UI loading）
  // - isRemoved：用户在上传完成前是否已删除（用于上传结束后补偿删除服务端附件）
  _PendingAttachment({
    required this.file,
    this.attachmentId,
    this.presignedUrl,
    this.filename,
    this.fileType,
    this.isUploading = false,
    this.isRemoved = false,
    this.progressText,
    this.progressValue,
  });

  final File file;
  int? attachmentId;
  String? presignedUrl;
  String? filename;
  int? fileType;
  bool isUploading;
  bool isRemoved;
  String? progressText;
  double? progressValue;
}

class _UploadedAttachmentResult {
  // 上传接口 feedback/attachments 的返回 data 映射
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

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm>
    with TickerProviderStateMixin {
  static const int _maxRecordSeconds = 50;
  static const _flushInterval = Duration(milliseconds: 120);

  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deviceIdFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _descBuffer = StringBuffer();
  final _imagePicker = ImagePicker();

  late final ChatStreamClient client;

  FlutterSoundPlayer? _player;
  SpeechRecognizer? _speechRecognizer;

  late final AnimationController _micAnimationTitle;
  late final AnimationController _micAnimationDescription;

  String? deviceType;
  String? feedbackType;
  String? feedbackTypeText;
  String? productText;

  DateTime? _selectedDateTime;
  String? _dateTimeError;

  final List<_PendingAttachment> _selectedMediaAttachments = [];
  String? _voicePathTitle;
  String? _voicePathDescription;
  int? _voiceDurationTitle;
  int? _voiceDurationDescription;
  // 语音文件对应的 attachmentId（标题 / 描述各一份）
  int? _voiceAttachmentIdTitle;
  int? _voiceAttachmentIdDescription;
  int? titleAudio;
  int? descriptionAudio;

  bool _isParamsLoaded = false;
  bool _isRecordingTitle = false;
  bool _isRecordingDescription = false;
  bool _isRecognizing = false;
  bool _isPlaying = false;
  bool _isSubmitting = false;

  String? _playingPath;
  String _speechRecognizerType = '';
  String _recognizedDescription = '';

  Timer? _flushTimer;
  Timer? _recordTimeoutTimer;
  StreamSubscription<String>? _aiSubscription;

  @override
  void initState() {
    super.initState();
    final baseUrl = HttpService().baseUrl;
    final normalizedBaseUrl =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    client = ChatStreamClient(serverUrl: normalizedBaseUrl);
    _player = FlutterSoundPlayer();
    _micAnimationTitle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _micAnimationDescription = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _initAudio();
    _initSpeechRecognizer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isParamsLoaded) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      deviceType = args['product_id']?.toString();
      feedbackType = args['feedback_type']?.toString();
      productText =
          deviceType == null
              ? S.of(context).unknown
              : getProductLabel(deviceType!);
      feedbackTypeText = _feedbackTypeLabel(feedbackType);

      // 来自语音输入页(VoiceInputPage)的 AI 结构化结果,自动预填
      final aiFields = (args['ai_fields'] as Map?)?.cast<String, dynamic>();
      if (aiFields != null) {
        _applyAiFields(aiFields);
      }
    }

    _isParamsLoaded = true;
  }

  @override
  void dispose() {
    _recordTimeoutTimer?.cancel();
    _flushTimer?.cancel();
    final aiSubscription = _aiSubscription;
    if (aiSubscription != null) {
      aiSubscription.cancel();
    }
    _deviceIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _deviceIdFocusNode.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    final player = _player;
    if (player != null) {
      player.closePlayer();
    }
    final speechRecognizer = _speechRecognizer;
    if (speechRecognizer != null) {
      speechRecognizer.dispose();
    }
    _micAnimationTitle.dispose();
    _micAnimationDescription.dispose();
    super.dispose();
  }

  void _initSpeechRecognizer() {
    final recognizer = SpeechRecognizer(
      appId: '397dfc06',
      apiKey: '',
      apiSecret: '',
      onResult: _handleSpeechResult,
      onError: (error) {
        if (!mounted) return;
        _showSnack('${S.of(context).recognitionError}: $error');
      },
      onAudioSaved: _handleAudioSaved,
    );
    _speechRecognizer = recognizer;
    recognizer.init();
  }

  Future<void> _initAudio() async {
    try {
      var microphoneStatus = await Permission.microphone.status;
      if (microphoneStatus.isDenied) {
        microphoneStatus = await Permission.microphone.request();
      }

      if (microphoneStatus.isGranted) {
        await _player?.openPlayer();
      } else if (mounted) {
        _showSnack(S.of(context).microphonePermissionRequired);
      }
    } catch (error) {
      debugPrint('Audio init failed: $error');
    }
  }

  void _handleSpeechResult(String text) {
    if (!mounted) return;
    print('Recognized text: $text');
    if (_speechRecognizerType == 'title') {
      _setControllerText(_titleController, text);
      return;
    }

    if (text.isEmpty) {
      _showSnack(S.of(context).contentEmptyPleaseReenter);
      return;
    }

    _recognizedDescription += text;
  }

  void _handleAudioSaved(String path, int duration) {
    if (!mounted) return;

    setState(() {
      if (_speechRecognizerType == 'title') {
        _isRecordingTitle = false;
        _voicePathTitle = path;
        _voiceDurationTitle = duration;
        _stopMicAnimation('title');
      } else {
        _isRecordingDescription = false;
        _voicePathDescription = path;
        _voiceDurationDescription = duration;
        _stopMicAnimation('description');
      }
    });

    // 语音文件保存到本地后，立即上传到 feedback/attachments，拿到 attachmentId
    _uploadVoiceAttachment(path, _speechRecognizerType);

    if (_speechRecognizerType == 'description' &&
        _recognizedDescription.isNotEmpty) {
      _streamRecognizedDescription();
    }
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
          final normalized =
              numeric > 1 ? (numeric / 100).clamp(0.0, 1.0) : numeric;
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
    } catch (_) {}
    return candidate;
  }

  Future<_UploadedAttachmentResult> _uploadAttachmentFile(
    File file, {
    void Function(String text, double? progress)? onVideoProgress,
  }) async {
    // 规则：feedback/attachments 只接收一个字段 file，并且每次只能上传一个文件
    final fileToUpload = await _transcodeVideoIfNeeded(
      file,
      onProgress: onVideoProgress,
    );
    if (onVideoProgress != null && !_isImageFile(file)) {
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

  Future<void> _deleteAttachmentId(int attachmentId) async {
    // 用户在提交反馈前删除附件时，需要同步删除服务端的 attachmentId
    await HttpService().delete('feedback/attachments/$attachmentId');
  }

  Future<void> _uploadPendingAttachment(_PendingAttachment attachment) async {
    // 单个附件的上传流程：本地文件 -> 上传 -> 保存 attachmentId
    if (attachment.isUploading || attachment.attachmentId != null) return;
    void updateProgress(String text, double? value) {
      if (!mounted) return;
      if (!_selectedMediaAttachments.contains(attachment)) return;
      setState(() {
        attachment
          ..progressText = text
          ..progressValue = value;
      });
    }

    setState(() {
      attachment
        ..isUploading = true
        ..progressText = S.of(context).uploading
        ..progressValue = null;
    });

    try {
      final result = await _uploadAttachmentFile(
        attachment.file,
        onVideoProgress: (text, value) => updateProgress(text, value),
      );
      if (!mounted) return;

      // 如果用户在上传完成前就把这个附件从页面删除了，上传成功后立刻补偿删除服务端附件
      if (attachment.isRemoved) {
        await _deleteAttachmentId(result.attachmentId);
        return;
      }

      setState(() {
        attachment
          ..isUploading = false
          ..progressText = null
          ..progressValue = null
          ..attachmentId = result.attachmentId
          ..presignedUrl = result.presignedUrl
          ..filename = result.filename
          ..fileType = result.fileType;
      });
    } catch (error) {
      debugPrint('Upload attachment failed: $error');
      if (!mounted) return;
      setState(() {
        _selectedMediaAttachments.remove(attachment);
      });
      _showSnack('${S.of(context).uploadFailed}: $error');
    }
  }

  Future<void> _setMediaAttachments(
    List<File> files, {
    required bool replace,
  }) async {
    // replace=true 表示“重新选择一批附件”，需要把上一批已上传的 attachmentId 先删除，避免脏数据
    if (replace) {
      final idsToDelete =
          _selectedMediaAttachments
              .map((item) => item.attachmentId)
              .whereType<int>()
              .toList();
      setState(() {
        _selectedMediaAttachments.clear();
      });
      for (final id in idsToDelete) {
        try {
          await _deleteAttachmentId(id);
        } catch (error) {
          debugPrint('Delete attachment failed: $error');
        }
      }
    }

    if (!mounted || files.isEmpty) return;
    final pending =
        files.map((file) => _PendingAttachment(file: file)).toList();
    setState(() {
      _selectedMediaAttachments.addAll(pending);
    });
    // 多选多个文件时，这里会逐个发请求（每个请求只上传一个文件）
    for (final item in pending) {
      await _uploadPendingAttachment(item);
    }
  }

  Future<void> _removeMediaAttachment(_PendingAttachment attachment) async {
    // 先从 UI 移除；如果已经拿到 attachmentId，再删除服务端
    final attachmentId = attachment.attachmentId;
    setState(() {
      attachment.isRemoved = true;
      _selectedMediaAttachments.remove(attachment);
    });

    if (attachmentId == null) return;
    try {
      await _deleteAttachmentId(attachmentId);
    } catch (error) {
      debugPrint('Delete attachment failed: $error');
    }
  }

  Future<void> _uploadVoiceAttachment(String path, String target) async {
    // 语音也走同一套附件上传接口：feedback/attachments
    final file = File(path);
    if (!await file.exists()) return;

    final previousId =
        target == 'title'
            ? _voiceAttachmentIdTitle
            : _voiceAttachmentIdDescription;
    if (previousId != null) {
      try {
        // 同一位置（title/description）新录一段语音时，旧的 attachmentId 先删掉
        await _deleteAttachmentId(previousId);
      } catch (error) {
        debugPrint('Delete voice attachment failed: $error');
      }
    }

    if (!mounted) return;
    setState(() {
      if (target == 'title') {
        _voiceAttachmentIdTitle = null;
        titleAudio = null;
      } else {
        _voiceAttachmentIdDescription = null;
        descriptionAudio = null;
      }
    });

    try {
      final result = await _uploadAttachmentFile(file);
      if (!mounted) return;
      setState(() {
        if (target == 'title') {
          _voiceAttachmentIdTitle = result.attachmentId;
          titleAudio = result.attachmentId;
        } else {
          _voiceAttachmentIdDescription = result.attachmentId;
          descriptionAudio = result.attachmentId;
        }
      });
    } catch (error) {
      debugPrint('Upload voice attachment failed: $error');
      if (!mounted) return;
      setState(() {
        if (target == 'title') {
          _voicePathTitle = null;
          _voiceDurationTitle = null;
          _voiceAttachmentIdTitle = null;
          titleAudio = null;
        } else {
          _voicePathDescription = null;
          _voiceDurationDescription = null;
          _voiceAttachmentIdDescription = null;
          descriptionAudio = null;
        }
      });
      _showSnack('${S.of(context).uploadFailed}: $error');
    }
  }

  Future<void> _removeVoiceAttachment(String target) async {
    final path = target == 'title' ? _voicePathTitle : _voicePathDescription;
    final attachmentId =
        target == 'title'
            ? _voiceAttachmentIdTitle
            : _voiceAttachmentIdDescription;
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

    if (attachmentId == null) return;
    try {
      await _deleteAttachmentId(attachmentId);
    } catch (error) {
      debugPrint('Delete voice attachment failed: $error');
    }
  }

  void _streamRecognizedDescription() {
    setState(() {
      _isRecognizing = true;
      _descriptionController.clear();
    });

    final previousSubscription = _aiSubscription;
    if (previousSubscription != null) {
      previousSubscription.cancel();
    }
    _aiSubscription = slowStream(
      client.askQuestion(_recognizedDescription, token: HttpService().token),
    ).listen(
      (word) {
        print('word: $word');
        // 1. 去掉双引号
        String result = word.replaceAll('"', '');

        // 2. 把 \n 转成真正换行
        result = result.replaceAll(r'\n', '\n');
        _descBuffer.write(result);
        if (_flushTimer?.isActive ?? false) return;

        _flushTimer = Timer(_flushInterval, () {
          if (!mounted) return;
          _appendDescriptionText(_descBuffer.toString());
          _descBuffer.clear();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _setControllerText(_descriptionController, _recognizedDescription);
          _isRecognizing = false;
        });
      },
      onDone: () {
        if (_descBuffer.isNotEmpty) {
          _appendDescriptionText(_descBuffer.toString());
          _descBuffer.clear();
        }
        if (!mounted) return;
        setState(() {
          _isRecognizing = false;
          _recognizedDescription = '';
        });
      },
    );
  }

  Stream<String> slowStream(Stream<String> input) async* {
    await for (final word in input) {
      yield word;
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  String get formattedDateTime {
    if (_selectedDateTime == null) return S.of(context).pleaseSelectTime;
    return DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
  }

  String get _attachmentCountText {
    final count = _selectedMediaAttachments.length;
    if (count == 0) return S.of(context).clickToUpload;
    return '$count ${S.of(context).attachment}';
  }

  String _apiDeviceType(String productId) {
    switch (productId) {
      case '101':
      case '102':
        return 'Toumai';
      case '103':
        return 'DFVision';
      case '104':
        return 'Honghu';
      case '105':
        return 'Rone';
      case '106':
        return 'MonaLisa';
      default:
        return 'Other';
    }
  }

  String _feedbackTypeLabel(String? type) {
    switch (type) {
      case '1':
        return S.of(context).defectFeedback;
      case '2':
        return S.of(context).requirementFeedback;
      case '3':
        return S.of(context).otherFeedback;
      default:
        return S.of(context).unknownType;
    }
  }

  String getProductLabel(String deviceType) {
    final productOptions = _getProductOptions();
    return productOptions.firstWhere(
      (item) => item['value'] == deviceType,
      orElse: () => {'label': S.of(context).unknown},
    )['label']!;
  }

  List<Map<String, String>> _getProductOptions() {
    return [
      {'label': S.of(context).all, 'value': '100'},
      {'label': S.of(context).tumaiMultiPort, 'value': '101'},
      {'label': S.of(context).tumaiSinglePort, 'value': '102'},
      {'label': S.of(context).dragonflyEye, 'value': '103'},
      {'label': S.of(context).honghu, 'value': '104'},
      {'label': S.of(context).rone, 'value': '105'},
      {'label': S.of(context).monaLisa, 'value': '106'},
      {'label': S.of(context).other, 'value': '107'},
    ];
  }

  String? _requiredText(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String get _deviceIdLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '设备 ID' : 'Device ID';
  }

  String get _deviceIdHint {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '支持扫码识别或手动输入设备编码'
        : 'Scan barcode/QR code or enter the device ID manually';
  }

  String get _deviceIdRequiredMessage {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '请输入设备 ID' : 'Please enter device ID';
  }

  String get _scanDeviceIdLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '扫码识别' : 'Scan code';
  }

  String get _manualEntryLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '手动录入' : 'Manual entry';
  }

  String get _scanCancelledMessage {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '未识别到设备码，请重试' : 'No device code detected';
  }

  String get _cameraPermissionMessage {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '需要相机权限以扫描设备码'
        : 'Camera permission is required to scan the device code';
  }

  String get _scanInstructionLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '支持一维码和二维码'
        : 'Supports barcode and QR code scanning';
  }

  String? _validateDateTime(DateTime? dateTime) {
    return dateTime == null ? S.of(context).pleaseSelectTime : null;
  }

  void _setControllerText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _appendDescriptionText(String value) {
    final next = '${_descriptionController.text}$value';
    _setControllerText(_descriptionController, next);
  }

  /// 应用来自语音页的 AI 结构化结果(预填 / 合并覆盖)。
  /// 仅对非空字段赋值;occurTime 尝试解析为 DateTime,失败则忽略。
  void _applyAiFields(Map<String, dynamic> fields) {
    final title = fields['title']?.toString().trim();
    final description = fields['description']?.toString().trim();
    final occurTime = fields['occurTime']?.toString().trim();

    if (title != null && title.isNotEmpty) {
      _setControllerText(_titleController, title);
    }
    if (description != null && description.isNotEmpty) {
      _setControllerText(_descriptionController, description);
    }
    final parsed = _parseOccurTime(occurTime);
    if (parsed != null) {
      _selectedDateTime = parsed;
      _dateTimeError = null;
    }
  }

  /// 「继续补充」:回到语音页(补充模式),返回的合并结果覆盖填入当前表单。
  Future<void> _continueSupplement() async {
    _hideKeyboard();
    final result = await Navigator.of(context).pushNamed(
      '/voice-feedback',
      arguments: {
        if (deviceType != null) 'product_id': deviceType,
        if (feedbackType != null) 'feedback_type': feedbackType,
        'from_supplement': true,
        'existing_content': {
          'title': _titleController.text,
          'description': _descriptionController.text,
        },
      },
    );
    if (!mounted) return;
    if (result is Map) {
      setState(() {
        _applyAiFields(result.cast<String, dynamic>());
      });
    }
  }

  /// 宽松解析 AI 返回的时间字符串(支持常见格式),失败返回 null。
  DateTime? _parseOccurTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final patterns = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy/MM/dd HH:mm',
      'yyyy-MM-dd',
    ];
    for (final p in patterns) {
      try {
        return DateFormat(p).parseStrict(value);
      } catch (_) {}
    }
    return DateTime.tryParse(value);
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _scanDeviceId() async {
    _hideKeyboard();

    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (!cameraStatus.isGranted) {
      if (mounted) {
        _showSnack(_cameraPermissionMessage);
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (_) => _DeviceScannerPage(
              title: _scanDeviceIdLabel,
              subtitle: _scanInstructionLabel,
            ),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) {
      if (mounted && result != null) {
        _showSnack(_scanCancelledMessage);
      }
      return;
    }

    final normalized = _normalizeDeviceId(result);
    setState(() {
      _setControllerText(_deviceIdController, normalized);
    });
    _showSnack('$_deviceIdLabel: $normalized');
  }

  String _normalizeDeviceId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    final uri = Uri.tryParse(value);
    if (uri != null) {
      const queryKeys = ['deviceId', 'device_id', 'sn', 'code', 'id'];
      for (final key in queryKeys) {
        final queryValue = uri.queryParameters[key];
        if (queryValue != null && queryValue.trim().isNotEmpty) {
          return queryValue.trim();
        }
      }

      final segment = uri.pathSegments.reversed.firstWhere(
        (item) => item.trim().isNotEmpty,
        orElse: () => '',
      );
      if (segment.isNotEmpty) {
        return Uri.decodeComponent(segment).trim();
      }
    }

    final lineMatch = RegExp(
      r'(?:device[_\s-]?id|sn|code)[:=]\s*([A-Za-z0-9\-_./]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (lineMatch != null) {
      return lineMatch.group(1)?.trim() ?? value;
    }

    return value;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  AnimationController _micAnimationFor(String target) {
    return target == 'title' ? _micAnimationTitle : _micAnimationDescription;
  }

  void _stopMicAnimation(String target) {
    _micAnimationFor(target)
      ..stop()
      ..reset();
  }

  Future<void> _startRecording(String target) async {
    if (_isRecognizing && target == 'description') {
      _showSnack(S.of(context).voiceRecognizingHint);
      return;
    }

    if (_isRecordingTitle || _isRecordingDescription) {
      _showSnack(S.of(context).currentlyRecognizing);
      return;
    }

    try {
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      if (!microphoneStatus.isGranted) {
        if (mounted) _showSnack(S.of(context).microphonePermissionRequired);
        return;
      }

      _speechRecognizerType = target;
      if (target == 'description') _recognizedDescription = '';
      await _speechRecognizer?.startRecognition();

      if (!mounted) return;
      setState(() {
        if (target == 'title') {
          _isRecordingTitle = true;
        } else {
          _isRecordingDescription = true;
        }
      });
      _micAnimationFor(target).repeat(reverse: true);

      _recordTimeoutTimer?.cancel();
      _recordTimeoutTimer = Timer(
        const Duration(seconds: _maxRecordSeconds),
        () => _stopRecording(target),
      );
    } catch (error) {
      debugPrint('Start recording failed: $error');
      if (mounted) {
        _showSnack('${S.of(context).recordingStartFailed}: $error');
      }
      _stopMicAnimation(target);
    }
  }

  Future<void> _stopRecording(String target) async {
    _recordTimeoutTimer?.cancel();
    await _speechRecognizer?.stopRecognition();

    if (!mounted) return;
    setState(() {
      if (target == 'title') {
        _isRecordingTitle = false;
      } else {
        _isRecordingDescription = false;
      }
      _stopMicAnimation(target);
    });
  }

  Future<void> _playVoice(String? path) async {
    if (path == null) return;

    try {
      if (_isPlaying && _playingPath == path) {
        await _player?.stopPlayer();
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        return;
      }

      if (_isPlaying) await _player?.stopPlayer();

      setState(() {
        _isPlaying = true;
        _playingPath = path;
      });

      final file = File(path);
      if (!await file.exists()) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _playingPath = null;
        });
        _showSnack(S.of(context).audioFileNotFound);
        return;
      }

      await _player?.startPlayer(
        fromURI: path,
        whenFinished: () {
          if (!mounted) return;
          setState(() {
            _isPlaying = false;
            _playingPath = null;
          });
        },
      );
    } catch (error) {
      debugPrint('Playback failed: $error');
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playingPath = null;
      });
      _showSnack('${S.of(context).playbackFailed}: $error');
    }
  }

  Future<void> _pickDateTime() async {
    _hideKeyboard();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    _hideKeyboard();
    final time = await showTimePicker(
      context: context,
      initialTime:
          _selectedDateTime == null
              ? TimeOfDay.now()
              : TimeOfDay.fromDateTime(_selectedDateTime!),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateTimeError = null;
    });
  }

  Future<void> _uploadAttachment() async {
    _hideKeyboard();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCD3DF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                _AttachmentActionTile(
                  icon: Icons.photo_library_outlined,
                  title: S.of(context).selectFromGallery,
                  onTap: () {
                    Navigator.pop(context);
                    _pickGalleryFiles();
                  },
                ),
                _AttachmentActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: S.of(context).takePhoto,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _AttachmentActionTile(
                  icon: Icons.videocam_outlined,
                  title: S.of(context).recordVideo,
                  onTap: () {
                    Navigator.pop(context);
                    _recordVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickGalleryFiles() async {
    try {
      final files = <File>[];

      if (Platform.isIOS || Platform.isAndroid) {
        final media = await _imagePicker.pickMultipleMedia();
        for (final item in media) {
          final persistedFile = await _persistPickedFile(item.path);
          if (persistedFile != null) {
            files.add(persistedFile);
          }
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: true,
          allowedExtensions: const [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'mp4',
            'mov',
            'avi',
          ],
        );

        if (result == null) return;

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

      if (!mounted || files.isEmpty) return;
      await _setMediaAttachments(files, replace: true);
    } catch (error) {
      debugPrint('Pick gallery files failed: $error');
      if (mounted) {
        _showSnack('${S.of(context).uploadFailed}: $error');
      }
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo == null || !mounted) return;

    final persistedFile = await _persistPickedFile(photo.path);
    if (persistedFile == null || !mounted) return;

    await _setMediaAttachments([persistedFile], replace: false);
  }

  Future<void> _recordVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (video == null || !mounted) return;

    final persistedFile = await _persistPickedFile(video.path);
    if (persistedFile == null || !mounted) return;

    await _setMediaAttachments([persistedFile], replace: false);
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

  Future<void> _submit() async {
    _hideKeyboard();
    setState(() {
      _dateTimeError = _validateDateTime(_selectedDateTime);
    });

    if (!(_formKey.currentState?.validate() ?? false) ||
        _dateTimeError != null) {
      return;
    }

    if (deviceType == null) {
      ToastUtils.showError(context, S.of(context).pleaseSelectProductType);
      return;
    }

    if (feedbackType == null) {
      ToastUtils.showError(context, S.of(context).pleaseSelectFeedbackType);
      return;
    }

    setState(() => _isSubmitting = true);
    _showSubmittingDialog();

    try {
      // 提交 feedback 之前，必须保证所有附件都已经拿到 attachmentId
      final hasUploadingMedia = _selectedMediaAttachments.any(
        (item) => item.isUploading || item.attachmentId == null,
      );
      final hasUploadingVoice =
          (_voicePathTitle != null && _voiceAttachmentIdTitle == null) ||
          (_voicePathDescription != null &&
              _voiceAttachmentIdDescription == null);
      if (hasUploadingMedia || hasUploadingVoice) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ToastUtils.showError(context, S.of(context).uploadFailed);
        return;
      }

      // feedback 接口只需要 attachmentIds（附件 id 集合），不再传文件本体
      final attachmentIds = <int>[
        ..._selectedMediaAttachments
            .map((item) => item.attachmentId)
            .whereType<int>(),
        if (_voiceAttachmentIdTitle != null) _voiceAttachmentIdTitle!,
        if (_voiceAttachmentIdDescription != null)
          _voiceAttachmentIdDescription!,
      ];

      final occurTime =
          _selectedDateTime == null
              ? ''
              : DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDateTime!);

      // 新建反馈：POST feedback
      print('attachmentIds: $attachmentIds');
      print(
        'deviceType: ${{'title': _titleController.text.trim(), 'feedbackType': int.tryParse(feedbackType!) ?? 0, 'deviceType': deviceType, 'deviceUdi': _deviceIdController.text.trim(), 'description': _descriptionController.text.trim(), 'occurTime': occurTime, 'attachmentIds': attachmentIds, 'titleAudio': titleAudio, 'descriptionAudio': descriptionAudio}}',
      );
      final response = await HttpService().post(
        'feedback',
        body: {
          'title': _titleController.text.trim(),
          'feedbackType': int.tryParse(feedbackType!) ?? 0,
          'deviceType': deviceType,
          'deviceUdi': _deviceIdController.text.trim(),
          'description': _descriptionController.text.trim(),
          'occurTime': occurTime,
          'attachmentIds': attachmentIds,
          'titleAudio': titleAudio,
          'descriptionAudio': descriptionAudio,
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      Navigator.of(context).pop();

      if (data['status'] == 200) {
        final deviceId = _deviceIdController.text.trim();
        if (deviceId.isNotEmpty) {
          await DeviceBindingRepository().bindDevice(deviceId);
        }
        await _showSuccessDialog();
      } else {
        ToastUtils.showError(context, _messageFrom(data));
      }
    } catch (error) {
      debugPrint('Submit feedback failed: $error');
      if (!mounted) return;
      Navigator.of(context).pop();
      ToastUtils.showError(
        context,
        error is HttpException
            ? error.message
            : '${S.of(context).uploadFailed}: $error',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFrom(Map<String, dynamic> data) {
    final message = data['message'];
    return message is String && message.isNotEmpty
        ? message
        : S.of(context).submitFailed;
  }

  void _showSubmittingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(S.of(context).success),
            content: Text(S.of(context).feedbackSubmittedSuccessfully),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).ok),
              ),
            ],
          ),
    );
  }

  bool _isImageFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
  }

  void _previewAttachment(File file) {
    if (_isImageFile(file)) {
      _previewImageInDialog(file);
    } else {
      _previewVideoInDialog(file);
    }
  }

  void _previewImageInDialog(File imageFile) {
    showDialog<void>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                PhotoView(
                  imageProvider: FileImage(imageFile),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: Material(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _previewVideoInDialog(File videoFile) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: VideoPlayerDialogContent(videoFile: videoFile),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideKeyboard,
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
                  _FeedbackPageHeader(
                    title: S.of(context).feedbackForm,
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
                            productText: productText ?? S.of(context).unknown,
                            feedbackTypeText:
                                feedbackTypeText ?? S.of(context).unknownType,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _continueSupplement,
                              icon: const Icon(Icons.mic_none),
                              label: Text(S.of(context).continueSupplement),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Section(
                            title: '$_deviceIdLabel *',
                            child: DeviceIdCard(
                              scanTitle: _scanDeviceIdLabel,
                              scanHint: _deviceIdHint,
                              scanButtonLabel: _scanDeviceIdLabel,
                              manualTitle: _manualEntryLabel,
                              onScan: _scanDeviceId,
                              input: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _deviceIdController,
                                builder: (context, value, _) {
                                  return TextFormField(
                                    controller: _deviceIdController,
                                    focusNode: _deviceIdFocusNode,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: _deviceIdHint,
                                      prefixIcon: const Icon(
                                        Icons.confirmation_number_outlined,
                                      ),
                                      suffixIcon:
                                          value.text.isEmpty
                                              ? null
                                              : IconButton(
                                                onPressed:
                                                    _deviceIdController.clear,
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                              ),
                                    ),
                                    validator:
                                        (value) => _requiredText(
                                          value,
                                          _deviceIdRequiredMessage,
                                        ),
                                  );
                                },
                              ),
                              brandColor: _brandColor,
                              primaryTextColor: _textPrimary,
                              secondaryTextColor: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: '${S.of(context).problemTitle} *',
                            titleTrailing: _MicButton(
                              isRecording: _isRecordingTitle,
                              controller: _micAnimationTitle,
                              onTap: () {
                                if (_isRecordingTitle) {
                                  _stopRecording('title');
                                } else {
                                  _startRecording('title');
                                }
                              },
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  focusNode: _titleFocusNode,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText:
                                        S.of(context).pleaseEnterProblemTitle,
                                  ),
                                  validator:
                                      (value) => _requiredText(
                                        value,
                                        S.of(context).pleaseEnterTitle,
                                      ),
                                  onFieldSubmitted: (_) {
                                    _descriptionFocusNode.requestFocus();
                                  },
                                ),
                                if (_voicePathTitle != null)
                                  _VoiceBar(
                                    label: S.of(context).titleRecording,
                                    duration: _voiceDurationTitle,
                                    isPlaying:
                                        _isPlaying &&
                                        _playingPath == _voicePathTitle,
                                    onTap: () => _playVoice(_voicePathTitle),
                                    onRemove:
                                        () => _removeVoiceAttachment('title'),
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
                                _MicButton(
                                  isRecording: _isRecordingDescription,
                                  controller: _micAnimationDescription,
                                  isEnabled: !_isRecognizing,
                                  onTap: () {
                                    if (_isRecordingDescription) {
                                      _stopRecording('description');
                                    } else {
                                      _startRecording('description');
                                    }
                                  },
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
                                  decoration: InputDecoration(
                                    hintText:
                                        _isRecognizing
                                            ? S.of(context).voiceRecognizingHint
                                            : S.of(context).pleaseEnterContent,
                                  ),
                                  validator:
                                      (value) => _requiredText(
                                        value,
                                        S.of(context).pleaseEnterProblemContent,
                                      ),
                                ),
                                if (_voicePathDescription != null)
                                  _VoiceBar(
                                    label: S.of(context).descriptionRecording,
                                    duration: _voiceDurationDescription,
                                    isPlaying:
                                        _isPlaying &&
                                        _playingPath == _voicePathDescription,
                                    onTap:
                                        () => _playVoice(_voicePathDescription),
                                    onRemove:
                                        () => _removeVoiceAttachment(
                                          'description',
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: '${S.of(context).occurTime} *',
                            child: _DateTimeField(
                              value: formattedDateTime,
                              errorText: _dateTimeError,
                              hasValue: _selectedDateTime != null,
                              onTap: _pickDateTime,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Section(
                            title: S.of(context).uploadAttachment,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AttachmentPicker(
                                  text: _attachmentCountText,
                                  onTap: _uploadAttachment,
                                ),
                                if (_selectedMediaAttachments.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _AttachmentGrid(
                                    attachments: _selectedMediaAttachments,
                                    isImageFile: _isImageFile,
                                    onTap: _previewAttachment,
                                    onRemove: _removeMediaAttachment,
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

class _FeedbackPageHeader extends StatelessWidget {
  const _FeedbackPageHeader({
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
            child: const Icon(Icons.rate_review_outlined, color: _brandColor),
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

class _DeviceScannerPage extends StatefulWidget {
  const _DeviceScannerPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_DeviceScannerPage> createState() => _DeviceScannerPageState();
}

class _DeviceScannerPageState extends State<_DeviceScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;
  bool _torchEnabled = false;
  bool _scannerUnavailable = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markScannerUnavailable() {
    if (_scannerUnavailable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _scannerUnavailable = true;
      });
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final isSimulator =
        Platform.isIOS &&
        (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
            Platform.environment.containsKey('SIMULATOR_UDID'));
    final unavailableMessage =
        isZh
            ? 'iOS 模拟器不支持相机扫码，请使用真机或手动输入设备 ID。'
            : 'iOS Simulator does not support camera scanning. Use a real device or enter the device ID manually.';
    final overlayText =
        _scannerUnavailable ? unavailableMessage : widget.subtitle;

    if (isSimulator) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: Text(
                    unavailableMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
            errorBuilder: (context, error) {
              _markScannerUnavailable();
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white70,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isZh ? '无法使用相机' : 'Camera unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unavailableMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overlayText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_scannerUnavailable)
                        IconButton(
                          onPressed: () async {
                            await _controller.toggleTorch();
                            if (!mounted) return;
                            setState(() {
                              _torchEnabled = !_torchEnabled;
                            });
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(
                            _torchEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      overlayText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
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

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.isRecording,
    required this.controller,
    required this.onTap,
    this.isEnabled = true,
  });

  final bool isRecording;
  final bool isEnabled;
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
}

class _VoiceBar extends StatelessWidget {
  const _VoiceBar({
    required this.label,
    required this.duration,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final int? duration;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
              onTap: onTap,
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
                      isPlaying
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
              onPressed: onRemove,
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

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.value,
    required this.errorText,
    required this.hasValue,
    required this.onTap,
  });

  final String value;
  final String? errorText;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    hasError
                        ? Theme.of(context).colorScheme.error
                        : _borderColor,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: _textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
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
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).clickToUploadImageOrVideo,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentGrid extends StatelessWidget {
  const _AttachmentGrid({
    required this.attachments,
    required this.isImageFile,
    required this.onTap,
    required this.onRemove,
  });

  final List<_PendingAttachment> attachments;
  final bool Function(File file) isImageFile;
  final ValueChanged<File> onTap;
  final ValueChanged<_PendingAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: attachments.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        final file = attachment.file;
        final isImage = isImageFile(file);

        return InkWell(
          onTap: () => onTap(file),
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isImage)
                  Image.file(file, fit: BoxFit.cover)
                else
                  Container(
                    color: const Color(0xFFEAF3FF),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: _brandColor,
                      size: 34,
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: const Color(0x75000000),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => onRemove(attachment),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    color: const Color(0x75000000),
                    child: Text(
                      file.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                if (attachment.isUploading)
                  Container(
                    color: const Color(0x66000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              value: attachment.progressValue,
                              strokeWidth: 2.6,
                              color: Colors.white,
                            ),
                          ),
                          if ((attachment.progressText ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                attachment.progressText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (attachment.progressValue != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${(attachment.progressValue! * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentActionTile extends StatelessWidget {
  const _AttachmentActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _brandColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}
