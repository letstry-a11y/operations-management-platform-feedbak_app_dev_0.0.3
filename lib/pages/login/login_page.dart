import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/providers/user_provider.dart' show UserProvider;
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:provider/provider.dart';

const _brandColor = Color(0xFF042A72);
const _accentColor = Color(0xFF12A594);
const _surfaceColor = Color(0xFFF6F8FB);
const _textPrimaryColor = Color(0xFF172033);
const _textSecondaryColor = Color(0xFF697386);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final userProvider = context.read<UserProvider>();

    try {
      final response = await HttpService().post(
        'auth/login',
        body: {'email': email, 'password': password},
      );
      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      print('auth/login; $result');
      if (result['status'] == 200) {
        final data = result['data'] as Map<String, dynamic>;
        final token = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String? ?? '';
        if (refreshToken.trim().isNotEmpty) {
          await userProvider.setAuthTokens(
            accessToken: token,
            refreshToken: refreshToken,
          );
        } else {
          await userProvider.setToken(token);
        }

        try {
          final res = await HttpService().get('user/info');
          final userInfoResult = jsonDecode(res.body) as Map<String, dynamic>;
          if (userInfoResult['status'] == 200) {
            final userInfo = userInfoResult['data'] as Map<String, dynamic>;
            await userProvider.setProfile(userInfo);
          }
        } catch (_) {
          
        }

        await ToastUtils.showSuccess(context, S.of(context).login).closed;
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } else {
        ToastUtils.showError(context, _messageFrom(result));
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context,  e is HttpException ? e.message : S.of(context).loadException);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return S.of(context).pleaseEnterAccount;

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return S.of(context).pleaseEnterAccount;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return S.of(context).pleaseEnterPwd;
    if (value.length < 6) return S.of(context).pleaseEnterPwd;
    return null;
  }

  String _messageFrom(Map<String, dynamic> result) {
    final message = result['message'];
    return message is String && message.isNotEmpty
        ? message
        : S.of(context).login;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _surfaceColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 420
                ? 20.0
                : 32.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                24 + bottomInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _LoginCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocusNode: _emailFocusNode,
                      passwordFocusNode: _passwordFocusNode,
                      obscurePassword: _obscurePassword,
                      isLoading: _isLoading,
                      onTogglePassword: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      onSubmit: _submitLogin,
                      validateEmail: _validateEmail,
                      validatePassword: _validatePassword,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 28),
              Text(
                S.of(context).login,
                style: textTheme.headlineMedium?.copyWith(
                  color: _textPrimaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medbot AI',
                style: textTheme.bodyMedium?.copyWith(
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _LoginTextField(
                controller: emailController,
                focusNode: emailFocusNode,
                labelText: S.of(context).email,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validateEmail,
                onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              _LoginTextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                labelText: S.of(context).password,
                icon: Icons.lock_outline_rounded,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                validator: validatePassword,
                onFieldSubmitted: (_) {
                  if (!isLoading) onSubmit();
                },
                suffixIcon: IconButton(
                  tooltip: obscurePassword
                      ? S.of(context).show
                      : S.of(context).hide,
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _AccountLinks(isLoading: isLoading),
              const SizedBox(height: 20),
              _LoginButton(isLoading: isLoading, onPressed: onSubmit),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6E5F7)),
          ),
          child: Image.asset(
            'assets/images/logo/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medbot',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _brandColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 72,
                height: 3,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: false,
      enableSuggestions: !obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _AccountLinks extends StatelessWidget {
  const _AccountLinks({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: isLoading
              ? null
              : () => Navigator.pushNamed(context, '/register'),
          child: Text(S.of(context).register),
        ),
        const Spacer(),
        TextButton(
          onPressed: isLoading
              ? null
              : () => Navigator.pushNamed(context, '/forgot-password'),
          child: Text(S.of(context).forgotPassword),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text(
                  S.of(context).login,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
