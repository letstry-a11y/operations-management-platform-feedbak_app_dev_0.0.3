import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildCard({
    required String title,
    required List<String> descriptions,
    required Color bgColor,
    required Color titleColor,
    required Color descColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25), // 阴影颜色
              blurRadius: 4, // 阴影模糊约 4pt
              offset: const Offset(0, 2), // 阴影方向（下方）
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧图标
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(icon, color: titleColor, size: 28),
              ),

            // 分隔线
            Center(
              child: Container(
                height: 60,
                width: 1,
                color: const Color(0xFFB4B4B4),
                margin: const EdgeInsets.only(right: 12),
              ),
            ),

            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // 内容垂直居中
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      height: 1.2,
                      // fontFamily: "Arial"
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...descriptions.map(
                    (desc) => Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: descColor,
                        height: 1.2,
                        // fontFamily: 'Arial',
                        fontWeight: FontWeight.normal, // Regular 字重
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 右侧箭头
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFB4B4B4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final defectBg = Colors.white;
        final defectTitle = Color(0xFF032F54);
        final defectDesc = Color(0xFF606060);

        final demandBg = Colors.white;
        final demandTitle = Color(0xFF900000);
        final demandDesc = Color(0xFF606060);

        final otherBg = Colors.white;
        final otherTitle = Color(0xFF00633B);
        final otherDesc = Color(0xFF606060);

        return Scaffold(
          // 使用浅色渐变背景填充
          body: Container( 
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E5E5),
              // gradient: LinearGradient(
              //   colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
              //   begin: Alignment.topCenter,
              //   end: Alignment.bottomCenter,
              // ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 顶部logo
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      "assets/images/logo/medbot.png",
                      width: 352 * 0.3,
                      height: 42 * 0.3,
                    ),
                  ),
                  // 顶部标题区域
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      S.of(context).feedbackForm,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A3A3A),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      S.of(context).feedbackInstruction,
                      style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFFA3A3A3),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 可滚动卡片列表
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCard(
                            title: S.of(context).defectFeedback,
                            icon: Icons.bug_report_outlined,
                            descriptions: [
                              S.of(context).defectFeedbackDesc1,
                              S.of(context).defectFeedbackDesc2,
                            ],
                            bgColor: defectBg,
                            titleColor: defectTitle,
                            descColor: defectDesc,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/select-device",
                                arguments: {"feedback_type": "1"},
                              );
                            },
                          ),
                          _buildCard(
                            title: S.of(context).requirementFeedback,
                            icon: Icons.lightbulb_outline_rounded,
                            descriptions: [
                              S.of(context).requirementFeedbackDesc1,
                              S.of(context).requirementFeedbackDesc2,
                            ],
                            bgColor: demandBg,
                            titleColor: demandTitle,
                            descColor: demandDesc,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/select-device",
                                arguments: {"feedback_type": "2"},
                              );
                            },
                          ),
                          _buildCard(
                            title: S.of(context).otherService,
                            icon: Icons.chat_bubble_outline,
                            descriptions: [
                              S.of(context).otherServiceDesc1,
                              S.of(context).otherServiceDesc2,
                            ],
                            bgColor: otherBg,
                            titleColor: otherTitle,
                            descColor: otherDesc,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/select-device",
                                arguments: {"feedback_type": "3"},
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // 底部小文字（可选）
                  // const Padding(
                  //   padding: EdgeInsets.only(bottom: 12),
                  //   child: Text(
                  //     '© 2025 Company. All rights reserved',
                  //     style: TextStyle(fontSize: 12, color: Colors.black38),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     Navigator.pushReplacementNamed(context, "/guide");
          //   },
          //   backgroundColor: Colors.transparent,
          //   elevation: 0,
          //   splashColor: Colors.transparent,
          //   highlightElevation: 0,
          //   child: SizedBox(
          //     height: 150, // 控制整体高度，避免溢出
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         GestureDetector(
          //           onTap: () {
          //             Navigator.pushNamed(context, "/chat");
          //           },
          //           child: const CircleAvatar(
          //             backgroundImage: AssetImage(
          //               'assets/images/logo/logo.png',
          //             ),
          //             radius: 12, // 缩小头像半径
          //             backgroundColor: Colors.transparent,
          //           ),
          //         ),
          //         const SizedBox(height: 10),
          //         const Icon(Icons.arrow_back, size: 18, color: Colors.teal),
          //       ],
          //     ),
          //   ),
          // ),
        );
      },
    );
  }
}
