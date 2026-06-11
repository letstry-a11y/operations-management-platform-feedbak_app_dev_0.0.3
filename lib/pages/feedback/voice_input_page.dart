import 'dart:async';

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
  /// 讯飞 IAT 单次会话上限 60s,提前 10s 自动停止留出余量(与 feedback_edit 一致)
  static const int _maxRecordSeconds = 50;

  /// 最后 N 秒进入倒计时提醒
  static const int _countdownSeconds = 10;

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

  int _elapsedSeconds = 0;
  Timer? _recordTicker;

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
      _startRecordTicker();
    };
    recognizer.onError = (error) {
      if (!mounted) return;
      _stopRecordTicker();
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

  /// 录音计时:每秒刷新;到 [_maxRecordSeconds] 自动停止并走 AI 整理流程。
  void _startRecordTicker() {
    _recordTicker?.cancel();
    _elapsedSeconds = 0;
    _recordTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _maxRecordSeconds) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = null;
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
    _stopRecordTicker();
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

    // 每次语音作为一条编号记录追加到描述;标题由 AI 总结全部内容。
    final existingDesc = _normalizeNumbering(
      (_existingContent?['description'] ?? '').toString().trim(),
    );
    final hasExisting = _fromSupplement && existingDesc.isNotEmpty;
    final nextIndex = hasExisting ? _nextRecordIndex(existingDesc) : 1;

    Map<String, dynamic> fields;
    var fallback = false;
    try {
      final parsed = await _kimi.organizeToFeedback(
        transcript,
        existingRecords: hasExisting ? existingDesc : null,
      );
      fields = _normalizeFields(parsed);
      _dropHallucinatedOccurTime(fields, parsed, transcript);
    } catch (e) {
      // ignore: avoid_print
      print('[VoicePage] kimi organize ERROR: $e');
      fields = {};
      fallback = true;
    }

    // 本次整理结果(失败则用原文)作为第 nextIndex 条记录
    final newDesc = (fields['description'] ?? '').toString().trim();
    final record = '$nextIndex. ${newDesc.isEmpty ? transcript : newDesc}';
    fields['description'] = hasExisting ? '$existingDesc\n$record' : record;
    if (fallback) {
      // 失败时不覆盖已有标题(不带 title 字段即保留第二页现状)
      fields.remove('title');
      fields['_fallback'] = true;
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

  /// occurTime 防幻觉:AI 必须同时给出口述中的时间原话摘录(occurTimeQuote),
  /// 摘录为空或在本次口述里找不到时,视为编造,丢弃 occurTime。
  void _dropHallucinatedOccurTime(
    Map<String, dynamic> fields,
    Map<String, dynamic> parsed,
    String transcript,
  ) {
    if (fields['occurTime'] == null) return;
    final quote = (parsed['occurTimeQuote'] ?? '').toString().trim();
    final mentioned = quote.isNotEmpty &&
        transcript.toLowerCase().contains(quote.toLowerCase());
    if (!mentioned) {
      // ignore: avoid_print
      print('[VoicePage] drop occurTime(quote="$quote") not in transcript');
      fields.remove('occurTime');
    }
  }

  /// 已有描述若没有任何「N.」编号(如用户手动输入),整体视作第 1 条记录。
  String _normalizeNumbering(String desc) {
    if (desc.isEmpty) return desc;
    final numbered = RegExp(r'^\s*\d+[.、]', multiLine: true).hasMatch(desc);
    return numbered ? desc : '1. $desc';
  }

  /// 取已有记录的最大序号 + 1 作为本次记录序号。
  int _nextRecordIndex(String numberedDesc) {
    var maxIndex = 0;
    for (final m in RegExp(r'^\s*(\d+)[.、]', multiLine: true)
        .allMatches(numberedDesc)) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n > maxIndex) maxIndex = n;
    }
    return maxIndex + 1;
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

  /// 跳过语音,直接进入第二页文字输入。
  /// 补充模式下第二页就在路由栈下方,直接返回(不带结果,不改动表单)。
  Future<void> _skipToTextInput() async {
    if (_isAnalyzing) return;
    if (_isRecording) {
      _stopRecordTicker();
      _stopPulse();
      setState(() => _isRecording = false);
      try {
        await _iflytek?.stopRecognition();
      } catch (_) {}
    }
    if (!mounted) return;
    if (_fromSupplement) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      '/create-feedback',
      arguments: {
        if (_productId != null) 'product_id': _productId,
        if (_feedbackType != null) 'feedback_type': _feedbackType,
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _stopRecordTicker();
    _pulse.dispose();
    _iflytek?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const primary = Color(0xFF042A72);

    final remaining = _maxRecordSeconds - _elapsedSeconds;
    final inCountdown = _isRecording && remaining <= _countdownSeconds;
    final String statusText;
    if (_isAnalyzing) {
      statusText = s.analyzing;
    } else if (_isRecording) {
      // 前 40s 只显示聆听中;最后 10s 显示自动停止倒计时
      statusText =
          inCountdown ? s.autoStopCountdown(remaining) : s.listening;
    } else {
      statusText = s.tapOrHoldToSpeak;
    }

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
              // 不想语音输入时,直接进入文字输入页(补充模式下为直接返回表单)
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isAnalyzing ? null : _skipToTextInput,
                icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                label: Text(s.skipToTextInput),
                style: TextButton.styleFrom(foregroundColor: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
