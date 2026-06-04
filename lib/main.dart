import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:medbot_ai_app/pages/feedback/chat_page.dart';
import 'package:medbot_ai_app/pages/feedback/device_select.dart';
import 'package:medbot_ai_app/pages/feedback/feedback_form.dart';
import 'package:medbot_ai_app/pages/feedback/speak_page.dart';
import 'package:medbot_ai_app/pages/feedback/voice_input_page.dart';
import 'package:medbot_ai_app/pages/guide_page.dart';
import 'package:medbot_ai_app/pages/login/change_password.dart';
import 'package:medbot_ai_app/pages/login/country_picker.dart';
import 'package:medbot_ai_app/pages/login/destroy_account.dart';
import 'package:medbot_ai_app/pages/login/forget_password.dart';
import 'package:medbot_ai_app/pages/login/login_page.dart';
import 'package:medbot_ai_app/pages/login/register_page.dart';
import 'package:medbot_ai_app/pages/main_page.dart';
import 'package:medbot_ai_app/pages/mine/feedback_detail.dart';
import 'package:medbot_ai_app/pages/mine/feedback_edit.dart';
import 'package:medbot_ai_app/pages/mine/feedback_list.dart';
import 'package:medbot_ai_app/pages/mine/device_management_page.dart';
import 'package:medbot_ai_app/pages/mine/user_edit.dart';
import 'package:medbot_ai_app/pages/profile_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medbot_ai_app/generated/l10n.dart'; // 这是生成的语言包文件
import 'package:medbot_ai_app/providers/language_provider.dart';
import 'package:medbot_ai_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:medbot_ai_app/utils/navigation_service.dart';
import 'package:medbot_ai_app/utils/http_service.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF6F8FB),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  List<String> _fontFallbackForPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const ['SF Pro Text', 'PingFang SC', 'Helvetica Neue', 'Arial'];
      case TargetPlatform.android:
        return const ['Roboto', 'Noto Sans SC', 'Droid Sans', 'Arial'];
      default:
        return const ['Roboto', 'PingFang SC', 'Arial'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontFallback = _fontFallbackForPlatform();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadLanguage(),
        ), // 语言管理
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loadUserFromPrefs(),
        ), // 👈 加入用户状态
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          // 同步语言设置到 HttpService
          HttpService().setLanguage(languageProvider.locale.languageCode);
          return MaterialApp(
            debugShowCheckedModeBanner: false, // 关闭右上角的 debug 标签
            navigatorKey: NavigationService.navigatorKey,
            // 使用从 LanguageProvider 获取的语言设置
            locale: languageProvider.locale,
            localizationsDelegates: const [
              S.delegate, // 语言包代理
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // 支持的语言环境列表
            supportedLocales: const [
              Locale('en', ''), // 英语
              Locale('zh', ''), // 中文简体
            ],
            title: 'Medbot AI',
            theme: ThemeData(
              useMaterial3: true,
              fontFamilyFallback: fontFallback,
              scaffoldBackgroundColor: const Color(0xFFF6F8FB),
              primaryColor: const Color(0xFF042A72),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF042A72),
                primary: const Color(0xFF042A72),
                secondary: const Color(0xFF12A594),
                surface: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF042A72),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF042A72),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF9AA8BC),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFD8DEE9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFD8DEE9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF042A72), width: 1.4),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFD64545)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFD64545), width: 1.4),
                ),
                prefixIconColor: Color(0xFF697386),
                suffixIconColor: Color(0xFF697386),
                labelStyle: TextStyle(color: Color(0xFF697386)),
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => MainPage(),
              // '/': (context) {
              //   final userModel = Provider.of<UserProvider>(context);
              //   return userModel.isLoggedIn
              //       ? MainPage()
              //       : const GuidePage(); // 👈 根据登录状态返回主页或登录页
              // },
              '/guide': (context) => GuidePage(),
              '/speak': (context) => IflytekIatDemo(),
              '/chat': (context) => ChatPage(),
              '/select-device': (context) => DeviceSelectionPage(),
              '/voice-feedback': (context) => const VoiceInputPage(),
              '/create-feedback': (context) => FeedbackForm(),
              '/profile': (context) => ProfilePage(),
              '/feedback_list': (context) => FeedbackListPage(),
              '/feedback_detail': (context) => FeedbackDetail(),
              '/feedback_edit': (context) => FeedbackEditPage(),
              '/device-management': (context) => const DeviceManagementPage(),
              '/login': (context) => const LoginPage(),
              '/user-edit': (context) => const UserEditPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(),
              '/change-password': (context) => const ChangePasswordPage(),
              '/destroy-account': (context) => const AccountDeletionPage(),
              '/register': (context) => const RegisterPage(),
              '/country-picker': (context) => const CountryPickerPage(),
            },
          );
        },
      ),
    );
  }
}
