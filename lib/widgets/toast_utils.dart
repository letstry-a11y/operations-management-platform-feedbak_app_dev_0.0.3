import 'package:flutter/material.dart';

class ToastUtils {
  // 显示错误提示（红色）
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 显示成功提示（绿色），返回 ScaffoldFeatureController 可监听关闭事件
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 0),
  }) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  static void handleHttpException(dynamic error, BuildContext context) {
    final message = error.toString();

    if (message.contains('[403]') || message.contains('"message":"未登录"')) {
      // 处理未登录跳转逻辑
      showError(context, '登录失效，请重新登录');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      // 处理其他异常
      debugPrint('其他错误: $message');
    }
  }
}
