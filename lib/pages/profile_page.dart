import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medbot_ai_app/data/constants/user_options.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/providers/language_provider.dart';
import 'package:medbot_ai_app/providers/user_provider.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _ready = false;
  Map<String, dynamic> _userInfo = {};

  String _deviceManagementLabel(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '设备管理' : 'Device Management';
  }

  @override
  void initState() {
    super.initState();
    _ensureUserInfo();
  }

  Future<void> _ensureUserInfo() async {
    try {
      final res = await HttpService().get('user/info');
      final result = jsonDecode(res.body) as Map<String, dynamic>;
      print('user/info: $result');
      if (!mounted) return;
      if (result['status'] == 200) {
        final data = result['data'] as Map<String, dynamic>;
        print('data; $data');
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // userProvider.setProfile(data);
        await userProvider.setProfile(data);
        print('userProvider.profile; ${userProvider.profile}');
        setState(() {
          _loading = false;
          _ready = true;
          _userInfo = data;
        });
      } else {
        setState(() {
          _loading = false;
          _ready = false;
        });
      }
      // else if (result['status'] == 10507 || result['status'] == 10506) {
      //   print('Token invalid or expired, logging out');
      //   // token 无效或过期，直接登出
      //   final userProvider = Provider.of<UserProvider>(context, listen: false);
      //   userProvider.clearUser();
      //   if (!mounted) return;
      //   Navigator.pushReplacementNamed(context, '/login');
      //   setState(() {
      //     _loading = false;
      //     _ready = false;
      //   });
      // }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _ready = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final userProvider = Provider.of<UserProvider>(context);
        final userInfo = userProvider.profile ?? _userInfo;
        print('userInfo; $_userInfo');
        final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
        final colors = _ProfilePalette.fromContext(context, isIOS: isIOS);

        String mapLabel(String? raw, List<Map<String, String>> options) {
          if (raw == null || raw.isEmpty) return '';
          final byId = options.firstWhere(
            (e) => e['id'] == raw,
            orElse: () => {},
          );
          if (byId.isNotEmpty) return byId['label'] ?? '';
          final byLabel = options.firstWhere(
            (e) => e['label'] == raw,
            orElse: () => {},
          );
          if (byLabel.isNotEmpty) return byLabel['label'] ?? '';
          return raw;
        }

        final orgLabel = mapLabel(
          userInfo['organization']?.toString(),
          UserOptions.identityOptions(context),
        );
        final roleLabel = mapLabel(
          userInfo['role']?.toString(),
          UserOptions.roleOptions(context),
        );
        final userName = userInfo['username']?.toString().trim();
        final subtitleText = [
          orgLabel,
          roleLabel,
        ].where((e) => e.isNotEmpty).join(' · ');

        return Scaffold(
          backgroundColor: colors.pageBackground,
          body:
              _loading
                  ? SafeArea(
                    top: true,
                    bottom: false,
                    child: Center(
                      child: CircularProgressIndicator(color: colors.brand),
                    ),
                  )
                  : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.heroBackground,
                          colors.pageBackground,
                          colors.pageBackground,
                        ],
                        stops: const [0, 0.32, 1],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        children: [
                          _ProfileHero(
                            colors: colors,
                            isIOS: isIOS,
                            isReady: _ready,
                            userName:
                                userName?.isNotEmpty == true
                                    ? userName!
                                    : S.of(context).profilePage,
                            subtitle:
                                subtitleText.isEmpty
                                    ? S.of(context).pleaseEnterContent
                                    : subtitleText,
                            onTap: () {
                              Navigator.pushNamed(context, '/user-edit');
                            },
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            title: S.of(context).profile,
                            caption:
                                isIOS ? 'Account & Preferences' : 'Settings',
                            colors: colors,
                          ),
                          const SizedBox(height: 10),
                          _SettingsGroup(
                            colors: colors,
                            children: [
                              _SettingsTile(
                                icon: CupertinoIcons.chat_bubble_2,
                                androidIcon: Icons.feedback_outlined,
                                title: S.of(context).feedbackList,
                                colors: colors,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/feedback_list',
                                  );
                                },
                              ),
                              _SettingsTile(
                                icon: CupertinoIcons.dot_radiowaves_left_right,
                                androidIcon: Icons.devices_other_outlined,
                                title: _deviceManagementLabel(context),
                                colors: colors,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/device-management',
                                  );
                                },
                              ),
                              _SettingsTile(
                                icon: CupertinoIcons.lock_shield,
                                androidIcon: Icons.lock_outline,
                                title: S.of(context).changePassword,
                                colors: colors,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/change-password',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            title: S.of(context).language,
                            caption:
                                isIOS ? 'Localized Display' : 'App Language',
                            colors: colors,
                          ),
                          const SizedBox(height: 10),
                          _LanguageCard(colors: colors),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            title: S.of(context).versionInfo,
                            caption: isIOS ? 'Security & App Info' : 'Support',
                            colors: colors,
                          ),
                          const SizedBox(height: 10),
                          _SettingsGroup(
                            colors: colors,
                            children: [
                              _SettingsTile(
                                icon: CupertinoIcons.info_circle,
                                androidIcon: Icons.info_outline,
                                title: S.of(context).versionInfo,
                                colors: colors,
                                onTap: () {
                                  _showVersionDialog(context);
                                },
                              ),
                              _SettingsTile(
                                icon: CupertinoIcons.square_arrow_right,
                                androidIcon: Icons.logout,
                                title: S.of(context).logout,
                                colors: colors,
                                onTap: () {
                                  _showLogoutDialog(context, userProvider);
                                },
                              ),
                              _SettingsTile(
                                icon: CupertinoIcons.delete_solid,
                                androidIcon: Icons.delete_forever,
                                title: S.of(context).destroyAccount,
                                colors: colors,
                                accentColor: colors.destructive,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/destroy-account',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Future<void> _showVersionDialog(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).versionInfo),
          content: Text('${S.of(context).currentVersion}：$version'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S.of(context).ok),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider provider) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(S.of(context).confirm),
          content: Text(S.of(context).logout),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();

                try {
                  await HttpService().post('user/logout');
                } catch (e) {
                  if (context.mounted) {
                    ToastUtils.handleHttpException(e, context);
                  }
                } finally {
                  provider.clearUser();
                  if (!context.mounted) return;
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: Text(S.of(context).ok),
            ),
          ],
        );
      },
    );
  }
}

class _ProfilePalette {
  const _ProfilePalette({
    required this.pageBackground,
    required this.heroBackground,
    required this.surface,
    required this.surfaceBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.brand,
    required this.brandSoft,
    required this.divider,
    required this.destructive,
  });

  final Color pageBackground;
  final Color heroBackground;
  final Color surface;
  final Color surfaceBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color brand;
  final Color brandSoft;
  final Color divider;
  final Color destructive;

  factory _ProfilePalette.fromContext(
    BuildContext context, {
    required bool isIOS,
  }) {
    final theme = Theme.of(context);
    return _ProfilePalette(
      pageBackground: const Color(0xFFE5E5E5),
      heroBackground: isIOS ? const Color(0xFFE7EFFD) : const Color(0xFFDCE7FB),
      surface: Colors.white.withValues(alpha: isIOS ? 0.78 : 0.96),
      surfaceBorder: isIOS ? const Color(0xD9FFFFFF) : const Color(0xFFE2E7F1),
      primaryText: const Color(0xFF172033),
      secondaryText: const Color(0xFF6B7483),
      brand: theme.primaryColor,
      brandSoft: isIOS ? const Color(0xFFEDF3FF) : const Color(0xFFEAF1FF),
      divider: isIOS ? const Color(0xFFE8ECF4) : const Color(0xFFE3E7EE),
      destructive: const Color(0xFFD43C33),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.colors,
    required this.isIOS,
    required this.isReady,
    required this.userName,
    required this.subtitle,
    required this.onTap,
  });

  final _ProfilePalette colors;
  final bool isIOS;
  final bool isReady;
  final String userName;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isIOS ? 18 : 10,
          sigmaY: isIOS ? 18 : 10,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: colors.brand.withValues(alpha: isIOS ? 0.08 : 0.12),
                blurRadius: isIOS ? 26 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.brand.withValues(alpha: 0.92),
                            colors.brand.withValues(alpha: 0.64),
                          ],
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isIOS ? 23 : 21,
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brandSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isReady ? 'Profile Ready' : 'Offline Snapshot',
                              style: TextStyle(
                                color: colors.brand,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isIOS
                          ? CupertinoIcons.chevron_forward
                          : Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: colors.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.caption,
    required this.colors,
  });

  final String title;
  final String caption;
  final _ProfilePalette colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: TextStyle(fontSize: 12.5, color: colors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children, required this.colors});

  final List<Widget> children;
  final _ProfilePalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isEven) {
            return children[index ~/ 2];
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, color: colors.divider),
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.androidIcon,
    required this.title,
    required this.colors,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final IconData androidIcon;
  final String title;
  final _ProfilePalette colors;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final tone = accentColor ?? colors.brand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(isIOS ? icon : androidIcon, size: 19, color: tone),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accentColor ?? colors.primaryText,
                  ),
                ),
              ),
              Icon(
                isIOS
                    ? CupertinoIcons.chevron_forward
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.colors});

  final _ProfilePalette colors;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final current = Provider.of<LanguageProvider>(context).locale.languageCode;
    final isZH = current == 'zh';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.globe,
                  color: colors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).language,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isZH ? S.of(context).chinese : S.of(context).english,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LangPill(
                  label: S.of(context).chinese,
                  selected: isZH,
                  colors: colors,
                  onTap: () => languageProvider.setLocale('zh'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LangPill(
                  label: S.of(context).english,
                  selected: !isZH,
                  colors: colors,
                  onTap: () => languageProvider.setLocale('en'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _ProfilePalette colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.brand : colors.brandSoft,
          borderRadius: BorderRadius.circular(18),
          border: selected ? null : Border.all(color: colors.surfaceBorder),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : colors.brand,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
