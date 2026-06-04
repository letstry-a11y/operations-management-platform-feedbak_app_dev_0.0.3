import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/loading_button.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pwdController = TextEditingController();
  final _confirmController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController(); // 新增

  // 焦点节点，用于管理键盘显示
  final _codeFocusNode = FocusNode();
  final _pwdFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _pwdVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // _pwdController.text = "123456";
    // _confirmController.text = "123456";
    
    // 添加焦点监听器，用于键盘管理
    _codeFocusNode.addListener(_onCodeFocusChange);
    _pwdFocusNode.addListener(_onPwdFocusChange);
    _confirmFocusNode.addListener(_onConfirmFocusChange);
  }

  /// 验证码输入框焦点变化处理
  void _onCodeFocusChange() {
    if (_codeFocusNode.hasFocus) {
      _showKeyboard();
    }
  }

  /// 新密码输入框焦点变化处理
  void _onPwdFocusChange() {
    if (_pwdFocusNode.hasFocus) {
      _showKeyboard();
    }
  }

  /// 确认密码输入框焦点变化处理
  void _onConfirmFocusChange() {
    if (_confirmFocusNode.hasFocus) {
      _showKeyboard();
    }
  }

  /// 强制显示键盘（解决某些设备上键盘不弹出的问题）
  void _showKeyboard() {
    if (!mounted) return;
    
    // 确保在下一帧后执行，让焦点先设置完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // 延迟后通过系统通道强制显示键盘
      Future.delayed(Duration(milliseconds: 150), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput.invokeMethod('TextInput.show').catchError((e) {
            print('TextInput.show failed: $e');
          });
        } catch (e) {
          print('Force show keyboard exception: $e');
        }
      });
      
      // 再次延迟尝试（有些设备需要更长时间）
      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput.invokeMethod('TextInput.show').catchError((_) {});
        } catch (e) {
          // 忽略第二次尝试的错误
        }
      });
    });
  }

  /// 隐藏键盘（通过移除所有输入框的焦点）
  void _hideKeyboard() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide').catchError((_) {});
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从路由中获取参数
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final email = args?['email'] ?? '';
    _emailController.text = email;
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final pwd = _pwdController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty) {
      ToastUtils.showError(context, S.of(context).emailCannotBeEmpty);
      return;
    }
    if (code.isEmpty) {
      ToastUtils.showError(context, S.of(context).pleaseEnterCode);
      return;
    }
    if (pwd.isEmpty) {
      ToastUtils.showError(context, S.of(context).pleaseEnterNewPassword);
      return;
    }
    if (confirm.isEmpty) {
      ToastUtils.showError(context, S.of(context).confirmNewPassword);
      return;
    }
    if (pwd != confirm) {
      ToastUtils.showError(context, S.of(context).passwordsNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await HttpService().post(
        'auth/resetPwd',
        body: {'email': email, 'code': code, 'newPassword': pwd},
      );

      final data = jsonDecode(response.body);
      if (data['code'] == 0) {
        ToastUtils.showSuccess(context, S.of(context).passwordChangeSuccess);
        // 跳转到登录页，清除导航栈
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } else {
        ToastUtils.showError(context, data['message'] ?? S.of(context).changeFailed);
      }
    } catch (e) {

      ToastUtils.showError(context,  e is HttpException ? e.message : S.of(context).loadFailed);
    } finally {
      setState(() => _isLoading = false); // loading 结束
    }
  }

  @override
  void dispose() {
    // 移除焦点监听器，防止内存泄漏
    _codeFocusNode.removeListener(_onCodeFocusChange);
    _pwdFocusNode.removeListener(_onPwdFocusChange);
    _confirmFocusNode.removeListener(_onConfirmFocusChange);
    
    // 释放焦点节点
    _codeFocusNode.dispose();
    _pwdFocusNode.dispose();
    _confirmFocusNode.dispose();
    
    _pwdController.dispose();
    _confirmController.dispose();
    _codeController.dispose();
    _emailController.dispose(); // 清理
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).changePassword)),
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
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 邮箱字段（只读）
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: S.of(context).email,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 验证码
            TextFormField(
              controller: _codeController,
              focusNode: _codeFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: S.of(context).emailVerificationCode,
                prefixIcon: const Icon(Icons.verified_user_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                Future.microtask(() {
                  _codeFocusNode.requestFocus();
                  _showKeyboard();
                });
              },
              onFieldSubmitted: (_) {
                _pwdFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 16),

            // 新密码
            TextFormField(
              controller: _pwdController,
              focusNode: _pwdFocusNode,
              obscureText: !_pwdVisible,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: S.of(context).newPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _pwdVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _pwdVisible = !_pwdVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                Future.microtask(() {
                  _pwdFocusNode.requestFocus();
                  _showKeyboard();
                });
              },
              onFieldSubmitted: (_) {
                _confirmFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 16),

            // 确认密码
            TextFormField(
              controller: _confirmController,
              focusNode: _confirmFocusNode,
              obscureText: !_confirmVisible,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: true,
              decoration: InputDecoration(
                labelText: S.of(context).confirmNewPassword,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _confirmVisible = !_confirmVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                Future.microtask(() {
                  _confirmFocusNode.requestFocus();
                  _showKeyboard();
                });
              },
              onFieldSubmitted: (_) {
                _hideKeyboard();
              },
            ),
            const SizedBox(height: 24),

            // 提交按钮
            LoadingButton(
              loading: _isLoading,
              label: S.of(context).submitChange,
              onPressed: _submit,
            ),
            // SizedBox(
            //   width: double.infinity,
            //   height: 48,
            //   child: ElevatedButton.icon(
            //     icon:
            //         _isLoading
            //             ? SizedBox(
            //               width: 20,
            //               height: 20,
            //               child: CircularProgressIndicator(
            //                 strokeWidth: 2,
            //                 valueColor: AlwaysStoppedAnimation<Color>(
            //                   Colors.white,
            //                 ),
            //               ),
            //             )
            //             : Icon(Icons.save), // 普通状态下显示保存图标
            //     label: Text(_isLoading ? '提交中...' : '提交修改'),
            //     onPressed: _isLoading ? null : _submit,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFF042A72), // 深蓝
            //       foregroundColor: Colors.white,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       elevation: 3,
            //     ),
            //   ),
            // ),
          ],
        ),
        ),
      ),
    );
  }
}
