import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/kimi_client.dart';
import 'package:medbot_ai_app/utils/speech_recognizer.dart';

/// 第一页:语音输入页(统一使用讯飞识别)
///
/// 识别:讯飞 SpeechRecognizer(后端 ws/speech)——真机与模拟器一致。
/// 整理:松手后把识别文本交给 Kimi 整理为结构化 JSON(交互期 App 直连,
///       正式版应迁移到后端)。
///
/// 交互:长按说话松手结束 / 点击开始再点结束。
///
/// 路由参数(arguments, Map):
/// - product_id / feedback_type : 透传给第二页
/// - from_supplement: bool       : 补充模式(从第二页「继续补充」进入)
/// - existing_content: Map        : 第二页当前内容 {title, description}
class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({super.key});

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage>
    with SingleTickerProviderStateMixin {
  final KimiClient _kimi = KimiClient();
  SpeechRecognizer? _iflytek;

  bool _paramsLoaded = false;
  bool _fromSupplement = false;
  Map<String, dynamic>? _existingContent;
  String? _productId;
  String? _feedbackType;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  String _transcript = '';

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _initIflytek();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paramsLoaded) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _fromSupplement = args['from_supplement'] == true;
      _existingContent =
          (args['existing_content'] as Map?)?.cast<String, dynamic>();
      _productId = args['product_id']?.toString();
      _feedbackType = args['feedback_type']?.toString();
    }
    _paramsLoaded = true;
  }

  void _initIflytek() {
    if (_iflytek != null) return;
    final recognizer =
        SpeechRecognizer(appId: '397dfc06', apiKey: '', apiSecret: '');
    recognizer.onResult = (text) {
      if (!mounted || text.isEmpty) return;
      setState(() => _transcript += text);
    };
    recognizer.onStart = () {
      if (!mounted) return;
      setState(() => _isRecording = true);
      _pulse.repeat(reverse: true);
    };
    recognizer.onError = (error) {
      if (!mounted) return;
      _stopPulse();
      setState(() => _isRecording = false);
      _showSnack('${S.of(context).recognitionError}: $error');
    };
    recognizer.onAudioSaved = (_, __) {
      // 结束由 _stopRecording 显式驱动
    };
    _iflytek = recognizer;
    recognizer.init();
  }

  void _stopPulse() {
    _pulse.stop();
    _pulse.reset();
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isAnalyzing) return;
    setState(() => _transcript = '');
    if (_iflytek == null) _initIflytek();
    try {
      await _iflytek?.startRecognition(); // onStart 内置 setState
    } catch (e) {
      if (!mounted) return;
      _stopPulse();
      setState(() => _isRecording = false);
      _showSnack('${S.of(context).recordingStartFailed}: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _stopPulse();
    setState(() => _isRecording = false);
    try {
      await _iflytek?.stopRecognition(); // 完成后(含最终识别结果)再整理
    } catch (_) {}
    _onRecordingFinished();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _onRecordingFinished() {
    if (!mounted) return;
    final transcript = _transcript.trim();
    if (transcript.isEmpty) {
      _showSnack(S.of(context).voiceEmptyHint);
      return;
    }
    _analyzeAndGo(transcript);
  }

  Future<void> _analyzeAndGo(String transcript) async {
    setState(() => _isAnalyzing = true);

    // 补充模式:把第二页现有内容 + 新语音一起送 Kimi,语义合并去重
    String content = transcript;
    if (_fromSupplement && _existingContent != null) {
      final existingTitle = (_existingContent!['title'] ?? '').toString();
      final existingDesc = (_existingContent!['description'] ?? '').toString();
      final existing = [existingTitle, existingDesc]
          .where((e) => e.trim().isNotEmpty)
          .join('\n');
      if (existing.isNotEmpty) {
        content = '已有反馈内容:\n$existing\n\n补充内容:\n$transcript\n\n'
            '请将以上内容合并去重,输出完整的结构化反馈。';
      }
    }

    Map<String, dynamic> fields;
    try {
      final parsed = await _kimi.organizeToFeedback(content);
      fields = _normalizeFields(parsed);
    } catch (e) {
      // ignore: avoid_print
      print('[VoicePage] kimi organize ERROR: $e');
      fields = {'description': transcript, '_fallback': true};
    }
    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (fields['_fallback'] == true) {
      _showSnack(S.of(context).analyzeFailedFallback);
    }

    if (_fromSupplement) {
      Navigator.of(context).pop(fields);
    } else {
      Navigator.of(context).pushReplacementNamed(
        '/create-feedback',
        arguments: {
          if (_productId != null) 'product_id': _productId,
          if (_feedbackType != null) 'feedback_type': _feedbackType,
          'ai_fields': fields,
          'raw_transcript': transcript,
        },
      );
    }
  }

  /// 把 AI 返回 Map 归一化为第二页可识别的字段名。
  Map<String, dynamic> _normalizeFields(Map<String, dynamic> m) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    return {
      if (pick(['title', '标题', 'problemTitle']) != null)
        'title': pick(['title', '标题', 'problemTitle']),
      if (pick(['description', 'desc', '描述', 'content']) != null)
        'description': pick(['description', 'desc', '描述', 'content']),
      if (pick(['occurTime', 'occur_time', 'time', '发生时间']) != null)
        'occurTime': pick(['occurTime', 'occur_time', 'time', '发生时间']),
      if (m['_fallback'] == true) '_fallback': true,
    };
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _iflytek?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const primary = Color(0xFF042A72);
    final statusText = _isAnalyzing
        ? s.analyzing
        : (_isRecording ? s.listening : s.tapOrHoldToSpeak);

    return Scaffold(
      appBar: AppBar(title: Text(s.voiceInputTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                s.voiceInputSubtitle,
                style: const TextStyle(fontSize: 15, color: Color(0xFF697386)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8DEE9)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _transcript,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _isAnalyzing ? null : _toggleRecording,
                  onLongPressStart:
                      _isAnalyzing ? null : (_) => _startRecording(),
                  onLongPressEnd: _isAnalyzing ? null : (_) => _stopRecording(),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale =
                          _isRecording ? 1 + _pulse.value * 0.08 : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? const Color(0xFFD64545)
                            : primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? const Color(0xFFD64545)
                                    : primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isAnalyzing
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF9AA8BC)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.voicePreliminaryHint,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9AA8BC)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
