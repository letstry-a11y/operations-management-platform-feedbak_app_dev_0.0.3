import 'package:flutter/material.dart';
import 'package:medbot_ai_app/pages/guide_page.dart';
import 'package:medbot_ai_app/pages/home_page.dart';
import 'package:medbot_ai_app/pages/profile_page.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const GuidePage(),
    const HomePage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.blue : Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNavItemIcons(
    String normalIcon,
    String activeIcon,
    String txt,
    int index,
  ) {
    final bool isSelected = _selectedIndex == index;
    final String iconPath = isSelected ? activeIcon : normalIcon;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(28), // 和子项背景圆角匹配
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5E5E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // 水平居中
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
            children: [
              Image.asset(iconPath, height: 18, fit: BoxFit.contain),
              SizedBox(width: 4),
              Text(
                txt,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color:
                      isSelected
                          ? const Color(0xFF032F54)
                          : const Color(0xFF606060),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          backgroundColor: Color(0xFFE5E5E5),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Material(
                  color: Colors.white,
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItemIcons(
                          "assets/images/navbar/link_icon.png",
                          "assets/images/navbar/link_icon_active.png",
                          S.of(context).link,
                          0,
                        ),
                        _buildNavItemIcons(
                          "assets/images/navbar/home_icon.png",
                          "assets/images/navbar/home_icon_active.png",
                          S.of(context).home,
                          1,
                        ),
                        _buildNavItemIcons(
                          "assets/images/navbar/mine_icon.png",
                          "assets/images/navbar/mine_icon_active.png",
                          S.of(context).profilePage,
                          2,
                        ),
                        // _buildNavItem(Icons.link, S.of(context).link, 0),
                        // _buildNavItem(Icons.home, S.of(context).home, 1),
                        // _buildNavItem(Icons.person, S.of(context).profilePage, 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
