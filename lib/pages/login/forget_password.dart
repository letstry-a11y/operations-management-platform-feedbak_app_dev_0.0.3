import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medbot_ai_app/pages/login/reset_password.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool isSending = false;
  int countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // _emailController.text = "nndhysc@163.com";
  }

  bool isEmailValid(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  void startCountdown() {
    setState(() => countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  // void _sendCode() {
  //   if (_formKey.currentState!.validate()) {
  //     if (countdown > 0) return;

  //     setState(() => isSending = true);
  //     // 模拟验证码发送
  //     Future.delayed(const Duration(seconds: 1), () {
  //       setState(() => isSending = false);
  //       startCountdown();
  //       if (mounted) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
  //         );
  //       }
  //     });
  //   }
  // }

  void _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    if (countdown > 0) return;

    setState(() => isSending = true);

    try {
      // 示例：调用接口发送验证码
      final response = await HttpService().get(
        'auth/sendCode', // 根据你实际接口调整
        params: {'email': _emailController.text.trim(), 'scene': 'RESET'},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 200) {
        ToastUtils.showSuccess(context, S.of(context).codeSentSuccess);
        startCountdown(); // 开始倒计时

        if (mounted) {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          // );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ResetPasswordPage(),
              settings: RouteSettings(
                arguments: {'email': _emailController.text.trim()},
              ), // 👈 替换为你的邮箱
            ),
          );
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
        e is HttpException ? e.message : S.of(context).codeSendFailed,
      );

      // ToastUtils.handleHttpException(e, context);
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).forgotPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: S.of(context).pleaseEnterRegisteredEmail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return S.of(context).emailCannotBeEmpty;
                  if (!isEmailValid(value))
                    return S.of(context).pleaseEnterValidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (countdown == 0 && !isSending) ? _sendCode : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    countdown > 0
                        ? '${S.of(context).pleaseWait} ($countdown s)'
                        : S.of(context).getCodeAndNext,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              countdown > 0
                  ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResetPasswordPage(),
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(S.of(context).next),
                    ),
                  )
                  : const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
