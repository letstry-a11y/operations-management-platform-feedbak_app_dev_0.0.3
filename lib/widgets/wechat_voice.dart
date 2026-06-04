import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

class WeChatVoiceInput extends StatefulWidget {
  final void Function(bool isRecording)? onRecordingStateChanged;
  final void Function(String? path)? onVoiceRecorded;

  const WeChatVoiceInput({
    Key? key,
    this.onRecordingStateChanged,
    this.onVoiceRecorded,
  }) : super(key: key);

  @override
  _WeChatVoiceInputState createState() => _WeChatVoiceInputState();
}

class _WeChatVoiceInputState extends State<WeChatVoiceInput> {
  late FlutterSoundRecorder _recorder;
  late AudioPlayer _player;

  bool _isRecording = false;
  bool _isCancelled = false;
  Offset _startOffset = Offset.zero;
  String? _voicePath;
  Duration _voiceDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = AudioPlayer();
    _initPermissions();
    _player.positionStream.listen((pos) {
      setState(() => _currentPosition = pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => _voiceDuration = dur);
    });
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await _player.seek(Duration.zero);
        await _player.pause();
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _initPermissions() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _voicePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: _voicePath, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _isCancelled = false;
    });
    widget.onRecordingStateChanged?.call(true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    if (!_isCancelled && _voicePath != null) {
      await _player.setFilePath(_voicePath!);
      widget.onVoiceRecorded?.call(_voicePath);
    } else if (_voicePath != null) {
      File(_voicePath!).delete();
      widget.onVoiceRecorded?.call(null);
    }
    setState(() {
      _isRecording = false;
    });
    widget.onRecordingStateChanged?.call(false);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _startOffset = details.globalPosition;
    _startRecording();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    double offset = _startOffset.dy - details.globalPosition.dy;
    setState(() => _isCancelled = offset > 50);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _stopRecording();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  double _getVoiceWidth() {
    int sec = _voiceDuration.inSeconds.clamp(1, 60);
    return 60 + sec * 3.0;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }

  Widget _buildVoiceBubble() {
    if (_voicePath == null || _voiceDuration == Duration.zero) return SizedBox();

    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            SizedBox(width: 8),
            Stack(
              children: [
                Container(
                  width: _getVoiceWidth(),
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  width: _getVoiceWidth() *
                      (_voiceDuration.inMilliseconds == 0
                          ? 0
                          : (_currentPosition.inMilliseconds / _voiceDuration.inMilliseconds)
                              .clamp(0.0, 1.0)),
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            SizedBox(width: 8),
            Text("${_voiceDuration.inSeconds}''"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onLongPressStart: _handleLongPressStart,
            onLongPressMoveUpdate: _handleLongPressMoveUpdate,
            onLongPressEnd: _handleLongPressEnd,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '按住说话',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        _buildVoiceBubble(),
      ],
    );
  }
}
