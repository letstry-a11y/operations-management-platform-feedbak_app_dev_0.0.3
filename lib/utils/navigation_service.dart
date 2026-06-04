import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void showSnack(String message) {
    final ctx = context;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  static void showAuthExpiredMessage(String _message) {
    final ctx = context;
    if (ctx == null) return;
    // Prefer a dedicated i18n key; fall back to a readable text if missing
    ScaffoldMessenger.of(ctx).showSnackBar(
      // SnackBar(content: Text('登录已过期，请重新登录')),
      SnackBar(content: Text(_message)),
    );
  }

  static void toLoginAndClear() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}


