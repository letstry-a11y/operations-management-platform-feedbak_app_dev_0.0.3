import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 焦点节点，用于管理键盘显示
  final _oldPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // 添加焦点监听器，用于键盘管理
    _oldPasswordFocusNode.addListener(_onOldPasswordFocusChange);
    _newPasswordFocusNode.addListener(_onNewPasswordFocusChange);
    _confirmPasswordFocusNode.addListener(_onConfirmPasswordFocusChange);
  }

  /// 各个输入框焦点变化处理方法
  void _onOldPasswordFocusChange() {
    if (_oldPasswordFocusNode.hasFocus) _showKeyboard();
  }

  void _onNewPasswordFocusChange() {
    if (_newPasswordFocusNode.hasFocus) _showKeyboard();
  }

  void _onConfirmPasswordFocusChange() {
    if (_confirmPasswordFocusNode.hasFocus) _showKeyboard();
  }

  /// 强制显示键盘（解决某些设备上键盘不弹出的问题）
  void _showKeyboard() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future.delayed(Duration(milliseconds: 150), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput.invokeMethod('TextInput.show').catchError((
            e,
          ) {
            print('TextInput.show failed: $e');
          });
        } catch (e) {
          print('Force show keyboard exception: $e');
        }
      });

      Future.delayed(Duration(milliseconds: 300), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput
              .invokeMethod('TextInput.show')
              .catchError((_) {});
        } catch (e) {
          // 忽略错误
        }
      });
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

  @override
  void dispose() {
    // 移除焦点监听器，防止内存泄漏
    _oldPasswordFocusNode.removeListener(_onOldPasswordFocusChange);
    _newPasswordFocusNode.removeListener(_onNewPasswordFocusChange);
    _confirmPasswordFocusNode.removeListener(_onConfirmPasswordFocusChange);

    // 释放焦点节点
    _oldPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 提交密码修改
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await HttpService().post(
          'user/changePwd',
          body: {
            'oldPassword': _oldPasswordController.text,
            'newPassword': _newPasswordController.text,
          },
        );

        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 200) {
          ToastUtils.showSuccess(context, S.of(context).passwordChangeSuccess);
          HttpService().clearToken();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          ToastUtils.showError(
            context,
            responseData['message'] ?? S.of(context).changeFailed,
          );
        }
      } catch (e) {
        ToastUtils.showError(
          context,
          e is HttpException ? e.message : S.of(context).changeFailed,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 构建每个密码输入框
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onFieldSubmitted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: !visible,
        keyboardType: TextInputType.text,
        textInputAction: textInputAction,
        enableInteractiveSelection: true,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
        ),
        onTap: () {
          Future.microtask(() {
            focusNode.requestFocus();
            _showKeyboard();
          });
        },
        onFieldSubmitted:
            onFieldSubmitted != null
                ? (_) => onFieldSubmitted()
                : (value) {
                  if (textInputAction == TextInputAction.next) {
                    // 移动到下一个输入框的逻辑需要根据实际情况处理
                  } else {
                    _hideKeyboard();
                  }
                },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text(S.of(context).changePassword),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Color(0xFF042A72),
      ),
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
            padding: padding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).pleaseFillInfo,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),

                  // 原密码
                  _buildPasswordField(
                    label: S.of(context).oldPassword,
                    controller: _oldPasswordController,
                    focusNode: _oldPasswordFocusNode,
                    visible: _oldPasswordVisible,
                    onToggle:
                        () => setState(
                          () => _oldPasswordVisible = !_oldPasswordVisible,
                        ),
                    validator:
                        (val) =>
                            (val == null || val.isEmpty)
                                ? S.of(context).pleaseEnterOldPassword
                                : null,
                    onFieldSubmitted:
                        () => _newPasswordFocusNode.requestFocus(),
                  ),

                  // 新密码
                  _buildPasswordField(
                    label: S.of(context).newPassword,
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    visible: _newPasswordVisible,
                    onToggle:
                        () => setState(
                          () => _newPasswordVisible = !_newPasswordVisible,
                        ),
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return S.of(context).pleaseEnterNewPassword;
                      if (val.length < 6) return S.of(context).passwordAtLeast6;
                      return null;
                    },
                    onFieldSubmitted:
                        () => _confirmPasswordFocusNode.requestFocus(),
                  ),

                  // 确认密码
                  _buildPasswordField(
                    label: S.of(context).confirmNewPassword,
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    visible: _confirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onToggle:
                        () => setState(
                          () =>
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible,
                        ),
                    validator: (val) {
                      if (val != _newPasswordController.text)
                        return S.of(context).passwordsNotMatch;
                      return null;
                    },
                    onFieldSubmitted: () => _hideKeyboard(),
                  ),

                  const SizedBox(height: 24),

                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon:
                          _isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(Icons.save), // 普通状态下显示保存图标
                      label: Text(
                        _isLoading
                            ? S.of(context).submitting
                            : S.of(context).submitChange,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF042A72), // 深蓝
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
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
