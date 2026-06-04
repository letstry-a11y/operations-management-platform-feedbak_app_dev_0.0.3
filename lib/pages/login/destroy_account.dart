import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  // 焦点节点，用于管理键盘显示
  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();

  bool _isSendingCode = false;
  int _secondsRemaining = 0;
  Timer? _timer;
  Timer? _keyboardTimer;

  String? _codeErrorText; // 显示验证码错误提示
  bool _isRequestingCode = false;
  bool _isDestroying = false;

  @override
  void initState() {
    super.initState();
    // 添加焦点监听器，用于键盘管理
    _emailFocusNode.addListener(_onEmailFocusChange);
    _codeFocusNode.addListener(_onCodeFocusChange);
  }

  /// 各个输入框焦点变化处理方法
  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) _showKeyboard();
  }

  void _onCodeFocusChange() {
    if (_codeFocusNode.hasFocus) _showKeyboard();
  }

  /// 强制显示键盘（解决某些设备上键盘不弹出的问题）
  void _showKeyboard() {
    if (!mounted) return;
    _keyboardTimer?.cancel();
    _keyboardTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      try {
        SystemChannels.textInput.invokeMethod('TextInput.show').catchError((_) {});
      } catch (_) {}
    });
  }

  /// 隐藏键盘（通过移除所有输入框的焦点）
  void _hideKeyboard() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    try {
      SystemChannels.textInput
          .invokeMethod('TextInput.hide')
          .catchError((_) {});
    } catch (e) {
      // 忽略错误
    }
  }

  void _startCountdown() {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 120;
      _isSendingCode = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining <= 1) {
          _secondsRemaining = 0;
          _isSendingCode = false;
          timer.cancel();
          return;
        }
        _secondsRemaining--;
      });
    });
  }

  Future<void> _sendCode() async {
    if (_isSendingCode || _isRequestingCode || _isDestroying) return;
    final isValid = _emailFieldKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ToastUtils.showError(context, S.of(context).pleaseEnterValidEmail);

      return;
    }

    try {
      setState(() => _isRequestingCode = true);
      final response = await HttpService().get(
        'auth/sendCode', // 根据你实际接口调整
        params: {'email': email, 'scene': 'DESTROY'}, // type参数告诉后端这是用于账号销毁的验证码
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 200) {
        ToastUtils.showSuccess(context, '${S.of(context).codeSentTo} $email');
        if (mounted) {
          setState(() {
            _codeErrorText = null;
          });
          _startCountdown();
          _codeFocusNode.requestFocus();
        }
      } else {
        ToastUtils.showError(
          context,
          data['message'] ?? S.of(context).codeSendFailed,
        );
      }
    } catch (e) {
      ToastUtils.showError(
        context,
        e is HttpException ? e.message : S.of(context).loadException,
      );
      // ToastUtils.handleHttpException(e, context);
    } finally {
      if (mounted) {
        setState(() => _isRequestingCode = false);
      }
    }
  }

  Future<void> _destroyAccount() async {
    if (_isDestroying) return;
    final l10n = S.of(context);
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isDestroying = true);
    _hideKeyboard();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await HttpService().post(
        'user/destroy',
        body: {"code": code},
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();

      if (data is Map && data['status'] == 200) {
        ToastUtils.showSuccess(context, l10n.accountDestroyedSuccess);
        _timer?.cancel();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        ToastUtils.showError(
          context,
          data is Map ? (data['message'] ?? l10n.destroyFailed) : l10n.destroyFailed,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
      ToastUtils.showError(
        context,
        e is HttpException ? e.message : l10n.loadException,
      );
    } finally {
      if (mounted) {
        setState(() => _isDestroying = false);
      }
    }
  }

  void _submit() {
    if (_isDestroying) return;
    setState(() => _codeErrorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ToastUtils.showError(context, S.of(context).pleaseEnterValidEmail);
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(S.of(context).confirmDestroy),
            content: Text(S.of(context).confirmDestroyMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _destroyAccount();
                },
                child: Text(
                  S.of(context).confirm,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // 移除焦点监听器，防止内存泄漏
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _codeFocusNode.removeListener(_onCodeFocusChange);

    // 释放焦点节点
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();

    _emailController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    _keyboardTimer?.cancel();
    super.dispose();
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).destroyAccount)),
      backgroundColor: const Color(0xFFF7F8FA),
      resizeToAvoidBottomInset: true, // 确保键盘弹出时页面会调整
      body: GestureDetector(
        onTap: () {
          // 点击空白区域时隐藏键盘
          final focusScope = FocusScope.of(context);
          if (focusScope.hasFocus) {
            _hideKeyboard();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    S.of(context).destroyAccountWarning,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  _buildCard(
                    child: TextFormField(
                      key: _emailFieldKey, //
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        labelText: S.of(context).email,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).pleaseEnterEmail;
                        }
                        final regex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!regex.hasMatch(value)) {
                          return S.of(context).pleaseEnterValidEmail;
                        }
                        return null;
                      },
                      autovalidateMode:
                          AutovalidateMode.onUserInteraction, // 这里开启自动校验
                      onTap: () {
                        Future.microtask(() {
                          _emailFocusNode.requestFocus();
                          _showKeyboard();
                        });
                      },
                      onFieldSubmitted: (_) {
                        _codeFocusNode.requestFocus();
                      },
                    ),
                  ),
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                focusNode: _codeFocusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                enableInteractiveSelection: true,
                                decoration: InputDecoration(
                                  labelText: S.of(context).verificationCode,
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty)
                                    return S.of(context).pleaseEnterCode;
                                  return null;
                                },
                                onTap: () {
                                  Future.microtask(() {
                                    _codeFocusNode.requestFocus();
                                    _showKeyboard();
                                  });
                                },
                                onFieldSubmitted: (_) => _hideKeyboard(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  (_isSendingCode || _isRequestingCode || _isDestroying)
                                      ? null
                                      : _sendCode,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isSendingCode
                                    ? '$_secondsRemaining ${S.of(context).seconds}'
                                    : S.of(context).sendCode,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        if (_codeErrorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _codeErrorText!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isDestroying ? null : _submit,
                      label: Text(
                        S.of(context).confirmDestroy,
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 224, 2, 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
