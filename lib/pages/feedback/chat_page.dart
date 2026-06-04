// chat_page_with_voice.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/chat_stream_client.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/utils/speech_recognizer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final ChatStreamClient client = ChatStreamClient(
    serverUrl: 'http://139.196.125.119:8080/api/app',
  );
  final String appId = '397dfc06';
  final String apiKey = '';
  final String apiSecret = '';

  SpeechRecognizer? _sr;

  List<_ChatMessage> messages = [];
  StreamSubscription<String>? _subscription;
  bool _isThinking = false;
  bool _isVoiceMode = false;
  bool _voiceActive = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(() => setState(() {}));
    _sr = SpeechRecognizer(
      appId: appId,
      apiKey: apiKey,
      apiSecret: apiSecret,
      onResult: (text) {
        print("onResult ======================================== $text");
        controller.text = text;
        sendQuestion();
      },
      onStart: () {
        print("123123");
        setState(() => _voiceActive = true);
      },
      onStop: () {
        setState(() => _voiceActive = false);
        sendQuestion();
      },
      onError:
          (e) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${S.of(context).recognitionError}: $e'))),
    );
    _sr!.init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller.dispose();
    scrollController.dispose();
    _sr?.dispose();
    super.dispose();
  }

  Stream<String> slowStream(Stream<String> input) async* {
    await for (final word in input) {
      yield word;
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void sendQuestion() {
    final question = controller.text.trim();
    if (question.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      messages.add(
        _ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
      );
      messages.add(
        _ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );
      _isThinking = true;
      controller.clear();
    });

    _subscription?.cancel();
    _subscription = slowStream(
      client.askQuestion(
        question,
        token: HttpService().token,
      ),
    ).listen(
      (word) {
        if (!mounted) return;
        setState(() => messages.last.text += word);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent + 100,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onError:
          (e) {
            if (!mounted) return;
            setState(() {
              messages.last.text = '❌ ${S.of(context).error}: $e';
              _isThinking = false;
            });
          },
      onDone: () {
        if (!mounted) return;
        setState(() => _isThinking = false);
      },
    );
  }

  void toggleVoiceMode() => setState(() => _isVoiceMode = !_isVoiceMode);

  // Widget _buildInputBar() {
  //   if (_isVoiceMode) {
  //     return Row(
  //       children: [
  //         Expanded(
  //           child: GestureDetector(
  //             onLongPress: () => _sr?.startRecognition(),
  //             onLongPressUp: () => _sr?.stopRecognition(),
  //             child: Container(
  //               alignment: Alignment.center,
  //               padding: const EdgeInsets.symmetric(vertical: 14),
  //               decoration: BoxDecoration(
  //                 color: _voiceActive ? Colors.red[100] : Colors.blue[100],
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: Text(_voiceActive ? '松开结束' : '长按说话'),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         IconButton(
  //           icon: const Icon(Icons.keyboard),
  //           onPressed: toggleVoiceMode,
  //         ),
  //       ],
  //     );
  //   }
  Widget _buildInputBar() {
    if (_isVoiceMode) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () {
                _sr?.startRecognition();
                setState(() => _voiceActive = true);
              },
              onLongPressUp: () {
                _sr?.stopRecognition();
                setState(() => _voiceActive = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _voiceActive
                            ? [Color(0xFFFFD6E8), Color(0xFFFFB6C1)]
                            : [Color(0xFFB5F8D0), Color(0xFFB0E0E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _voiceActive ? Icons.mic : Icons.mic_none,
                        color: _voiceActive ? Colors.pinkAccent : Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _voiceActive ? S.of(context).releaseToEnd : S.of(context).longPressToSpeak,
                        style: TextStyle(
                          color:
                              _voiceActive
                                  ? Colors.pink[700]
                                  : Colors.teal[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: toggleVoiceMode,
            tooltip: S.of(context).switchToKeyboard,
          ),
        ],
      );
    }

    final hasText = controller.text.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => sendQuestion(),
            decoration: InputDecoration(
              hintText: S.of(context).pleaseEnterContent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        hasText
            ? IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: sendQuestion,
            )
            : IconButton(
              icon: const Icon(Icons.mic, color: Colors.blue),
              onPressed: toggleVoiceMode,
            ),
      ],
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final isUser = message.isUser;
    final bgColor = isUser ? Colors.blue[100] : Colors.grey[200];
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius =
        isUser
            ? const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            );
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/logo/logo.png'),
            radius: 20,
          ),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(color: bgColor, borderRadius: radius),
                child: MarkdownBody(
                  data: message.text,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        if (isUser) const SizedBox(width: 8),
        if (isUser)
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildLoadingBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundImage: AssetImage('assets/images/logo/logo.png'),
          radius: 20,
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              topLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            S.of(context).thinking,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).medbotAiAssistant),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == messages.length)
                  return _buildLoadingBubble();
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
