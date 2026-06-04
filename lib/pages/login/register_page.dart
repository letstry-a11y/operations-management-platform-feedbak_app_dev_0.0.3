import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medbot_ai_app/data/constants/user_options.dart';
import 'package:medbot_ai_app/data/models/country.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/pages/login/country_picker.dart';
import 'package:medbot_ai_app/utils/device_binding_repository.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/device_id_card.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

const _brandColor = Color(0xFF042A72);
const _registerSurfaceColor = Color(0xFFF4F6FA);
const _registerTextPrimaryColor = Color(0xFF172033);
const _registerTextSecondaryColor = Color(0xFF697386);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _customRoleController = TextEditingController();

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();

  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _deviceIdFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _emailCodeFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _whatsappFocusNode = FocusNode();
  final _customRoleFocusNode = FocusNode();

  Country? _selectedCountry;
  String? _selectedIdentity;
  String? _selectedRole;
  String? _customRole;

  int _seconds = 0;
  Timer? _timer;
  bool _submitting = false;
  bool _obscurePassword = true;

  _RegisterTypography _typeFor(BuildContext context) =>
      _RegisterTypography.fromContext(context);

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    _nameFocusNode.addListener(_onNameFocusChange);
    _deviceIdFocusNode.addListener(_onDeviceIdFocusChange);
    _emailFocusNode.addListener(_onEmailFocusChange);
    _emailCodeFocusNode.addListener(_onEmailCodeFocusChange);
    _phoneFocusNode.addListener(_onPhoneFocusChange);
    _whatsappFocusNode.addListener(_onWhatsappFocusChange);
    _customRoleFocusNode.addListener(_onCustomRoleFocusChange);
  }

  void _onUsernameFocusChange() {
    if (_usernameFocusNode.hasFocus) _showKeyboard();
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) _showKeyboard();
  }

  void _onNameFocusChange() {
    if (_nameFocusNode.hasFocus) _showKeyboard();
  }

  void _onDeviceIdFocusChange() {
    if (_deviceIdFocusNode.hasFocus) _showKeyboard();
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) _showKeyboard();
  }

  void _onEmailCodeFocusChange() {
    if (_emailCodeFocusNode.hasFocus) _showKeyboard();
  }

  void _onPhoneFocusChange() {
    if (_phoneFocusNode.hasFocus) _showKeyboard();
  }

  void _onWhatsappFocusChange() {
    if (_whatsappFocusNode.hasFocus) _showKeyboard();
  }

  void _onCustomRoleFocusChange() {
    if (_customRoleFocusNode.hasFocus) _showKeyboard();
  }

  void _showKeyboard() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput
              .invokeMethod('TextInput.show')
              .catchError((_) {});
        } catch (_) {}
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        try {
          SystemChannels.textInput
              .invokeMethod('TextInput.show')
              .catchError((_) {});
        } catch (_) {}
      });
    });
  }

  void _hideKeyboard() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    try {
      SystemChannels.textInput
          .invokeMethod('TextInput.hide')
          .catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();

    _usernameFocusNode.removeListener(_onUsernameFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _nameFocusNode.removeListener(_onNameFocusChange);
    _deviceIdFocusNode.removeListener(_onDeviceIdFocusChange);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailCodeFocusNode.removeListener(_onEmailCodeFocusChange);
    _phoneFocusNode.removeListener(_onPhoneFocusChange);
    _whatsappFocusNode.removeListener(_onWhatsappFocusChange);
    _customRoleFocusNode.removeListener(_onCustomRoleFocusChange);

    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _deviceIdController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _customRoleController.dispose();

    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    _deviceIdFocusNode.dispose();
    _emailFocusNode.dispose();
    _emailCodeFocusNode.dispose();
    _phoneFocusNode.dispose();
    _whatsappFocusNode.dispose();
    _customRoleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getVerificationCode() async {
    final isValid = _emailFieldKey.currentState?.validate() ?? false;
    if (!isValid || _seconds > 0) return;

    final email = _emailController.text.trim();

    try {
      final response = await HttpService().get(
        'auth/sendCode',
        params: {'email': email, 'scene': "register"},
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (data['status'] == 200) {
        setState(() => _seconds = 60);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_seconds <= 1) {
            timer.cancel();
          }
          if (mounted) {
            setState(() => _seconds--);
          }
        });
        ToastUtils.showSuccess(
          context,
          data['message'] ?? S.of(context).codeSentSuccess,
        );
      } else {
        ToastUtils.showError(
          context,
          data['message'] ?? S.of(context).sendFailed,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, S.of(context).networkErrorSendFailed);
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final deviceId = _deviceIdController.text.trim();
    final email = _emailController.text.trim();
    final emailCode = _emailCodeController.text.trim();
    final phone = _phoneController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final country = _selectedCountry?.name ?? '';
    final organization = _selectedIdentity ?? '';
    final role = _selectedRole == '0' ? _customRole : _selectedRole;

    _hideKeyboard();
    setState(() => _submitting = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await HttpService().post(
        'user/register',
        body: {
          'username': username,
          'password': password,
          'fullName': name,
          'deviceId': deviceId,
          'email': email,
          'code': emailCode,
          'phoneNumber': phone,
          'whatsapp': whatsapp,
          'country': country,
          // "preferLang": "zh_CN",
          'organization': organization,
          // "deviceType": "SURGICAL_ROBOT",
          'role': role,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      final data = jsonDecode(result.body);
      print('Register Response: $data');
      print({
        'username': username,
        'password': password,
        'fullName': name,
        'deviceId': deviceId,
        'email': email,
        'code': emailCode,
        'phoneNumber': phone,
        'whatsapp': whatsapp,
        'country': country,
        // "preferLang": "zh-CN",
        'organization': organization,
        // "deviceType": "SURGICAL_ROBOT",
        'role': role,
      });
      if (data['status'] == 200) {
        if (deviceId.isNotEmpty) {
          await DeviceBindingRepository().bindDevice(deviceId);
          if (!mounted) return;
        }
        ToastUtils.showSuccess(
          context,
          data['message'] ?? S.of(context).registerSuccess,
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ToastUtils.showError(
          context,
          data['message'] ?? S.of(context).registerFailed,
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Registration error: $e');
      Navigator.pop(context);
      ToastUtils.showError(context, e is HttpException ? e.message : S.of(context).registerRequestFailed);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '${S.of(context).pleaseEnter}$label';
    }
    return null;
  }

  String get _deviceIdLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '设备 ID' : 'Device ID';
  }

  String get _deviceIdHint {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '支持扫码识别或手动输入设备编码'
        : 'Scan barcode/QR code or enter the device ID manually';
  }

  String get _scanDeviceIdLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '扫码识别' : 'Scan code';
  }

  String get _manualEntryLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh' ? '手动录入' : 'Manual entry';
  }

  String get _scanInstructionLabel {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '支持一维码和二维码'
        : 'Supports barcode and QR code scanning';
  }

  String get _cameraPermissionMessage {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'zh'
        ? '需要相机权限以扫描设备码'
        : 'Camera permission is required to scan the device code';
  }

  Future<void> _scanDeviceId() async {
    _hideKeyboard();

    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    if (!cameraStatus.isGranted) {
      if (mounted) {
        ToastUtils.showError(context, _cameraPermissionMessage);
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder:
            (_) => _DeviceScannerPage(
              title: _scanDeviceIdLabel,
              subtitle: _scanInstructionLabel,
            ),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) return;

    final normalized = _normalizeDeviceId(result);
    setState(() {
      _deviceIdController.text = normalized;
      _deviceIdController.selection = TextSelection.collapsed(
        offset: normalized.length,
      );
    });
  }

  String _normalizeDeviceId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    final uri = Uri.tryParse(value);
    if (uri != null) {
      const queryKeys = ['deviceId', 'device_id', 'sn', 'code', 'id'];
      for (final key in queryKeys) {
        final queryValue = uri.queryParameters[key];
        if (queryValue != null && queryValue.trim().isNotEmpty) {
          return queryValue.trim();
        }
      }

      final segment = uri.pathSegments.reversed.firstWhere(
        (item) => item.trim().isNotEmpty,
        orElse: () => '',
      );
      if (segment.isNotEmpty) {
        return Uri.decodeComponent(segment).trim();
      }
    }

    final lineMatch = RegExp(
      r'(?:device[_\s-]?id|sn|code)[:=]\s*([A-Za-z0-9\-_./]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (lineMatch != null) {
      return lineMatch.group(1)?.trim() ?? value;
    }

    return value;
  }

  Future<void> _pickCountry() async {
    _hideKeyboard();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CountryPickerPage()),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _selectedCountry = Country(
          name: result['name']!,
          flag: result['flag']!,
          code: '',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.width < 390;
    final isShort = screenSize.height < 760;
    final typography = _typeFor(context);

    return Scaffold(
      backgroundColor: _registerSurfaceColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _hideKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 360
                      ? 12.0
                      : constraints.maxWidth < 420
                      ? 16.0
                      : 24.0;
              final topPadding = isShort ? 10.0 : 16.0;
              final bottomPadding = (isShort ? 16.0 : 24.0) + bottomInset;
              final formPadding =
                  isNarrow
                      ? const EdgeInsets.fromLTRB(14, 16, 14, 16)
                      : const EdgeInsets.fromLTRB(18, 20, 18, 20);

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RegisterTopBar(isIOS: isIOS, typography: typography),
                        SizedBox(height: isShort ? 8 : 12),
                        _RegisterHero(
                          isIOS: isIOS,
                          isNarrow: isNarrow,
                          typography: typography,
                        ),
                        SizedBox(height: isShort ? 14 : 18),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              isIOS ? 28 : 24,
                            ),
                            boxShadow: [
                              const BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 26,
                                offset: Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: formPadding,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormSection(
                                    title: S.of(context).user,
                                    typography: typography,
                                    sectionSpacing: isShort ? 10 : 12,
                                    children: [
                                      _RegisterInput(
                                        label: S.of(context).username,
                                        controller: _usernameController,
                                        focusNode: _usernameFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons.person
                                                : Icons.person_outline_rounded,
                                        validator:
                                            (value) => _validateRequired(
                                              value,
                                              S.of(context).username,
                                            ),
                                        onTap: () {
                                          _usernameFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted: (_) {
                                          _passwordFocusNode.requestFocus();
                                        },
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      _RegisterInput(
                                        label: S.of(context).password,
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons.lock
                                                : Icons.lock_outline_rounded,
                                        obscureText: _obscurePassword,
                                        validator:
                                            (value) => _validateRequired(
                                              value,
                                              S.of(context).password,
                                            ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? (isIOS
                                                    ? CupertinoIcons.eye
                                                    : Icons.visibility_outlined)
                                                : (isIOS
                                                    ? CupertinoIcons.eye_slash
                                                    : Icons
                                                        .visibility_off_outlined),
                                            size: 20,
                                            color: _registerTextSecondaryColor,
                                          ),
                                        ),
                                        onTap: () {
                                          _passwordFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted: (_) {
                                          _nameFocusNode.requestFocus();
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isShort ? 18 : 24),
                                  _FormSection(
                                    title: S.of(context).profile,
                                    typography: typography,
                                    sectionSpacing: isShort ? 10 : 12,
                                    children: [
                                      _RegisterInput(
                                        label: S.of(context).nickname,
                                        controller: _nameController,
                                        focusNode: _nameFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons.person_2
                                                : Icons.badge_outlined,
                                        onTap: () {
                                          _nameFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted: (_) {
                                          _deviceIdFocusNode.requestFocus();
                                        },
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      DeviceIdCard(
                                        scanTitle: _scanDeviceIdLabel,
                                        scanHint: _deviceIdHint,
                                        scanButtonLabel: _scanDeviceIdLabel,
                                        manualTitle: _manualEntryLabel,
                                        onScan: _scanDeviceId,
                                        input: ValueListenableBuilder<
                                          TextEditingValue
                                        >(
                                          valueListenable: _deviceIdController,
                                          builder: (context, value, _) {
                                            final languageCode =
                                                Localizations.localeOf(
                                                  context,
                                                ).languageCode;
                                            final fieldLabel =
                                                languageCode == 'zh'
                                                    ? '请输入设备 ID'
                                                    : 'Enter device ID';
                                            return _RegisterInput(
                                              label: fieldLabel,
                                              controller: _deviceIdController,
                                              focusNode: _deviceIdFocusNode,
                                              prefixIcon:
                                                  Icons
                                                      .confirmation_number_outlined,
                                              validator:
                                                  (value) => _validateRequired(
                                                    value,
                                                    _deviceIdLabel,
                                                  ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              onTap:
                                                  () =>
                                                      _deviceIdFocusNode
                                                          .requestFocus(),
                                              onFieldSubmitted:
                                                  (_) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).nextFocus(),
                                              suffixIcon:
                                                  value.text.isEmpty
                                                      ? null
                                                      : IconButton(
                                                        onPressed:
                                                            _deviceIdController
                                                                .clear,
                                                        icon: const Icon(
                                                          Icons.close_rounded,
                                                        ),
                                                      ),
                                            );
                                          },
                                        ),
                                        brandColor: _brandColor,
                                        primaryTextColor:
                                            _registerTextPrimaryColor,
                                        secondaryTextColor:
                                            _registerTextSecondaryColor,
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      _CountrySelector(
                                        country: _selectedCountry,
                                        onTap: _pickCountry,
                                        isIOS: isIOS,
                                        typography: typography,
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      Builder(
                                        builder: (context) {
                                          final identityOptions =
                                              UserOptions.identityOptions(
                                                context,
                                              );
                                          return _RegisterSelectorField(
                                            label:
                                                '${S.of(context).institutionSelection} *',
                                            value: _selectedIdentity,
                                            options: identityOptions,
                                            isIOS: isIOS,
                                            typography: typography,
                                            onChanged: (val) {
                                              setState(
                                                () => _selectedIdentity = val,
                                              );
                                            },
                                            validatorCallback:
                                                (val) =>
                                                    val == null
                                                        ? S
                                                            .of(context)
                                                            .pleaseSelectInstitutionType
                                                        : null,
                                          );
                                        },
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      Builder(
                                        builder: (context) {
                                          final roleOptions =
                                              UserOptions.roleOptions(context);
                                          return _RegisterSelectorField(
                                            label:
                                                '${S.of(context).roleSelection} *',
                                            value: _selectedRole,
                                            options: roleOptions,
                                            isIOS: isIOS,
                                            typography: typography,
                                            onChanged: (val) {
                                              setState(
                                                () => _selectedRole = val,
                                              );
                                            },
                                            validatorCallback:
                                                (val) =>
                                                    val == null
                                                        ? S
                                                            .of(context)
                                                            .pleaseSelectRoleType
                                                        : null,
                                          );
                                        },
                                      ),
                                      if (_selectedRole == '0') ...[
                                        SizedBox(height: isShort ? 12 : 14),
                                        _RegisterInput(
                                          label:
                                              S
                                                  .of(context)
                                                  .pleaseEnterSpecificRole,
                                          controller: _customRoleController,
                                          focusNode: _customRoleFocusNode,
                                          prefixIcon:
                                              isIOS
                                                  ? CupertinoIcons.briefcase
                                                  : Icons.work_outline_rounded,
                                          onTap: () {
                                            _customRoleFocusNode.requestFocus();
                                            _showKeyboard();
                                          },
                                          onChanged: (val) {
                                            _customRole = val;
                                          },
                                          textInputAction: TextInputAction.done,
                                          validator: (val) {
                                            if (_selectedRole == '0' &&
                                                (val == null ||
                                                    val.trim().isEmpty)) {
                                              return S
                                                  .of(context)
                                                  .pleaseEnterSpecificRole;
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted:
                                              (_) => _hideKeyboard(),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: isShort ? 18 : 24),
                                  _FormSection(
                                    title: S.of(context).contactInfo,
                                    typography: typography,
                                    sectionSpacing: isShort ? 10 : 12,
                                    children: [
                                      if (isNarrow) ...[
                                        _RegisterInput(
                                          fieldKey: _emailFieldKey,
                                          label: S.of(context).email,
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          prefixIcon:
                                              isIOS
                                                  ? CupertinoIcons.mail
                                                  : Icons.mail_outline_rounded,
                                          suffixIcon: _CodeIconButton(
                                            seconds: _seconds,
                                            onTap: _getVerificationCode,
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return S
                                                  .of(context)
                                                  .pleaseEnterEmail;
                                            }
                                            final regex = RegExp(
                                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            );
                                            if (!regex.hasMatch(value.trim())) {
                                              return S
                                                  .of(context)
                                                  .pleaseEnterValidEmail;
                                            }
                                            return null;
                                          },
                                          onTap: () {
                                            _emailFocusNode.requestFocus();
                                            _showKeyboard();
                                          },
                                          onFieldSubmitted: (_) {
                                            _emailCodeFocusNode.requestFocus();
                                          },
                                        ),
                                      ] else
                                        _RegisterInput(
                                          fieldKey: _emailFieldKey,
                                          label: S.of(context).email,
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          prefixIcon:
                                              isIOS
                                                  ? CupertinoIcons.mail
                                                  : Icons.mail_outline_rounded,
                                          suffixIcon: _CodeIconButton(
                                            seconds: _seconds,
                                            onTap: _getVerificationCode,
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return S
                                                  .of(context)
                                                  .pleaseEnterEmail;
                                            }
                                            final regex = RegExp(
                                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            );
                                            if (!regex.hasMatch(value.trim())) {
                                              return S
                                                  .of(context)
                                                  .pleaseEnterValidEmail;
                                            }
                                            return null;
                                          },
                                          onTap: () {
                                            _emailFocusNode.requestFocus();
                                            _showKeyboard();
                                          },
                                          onFieldSubmitted: (_) {
                                            _emailCodeFocusNode.requestFocus();
                                          },
                                        ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      _RegisterInput(
                                        label:
                                            S.of(context).emailVerificationCode,
                                        controller: _emailCodeController,
                                        focusNode: _emailCodeFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons
                                                    .check_mark_circled
                                                : Icons.verified_outlined,
                                        keyboardType: TextInputType.number,
                                        validator:
                                            (value) => _validateRequired(
                                              value,
                                              S
                                                  .of(context)
                                                  .emailVerificationCode,
                                            ),
                                        onTap: () {
                                          _emailCodeFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted: (_) {
                                          _phoneFocusNode.requestFocus();
                                        },
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      _RegisterInput(
                                        label: S.of(context).phone,
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons.phone
                                                : Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                        onTap: () {
                                          _phoneFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted: (_) {
                                          _whatsappFocusNode.requestFocus();
                                        },
                                      ),
                                      SizedBox(height: isShort ? 12 : 14),
                                      _RegisterInput(
                                        label: 'WhatsApp',
                                        controller: _whatsappController,
                                        focusNode: _whatsappFocusNode,
                                        prefixIcon:
                                            isIOS
                                                ? CupertinoIcons
                                                    .chat_bubble_text
                                                : Icons.chat_outlined,
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.done,
                                        onTap: () {
                                          _whatsappFocusNode.requestFocus();
                                          _showKeyboard();
                                        },
                                        onFieldSubmitted:
                                            (_) => _hideKeyboard(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isShort ? 20 : 28),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _submitting ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _brandColor,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child:
                                          _submitting
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Text(
                                                S.of(context).register,
                                                style: typography.primaryButton,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({
    required this.isIOS,
    required this.typography,
    required this.isNarrow,
  });

  final bool isIOS;
  final _RegisterTypography typography;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 14 : 18,
        isNarrow ? 14 : 18,
        isNarrow ? 14 : 18,
        isNarrow ? 14 : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F0FF), Color(0xFFF7FBFF)],
        ),
        borderRadius: BorderRadius.circular(isIOS ? 28 : 24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _brandColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isIOS
                  ? CupertinoIcons.person_crop_circle_badge_plus
                  : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).register, style: typography.heroTitle),
                const SizedBox(height: 6),
                Text(
                  'Medbot AI',
                  style: typography.heroSubtitle.copyWith(
                    color: _registerTextSecondaryColor.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTopBar extends StatelessWidget {
  const _RegisterTopBar({required this.isIOS, required this.typography});

  final bool isIOS;
  final _RegisterTypography typography;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                isIOS ? CupertinoIcons.back : Icons.arrow_back_rounded,
                color: _registerTextPrimaryColor,
                size: typography.iconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    required this.typography,
    this.sectionSpacing = 12,
  });

  final String title;
  final List<Widget> children;
  final _RegisterTypography typography;
  final double sectionSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typography.sectionTitle),
        SizedBox(height: sectionSpacing),
        ...children,
      ],
    );
  }
}

class _RegisterInput extends StatelessWidget {
  const _RegisterInput({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    this.fieldKey,
    this.validator,
    this.onTap,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final typography = _RegisterTypography.fromContext(context);
    final borderColor =
        isIOS ? const Color(0xFFE7EBF3) : const Color(0xFFD8DEE9);

    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enableInteractiveSelection: true,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: typography.fieldLabel,
        prefixIcon: Icon(prefixIcon, size: 20, color: _brandColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isIOS ? const Color(0xFFF7F9FD) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: typography.inputVerticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
          borderSide: const BorderSide(color: _brandColor, width: 1.4),
        ),
      ),
      style: typography.fieldValue,
    );
  }
}

class _RegisterSelectorField extends FormField<String> {
  _RegisterSelectorField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.validatorCallback,
    required this.isIOS,
    required this.typography,
  }) : super(
         initialValue: value,
         validator: validatorCallback,
         builder: (state) {
           final borderColor =
               isIOS ? const Color(0xFFE7EBF3) : const Color(0xFFD8DEE9);
           final selected = options.firstWhere(
             (item) => item['id'] == state.value,
             orElse: () => const {},
           );
           final selectedLabel = selected['label'];

           Future<void> showSelector() async {
             final picked = await showModalBottomSheet<String>(
               context: state.context,
               backgroundColor: Colors.transparent,
               isScrollControlled: false,
               builder: (context) {
                 return _SelectorSheet(
                   title: label.replaceAll(' *', ''),
                   options: options,
                   selectedValue: state.value,
                   isIOS: isIOS,
                   typography: typography,
                 );
               },
             );

             if (picked != null) {
               state.didChange(picked);
               onChanged(picked);
             }
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Material(
                 color: Colors.transparent,
                 child: InkWell(
                   onTap: showSelector,
                   borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
                   child: Ink(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 16,
                     ),
                     decoration: BoxDecoration(
                       color: isIOS ? const Color(0xFFF7F9FD) : Colors.white,
                       borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
                       border: Border.all(
                         color:
                             state.hasError
                                 ? Theme.of(state.context).colorScheme.error
                                 : borderColor,
                         width: state.hasError ? 1.2 : 1,
                       ),
                     ),
                     child: Row(
                       children: [
                         Icon(
                           isIOS
                               ? CupertinoIcons.square_grid_2x2
                               : Icons.unfold_more_rounded,
                           color: _brandColor,
                           size: 20,
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(label, style: typography.fieldCaption),
                               const SizedBox(height: 4),
                               Text(
                                 selectedLabel?.isNotEmpty == true
                                     ? selectedLabel!
                                     : label.replaceAll(' *', ''),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                                 style: TextStyle(
                                   fontSize: typography.fieldValue.fontSize,
                                   fontWeight:
                                       selectedLabel?.isNotEmpty == true
                                           ? FontWeight.w600
                                           : FontWeight.w500,
                                   fontFamilyFallback:
                                       typography.familyFallback,
                                   color:
                                       selectedLabel?.isNotEmpty == true
                                           ? _registerTextPrimaryColor
                                           : _registerTextSecondaryColor,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),
                         Icon(
                           isIOS
                               ? CupertinoIcons.chevron_up_chevron_down
                               : Icons.keyboard_arrow_down_rounded,
                           color: _registerTextSecondaryColor,
                           size: 18,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               if (state.hasError) ...[
                 const SizedBox(height: 6),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   child: Text(
                     state.errorText ?? '',
                     style: TextStyle(
                       color: Theme.of(state.context).colorScheme.error,
                       fontSize: 12,
                     ),
                   ),
                 ),
               ],
             ],
           );
         },
       );

  final String label;
  final String? value;
  final List<Map<String, String>> options;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validatorCallback;
  final bool isIOS;
  final _RegisterTypography typography;
}

class _SelectorSheet extends StatelessWidget {
  const _SelectorSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.isIOS,
    required this.typography,
  });

  final String title;
  final List<Map<String, String>> options;
  final String? selectedValue;
  final bool isIOS;
  final _RegisterTypography typography;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6DCE7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: typography.sectionTitle),
            const SizedBox(height: 10),
            ...options.map((item) {
              final selected = item['id'] == selectedValue;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(item['id']),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['label'] ?? '',
                            style: TextStyle(
                              fontSize: typography.fieldValue.fontSize,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontFamilyFallback: typography.familyFallback,
                              color:
                                  selected
                                      ? _brandColor
                                      : _registerTextPrimaryColor,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            isIOS
                                ? CupertinoIcons.check_mark_circled_solid
                                : Icons.check_circle_rounded,
                            size: 20,
                            color: _brandColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({
    required this.country,
    required this.onTap,
    required this.isIOS,
    required this.typography,
  });

  final Country? country;
  final VoidCallback onTap;
  final bool isIOS;
  final _RegisterTypography typography;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isIOS ? const Color(0xFFF7F9FD) : Colors.white,
            borderRadius: BorderRadius.circular(isIOS ? 18 : 16),
            border: Border.all(
              color: isIOS ? const Color(0xFFE7EBF3) : const Color(0xFFD8DEE9),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isIOS ? CupertinoIcons.location_solid : Icons.public_rounded,
                color: _brandColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country == null
                      ? S.of(context).pleaseSelectCountry
                      : '${country!.flag} ${country!.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: typography.fieldValue.fontSize,
                    fontFamilyFallback: typography.familyFallback,
                    color:
                        country == null
                            ? _registerTextSecondaryColor
                            : _registerTextPrimaryColor,
                  ),
                ),
              ),
              Icon(
                isIOS
                    ? CupertinoIcons.chevron_forward
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _registerTextSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeIconButton extends StatelessWidget {
  const _CodeIconButton({required this.seconds, required this.onTap});

  final int seconds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final enabled = seconds == 0;
    final tooltip =
        enabled ? S.of(context).getCode : '$seconds ${S.of(context).seconds}';

    return Tooltip(
      message: tooltip,
      child:
          enabled
              ? IconButton(
                onPressed: onTap,
                icon: Icon(
                  isIOS ? CupertinoIcons.paperplane : Icons.send_rounded,
                  size: 20,
                ),
                color: _brandColor,
              )
              : SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    '${seconds}s',
                    style: const TextStyle(
                      color: _registerTextSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
    );
  }
}

class _DeviceScannerPage extends StatefulWidget {
  const _DeviceScannerPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_DeviceScannerPage> createState() => _DeviceScannerPageState();
}

class _DeviceScannerPageState extends State<_DeviceScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.all],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;
  bool _torchEnabled = false;
  bool _scannerUnavailable = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markScannerUnavailable() {
    if (_scannerUnavailable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _scannerUnavailable = true;
      });
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = _RegisterTypography.fromContext(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 390;
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final isSimulator =
        Platform.isIOS &&
        (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
            Platform.environment.containsKey('SIMULATOR_UDID'));
    final unavailableMessage =
        isZh
            ? 'iOS 模拟器不支持相机扫码，请使用真机或手动输入设备 ID。'
            : 'iOS Simulator does not support camera scanning. Use a real device or enter the device ID manually.';
    final overlayText =
        _scannerUnavailable ? unavailableMessage : widget.subtitle;

    if (isSimulator) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isNarrow ? 12 : 16,
              12,
              isNarrow ? 12 : 16,
              isNarrow ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: Text(
                    unavailableMessage,
                    style: typography.scannerBody,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
            errorBuilder: (context, error) {
              _markScannerUnavailable();
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white70,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isZh ? '无法使用相机' : 'Camera unavailable',
                      style: typography.scannerTitle,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unavailableMessage,
                      style: typography.scannerBody,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isNarrow ? 12 : 16,
                12,
                isNarrow ? 12 : 16,
                isNarrow ? 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black45,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Spacer(),
                            if (!_scannerUnavailable)
                              IconButton(
                                onPressed: () async {
                                  await _controller.toggleTorch();
                                  if (!mounted) return;
                                  setState(() {
                                    _torchEnabled = !_torchEnabled;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black45,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Icon(
                                  _torchEnabled
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: typography.scannerTitle,
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: typography.scannerBody,
                          softWrap: true,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: typography.scannerTitle,
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: typography.scannerBody,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                        if (!_scannerUnavailable)
                          IconButton(
                            onPressed: () async {
                              await _controller.toggleTorch();
                              if (!mounted) return;
                              setState(() {
                                _torchEnabled = !_torchEnabled;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(
                              _torchEnabled
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                            ),
                          ),
                      ],
                    ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isNarrow ? 14 : 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      overlayText,
                      textAlign: TextAlign.center,
                      style: typography.scannerOverlay,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterTypography {
  const _RegisterTypography({
    required this.isIOS,
    required this.isNarrow,
    required this.familyFallback,
  });

  final bool isIOS;
  final bool isNarrow;
  final List<String> familyFallback;

  factory _RegisterTypography.fromContext(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    final locale = Localizations.localeOf(context).languageCode;
    final width = MediaQuery.sizeOf(context).width;

    final familyFallback =
        isIOS
            ? (locale == 'zh'
                ? const [
                  'PingFang SC',
                  'SF Pro Text',
                  'Helvetica Neue',
                  'Arial',
                ]
                : const ['SF Pro Text', 'Helvetica Neue', 'Arial'])
            : (locale == 'zh'
                ? const ['Roboto', 'Noto Sans SC', 'Droid Sans', 'Arial']
                : const ['Roboto', 'Noto Sans', 'Arial']);

    return _RegisterTypography(
      isIOS: isIOS,
      isNarrow: width < 390,
      familyFallback: familyFallback,
    );
  }

  double get iconSize => isIOS ? 19 : 20;
  double get inputVerticalPadding => isNarrow ? 14 : 16;

  TextStyle get heroTitle => _style(
    size: isIOS ? (isNarrow ? 22 : 24) : (isNarrow ? 23 : 24),
    weight: isIOS ? FontWeight.w700 : FontWeight.w800,
    color: _registerTextPrimaryColor,
    height: 1.15,
  );

  TextStyle get heroSubtitle => _style(
    size: isIOS ? 13 : 14,
    weight: isIOS ? FontWeight.w500 : FontWeight.w600,
    color: _registerTextSecondaryColor,
    height: 1.25,
  );

  TextStyle get sectionTitle => _style(
    size: isIOS ? 16.5 : 17,
    weight: isIOS ? FontWeight.w700 : FontWeight.w800,
    color: _registerTextPrimaryColor,
    height: 1.2,
  );

  TextStyle get fieldLabel => _style(
    size: isIOS ? 13 : 13.5,
    weight: FontWeight.w500,
    color: _registerTextSecondaryColor,
    height: 1.2,
  );

  TextStyle get fieldCaption => _style(
    size: isIOS ? 11.5 : 12,
    weight: isIOS ? FontWeight.w500 : FontWeight.w600,
    color: _registerTextSecondaryColor,
    height: 1.2,
  );

  TextStyle get fieldValue => _style(
    size: isIOS ? 14.5 : 15,
    weight: isIOS ? FontWeight.w500 : FontWeight.w600,
    color: _registerTextPrimaryColor,
    height: 1.25,
  );

  TextStyle get cardTitle => _style(
    size: isIOS ? 13.5 : 14,
    weight: isIOS ? FontWeight.w600 : FontWeight.w700,
    color: _registerTextPrimaryColor,
    height: 1.25,
  );

  TextStyle get helpText => _style(
    size: isIOS ? 12.5 : 12.8,
    weight: FontWeight.w400,
    color: _registerTextSecondaryColor,
    height: 1.35,
  );

  TextStyle get primaryButton => _style(
    size: isIOS ? 15 : 16,
    weight: isIOS ? FontWeight.w600 : FontWeight.w700,
    color: Colors.white,
    height: 1.1,
  );

  TextStyle get secondaryButton => _style(
    size: isIOS ? 13.5 : 14,
    weight: isIOS ? FontWeight.w600 : FontWeight.w700,
    color: _brandColor,
    height: 1.1,
  );

  TextStyle get scannerTitle => _style(
    size: isIOS ? 17 : 18,
    weight: isIOS ? FontWeight.w600 : FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  TextStyle get scannerBody => _style(
    size: isIOS ? 12.5 : 13,
    weight: FontWeight.w400,
    color: Colors.white70,
    height: 1.35,
  );

  TextStyle get scannerOverlay => _style(
    size: isIOS ? 13 : 14,
    weight: FontWeight.w500,
    color: Colors.white,
    height: 1.4,
  );

  TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    required double height,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamilyFallback: familyFallback,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}
