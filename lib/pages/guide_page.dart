import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/providers/language_provider.dart';
import 'package:medbot_ai_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  String _selectedLanguage = 'en'; // 只做UI展示，不真正切换

  @override
  void initState() {
    super.initState();
    // 获取当前语言设置 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = Localizations.localeOf(context);
      setState(() {
        _selectedLanguage = currentLocale.languageCode;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听语言变化
    final currentLocale = Localizations.localeOf(context);
    if (_selectedLanguage != currentLocale.languageCode) {
      setState(() {
        _selectedLanguage = currentLocale.languageCode;
      });
    }
  }

  List<Map<String, String>> get _languages => [
    {'code': 'zh', 'label': S.of(context).chinese},
    {'code': 'en', 'label': S.of(context).english},
    // {'code': 'zh_Hans', 'label': '简体中文'},
    // {'code': 'zh_Hant', 'label': '繁體中文'},
    // {'code': 'ja', 'label': '日本語'},
    // {'code': 'ko', 'label': '한국어'},
    // {'code': 'fr', 'label': 'Français'},
    // {'code': 'it', 'label': 'Italiano'},
    // {'code': 'ru', 'label': 'Русский'},
    // {'code': 'es', 'label': 'Español'},
  ];

  String _getCopyright() {
    return S.of(context).copyright;
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children:
              _languages.map((lang) {
                return RadioListTile<String>(
                  value: lang['code']!,
                  groupValue: _selectedLanguage,
                  title: Text(lang['label']!),
                  onChanged: (value) async {
                    print("Language selection: $value");
                    setState(() => _selectedLanguage = value!);

                    // 等待语言切换完成
                    await Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).setLocale('$value');

                    print("Language switch completed, closing dialog");
                    Navigator.pop(context);
                  },
                );
              }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE5E5E5))),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      /// 左侧占位（保持 Logo 居中用）
                      const Expanded(child: SizedBox()),

                      ///  居中 Logo
                      Image.asset(
                        "assets/images/logo/medbot_icon.png",
                        width: 521 * 0.3,
                        height: 80,
                      ),

                      ///  右侧语言按钮
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            _showLanguagePicker();
                          },
                          child: Image.asset(
                            "assets/images/logo/language.png",
                            width: 146 * 0.6,
                            height: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 60),
                Image.asset(
                  "assets/images/device/s_images_device_bg.png",
                  fit: BoxFit.contain,
                  height: 240,
                ),
                const SizedBox(height: 5),
                // 分割线
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 18), // 左右间距
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent, // 左端透明
                        const Color(0xFFB4B4B4), // 中间颜色
                        Colors.transparent, // 右端透明
                      ],
                      stops: const [0.0, 0.5, 1.0], // 渐变位置
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        S.of(context).recognizeQRCode,
                                      ),
                                      content: Text(
                                        S.of(context).qrCodeDetectedGoToWebsite,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text(S.of(context).cancel),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            final Uri _url = Uri.parse(
                                              'https://www.medbotsurgical.com/',
                                            );
                                            if (await canLaunchUrl(_url)) {
                                              await launchUrl(
                                                _url,
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            }
                                          },
                                          child: Text(S.of(context).confirm),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEFEFEF),
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // 圆角
                                  ),
                                  child: Image.asset(
                                    "assets/images/code/website1.png",
                                    fit: BoxFit.contain,
                                    width: 90,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Text(
                                    S.of(context).checkCode,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF3A3A3A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Image.asset(
                                  "assets/images/logo/medbot.png",
                                  height: 9,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(S.of(context).ceoLinkedin),
                                      content: Text(
                                        S.of(context).ceoLinkedinConfirm,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text(S.of(context).cancel),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            final Uri _url = Uri.parse(
                                              'http://linkedin.com/in/chao-he-084b4510b',
                                            );
                                            if (await canLaunchUrl(_url)) {
                                              await launchUrl(
                                                _url,
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            }
                                          },
                                          child: Text(S.of(context).confirm),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEFEFEF),
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ), // 圆角
                                  ),
                                  child: Image.asset(
                                    "assets/images/code/ceo1.png",
                                    fit: BoxFit.contain,
                                    width: 90,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Text(
                                    S.of(context).checkLinkCode,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF3A3A3A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Image.asset(
                                  "assets/images/code/Linkedin.png",
                                  height: 10,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          S.of(context).serviceEmail,
                          style: const TextStyle(
                            color: Color(0xFFA3A3A3),
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _getCopyright(),
                          style: const TextStyle(
                            color: Color(0xFFA3A3A3),
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Positioned(
          //   bottom: MediaQuery.of(context).padding.bottom + 20,
          //   right: 20,
          //   child: FloatingActionButton(
          //     onPressed: () {
          //       // 判断有没有登录 ，没有登录跳转登录界面，登录进主页
          //       final userModel = Provider.of<UserProvider>(
          //         context,
          //         listen: false,
          //       );
          //       String path = userModel.isLoggedIn ? "/" : "/login";
          //       print("userModel.isLoggedIn : ${userModel.isLoggedIn}");
          //       Navigator.pushReplacementNamed(context, path);
          //     },
          //     backgroundColor: Theme.of(context).primaryColor,
          //     foregroundColor: Colors.white,
          //     child: const Icon(Icons.arrow_circle_right_outlined),
          //   ),
          // ),
        ],
      ),
    );
  }
}
