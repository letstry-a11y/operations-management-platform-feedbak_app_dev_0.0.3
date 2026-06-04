import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medbot_ai_app/utils/device_binding_repository.dart';
import 'package:medbot_ai_app/utils/http_service.dart';
import 'package:medbot_ai_app/widgets/device_id_card.dart';
import 'package:medbot_ai_app/widgets/toast_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

const _brandColor = Color(0xFF042A72);
const _devicePageBackground = Color(0xFFF5F7FB);
const _deviceCardBackground = Colors.white;
const _devicePrimaryText = Color(0xFF172033);
const _deviceSecondaryText = Color(0xFF697386);
const _deviceBorderColor = Color(0xFFD8DEE9);
const _deviceSuccessSoft = Color(0xFFEAF7F2);

const List<String> _mockDeviceIds = <String>[
  'MRT-SH-2026-00128',
  'MRT-SZ-2026-00135',
  'MRA-ICU-TERM-00342',
  'MEDBOT-OR-00876',
  'MEDBOT-WARD-02119',
  'REHAB-ROBOT-03007',
];

class DeviceItem {
  final String id;
  final String deviceType;
  final String deviceUdi;
  final String bindTime;

  DeviceItem({
    required this.id,
    required this.deviceType,
    required this.deviceUdi,
    required this.bindTime,
  });

  factory DeviceItem.fromJson(Map<String, dynamic> json) {
    return DeviceItem(
      id: json['id']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      deviceUdi: json['deviceUdi']?.toString() ?? '',
      bindTime: json['bindTime']?.toString() ?? '',
    );
  }
}

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  final FocusNode _deviceIdFocusNode = FocusNode();

  List<DeviceItem> _devices = [];
  bool _loading = true;
  bool _submitting = false;

  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';
  _DeviceTypography _typeFor(BuildContext context) =>
      _DeviceTypography.fromContext(context);

  String get _pageTitle => _isZh ? '设备管理' : 'Device Management';
  String get _heroTitle =>
      _isZh ? '医疗机器人设备终端管理' : 'Medical Robot Terminal Management';
  String get _heroSubtitle =>
      _isZh
          ? '支持多个设备 ID 绑定、逐个解绑，并可在当前页面继续新增绑定设备。'
          : 'Manage multiple device IDs, unbind them one by one, and add new devices here.';
  String get _bindSectionTitle => _isZh ? '新增绑定设备' : 'Add Device Binding';
  String get _bindSectionSubtitle =>
      _isZh
          ? '把高频操作放在顶部，方便你扫码或手动输入后立即绑定。'
          : 'Add actions stay at the top for faster scan or manual binding.';
  String get _boundTitle => _isZh ? '已绑定设备列表' : 'Bound Device List';
  String get _boundSubtitle =>
      _isZh
          ? '设备较多时可直接上下滚动浏览，支持逐条解绑，不会影响其它已绑定设备。'
          : 'Scroll through long lists and unbind one device at a time.';
  String get _emptyTitle => _isZh ? '暂无绑定设备' : 'No bound devices';
  String get _emptySubtitle =>
      _isZh
          ? '可直接扫码或手动输入设备 ID，新增绑定医疗机器人设备终端。'
          : 'Scan or enter a device ID below to bind a terminal.';
  String get _deviceIdHint =>
      _isZh
          ? '支持扫码识别或手动输入设备编码'
          : 'Scan barcode/QR code or enter the device ID manually';
  String get _scanLabel => _isZh ? '扫码识别' : 'Scan code';
  String get _manualLabel => _isZh ? '手动录入' : 'Manual entry';
  String get _inputLabel => _isZh ? '请输入设备 ID' : 'Enter device ID';
  String get _scanInstruction =>
      _isZh ? '支持一维码和二维码' : 'Barcode and QR supported';
  String get _bindActionLabel => _isZh ? '新增绑定' : 'Add Binding';
  String get _unbindLabel => _isZh ? '解绑' : 'Unbind';
  String get _deviceIdLabel => _isZh ? '设备 ID' : 'Device ID';
  String get _cameraPermissionMessage =>
      _isZh
          ? '需要相机权限以扫描设备码'
          : 'Camera permission is required to scan the device code';
  String get _unbindDialogTitle => _isZh ? '确认解绑设备' : 'Confirm Unbind';
  String get _unbindDialogMessage =>
      _isZh ? '确认解绑以下设备 ID 吗？' : 'Do you want to unbind this device ID?';
  String get _cancelLabel => _isZh ? '取消' : 'Cancel';
  String get _confirmUnbindLabel => _isZh ? '确认解绑' : 'Confirm';
  String get _bindSuccessMessage =>
      _isZh ? '设备绑定成功' : 'Device bound successfully';
  String get _unbindSuccessMessage => _isZh ? '设备已解绑' : 'Device unbound';
  String get _duplicateMessage =>
      _isZh ? '该设备已绑定，无需重复操作' : 'This device is already bound';
  String get _requiredMessage => _isZh ? '请输入设备 ID' : 'Please enter device ID';
  String get _mockHint =>
      _isZh
          ? '已自动补充 mock 设备 ID，方便你验证解绑功能和交互。'
          : 'Mock IDs added for unbind testing.';

  @override
  void initState() {
    super.initState();
    _prepareDevices();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceIdFocusNode.dispose();
    super.dispose();
  }

  Future<void> _prepareDevices() async {
    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final response = await HttpService().post('device/list', body: {
        "current": 1,
        "size": 100
      });
      final data = jsonDecode(response.body);
      if (data['status'] == 200 && data['data'] != null) {
        final items = data['data']['items'] as List?;
        if (items != null) {
          final loadedDevices = items.map((e) => DeviceItem.fromJson(e)).toList();
          if (mounted) {
            setState(() {
              _devices = loadedDevices;
              _loading = false;
            });
          }
        }
      } else {
        if (mounted) {
          ToastUtils.showError(context, data['message'] ?? 'Failed to load devices');
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, 'Failed to load devices: $e');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _scanDeviceId() async {
    FocusScope.of(context).unfocus();

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
              title: _scanLabel,
              subtitle: _scanInstruction,
            ),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) return;

    final normalized = _normalizeDeviceId(result);
    _deviceIdController
      ..text = normalized
      ..selection = TextSelection.collapsed(offset: normalized.length);
  }

  String _normalizeDeviceId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    final uri = Uri.tryParse(value);
    if (uri != null) {
      const queryKeys = <String>['deviceId', 'device_id', 'sn', 'code', 'id'];
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

  Future<void> _bindDevice([String? rawValue]) async {
    final deviceId = _normalizeDeviceId(rawValue ?? _deviceIdController.text);
    if (deviceId.isEmpty) {
      ToastUtils.showError(context, _requiredMessage);
      return;
    }
    if (_devices.any((d) => d.deviceUdi == deviceId)) {
      ToastUtils.showSuccess(context, _duplicateMessage);
      return;
    }

    setState(() => _submitting = true);
    
    try {
      final response = await HttpService().post('device/bind', body: {
        "deviceType": "SURGICAL_ROBOT",
        "deviceId": deviceId
      });
      final data = jsonDecode(response.body);
      if (data['status'] == 200) {
        await _loadDevices();
        if (!mounted) return;
        _deviceIdController.clear();
        ToastUtils.showSuccess(context, _bindSuccessMessage);
      } else {
        if (!mounted) return;
        ToastUtils.showError(context, data['message'] ?? 'Bind failed');
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, 'Bind failed: $e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _unbindDevice(DeviceItem device) async {
    final confirmed = await _showUnbindDialog(device.deviceUdi);
    if (confirmed != true) return;

    try {
      final response = await HttpService().delete('device/unbind/${device.id}');
      final data = jsonDecode(response.body);
      if (data['status'] == 200) {
        await _loadDevices();
        if (!mounted) return;
        ToastUtils.showSuccess(context, _unbindSuccessMessage);
      } else {
        if (!mounted) return;
        ToastUtils.showError(context, data['message'] ?? 'Unbind failed');
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showError(context, 'Unbind failed: $e');
    }
  }

  Future<bool?> _showUnbindDialog(String deviceId) {
    final typography = _typeFor(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_unbindDialogTitle, style: typography.sectionTitle()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_unbindDialogMessage, style: typography.bodySecondary()),
              const SizedBox(height: 10),
              Text(deviceId, style: typography.deviceIdValue(), softWrap: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_cancelLabel, style: typography.buttonSecondary()),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD64545),
              ),
              child: Text(
                _confirmUnbindLabel,
                style: typography.buttonDanger(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final typography = _typeFor(context);

    return Scaffold(
      backgroundColor: _devicePageBackground,
      appBar: AppBar(
        backgroundColor: _devicePageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(_pageTitle, style: typography.navTitle()),
      ),
      body: SafeArea(
        top: false,
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: _brandColor),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroHeader(
                            title: _heroTitle,
                            subtitle: _heroSubtitle,
                            typography: typography,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _DeviceCountChip(
                                count: _devices.length,
                                isZh: _isZh,
                                typography: typography,
                              ),
                              // Remove mock hint or keep it if needed. Removing since it's real data.
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _bindSectionTitle,
                            style: typography.sectionTitle(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _bindSectionSubtitle,
                            style: typography.bodySecondary(),
                          ),
                          const SizedBox(height: 16),
                          DeviceIdCard(
                            scanTitle: _scanLabel,
                            scanHint: _deviceIdHint,
                            scanButtonLabel: _scanLabel,
                            manualTitle: _manualLabel,
                            onScan: _scanDeviceId,
                            input: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _deviceIdController,
                              builder: (context, value, _) {
                                return TextFormField(
                                  controller: _deviceIdController,
                                  focusNode: _deviceIdFocusNode,
                                  style: typography.deviceIdValue(),
                                  decoration: InputDecoration(
                                    hintText: _inputLabel,
                                    hintStyle: typography.bodySecondary(),
                                    prefixIcon: const Icon(
                                      Icons.confirmation_number_outlined,
                                    ),
                                    suffixIcon:
                                        value.text.isEmpty
                                            ? null
                                            : IconButton(
                                              onPressed:
                                                  _deviceIdController.clear,
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                  ),
                                );
                              },
                            ),
                            brandColor: _brandColor,
                            primaryTextColor: _devicePrimaryText,
                            secondaryTextColor: _deviceSecondaryText,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _bindDevice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isIOS ? 18 : 14,
                                  ),
                                ),
                              ),
                              child: Text(
                                _bindActionLabel,
                                style: typography.buttonOnPrimary(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_boundTitle, style: typography.sectionTitle()),
                          const SizedBox(height: 6),
                          Text(
                            _boundSubtitle,
                            style: typography.bodySecondary(),
                          ),
                          const SizedBox(height: 16),
                          if (_devices.isEmpty)
                            _EmptyState(
                              title: _emptyTitle,
                              subtitle: _emptySubtitle,
                              typography: typography,
                            )
                          else
                            _BoundDeviceList(
                              devices: _devices,
                              deviceIdLabel: _deviceIdLabel,
                              unbindLabel: _unbindLabel,
                              onUnbind: _unbindDevice,
                              typography: typography,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.typography,
  });

  final String title;
  final String subtitle;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3A92), Color(0xFF1E6AA8)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.heroTitle()),
                const SizedBox(height: 6),
                Text(subtitle, style: typography.heroSubtitle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _deviceCardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.typography,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                softWrap: true,
                style: typography.badge(foregroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.typography,
  });

  final String title;
  final String subtitle;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _deviceBorderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.precision_manufacturing_rounded,
            size: 34,
            color: _brandColor,
          ),
          const SizedBox(height: 12),
          Text(title, style: typography.cardTitle()),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: typography.bodySecondary(),
          ),
        ],
      ),
    );
  }
}

class _BoundDeviceList extends StatelessWidget {
  const _BoundDeviceList({
    required this.devices,
    required this.deviceIdLabel,
    required this.unbindLabel,
    required this.onUnbind,
    required this.typography,
  });

  final List<DeviceItem> devices;
  final String deviceIdLabel;
  final String unbindLabel;
  final ValueChanged<DeviceItem> onUnbind;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _deviceBorderColor),
      ),
      child: Column(
        children: List.generate(devices.length, (index) {
          final device = devices[index];
          return _BoundDeviceTile(
            device: device,
            deviceIdLabel: deviceIdLabel,
            unbindLabel: unbindLabel,
            showDivider: index != devices.length - 1,
            onUnbind: () => onUnbind(device),
            typography: typography,
          );
        }),
      ),
    );
  }
}

class _BoundDeviceTile extends StatelessWidget {
  const _BoundDeviceTile({
    required this.device,
    required this.deviceIdLabel,
    required this.unbindLabel,
    required this.showDivider,
    required this.onUnbind,
    required this.typography,
  });

  final DeviceItem device;
  final String deviceIdLabel;
  final String unbindLabel;
  final bool showDivider;
  final VoidCallback onUnbind;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border:
            showDivider
                ? const Border(bottom: BorderSide(color: _deviceBorderColor))
                : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: _brandColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deviceIdLabel, style: typography.caption()),
                const SizedBox(height: 2),
                Text(device.deviceUdi, style: typography.deviceIdValue(), softWrap: true),
                const SizedBox(height: 4),
                Text('Bind Time: ${device.bindTime}', style: typography.caption()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: onUnbind,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD64545),
                  backgroundColor: const Color(0xFFFFF1F1),
                  minimumSize: const Size(72, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    unbindLabel,
                    maxLines: 1,
                    style: typography.buttonDanger(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCountChip extends StatelessWidget {
  const _DeviceCountChip({
    required this.count,
    required this.isZh,
    required this.typography,
  });

  final int count;
  final bool isZh;
  final _DeviceTypography typography;

  @override
  Widget build(BuildContext context) {
    final label = isZh ? '已绑定 $count 台设备终端' : '$count terminals bound';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medical_services_outlined,
              size: 16,
              color: _brandColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: typography.badge(_brandColor),
              ),
            ),
          ],
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
    final typography = _DeviceTypography.fromContext(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final isSimulator =
        Platform.isIOS &&
        (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
            Platform.environment.containsKey('SIMULATOR_UDID'));
    final unavailableMessage =
        isZh
            ? 'iOS 模拟器不支持相机扫码，请使用真机或手动输入设备 ID。'
            : 'iOS Simulator does not support camera scanning. Use a real device or enter the device ID manually.';
    final overlayText = _scannerUnavailable ? unavailableMessage : widget.subtitle;

    if (isSimulator) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                    textAlign: TextAlign.center,
                    style: typography.heroSubtitle(),
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
                      style: typography.heroTitle(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unavailableMessage,
                      style: typography.heroSubtitle(),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: typography.heroTitle()),
                            const SizedBox(height: 4),
                            Text(
                              overlayText,
                              style: typography.heroSubtitle(),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      overlayText,
                      textAlign: TextAlign.center,
                      style: typography.heroSubtitle(),
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

class _DeviceTypography {
  const _DeviceTypography({
    required this.isIOS,
    required this.isNarrow,
    required this.familyFallback,
  });

  final bool isIOS;
  final bool isNarrow;
  final List<String> familyFallback;

  factory _DeviceTypography.fromContext(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isIOS =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final width = MediaQuery.sizeOf(context).width;
    final locale = Localizations.localeOf(context).languageCode;
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
                ? const ['Noto Sans SC', 'Roboto', 'Droid Sans', 'Arial']
                : const ['Roboto', 'Noto Sans', 'Arial']);

    return _DeviceTypography(
      isIOS: isIOS,
      isNarrow: width < 390,
      familyFallback: familyFallback,
    );
  }

  TextStyle navTitle() => _base(
    color: _devicePrimaryText,
    fontSize: isIOS ? (isNarrow ? 17 : 18) : (isNarrow ? 18 : 19),
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.2,
  );

  TextStyle heroTitle() => _base(
    color: Colors.white,
    fontSize: isIOS ? (isNarrow ? 17 : 18) : (isNarrow ? 18 : 20),
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.2,
  );

  TextStyle heroSubtitle() => _base(
    color: const Color(0xE6FFFFFF),
    fontSize: isIOS ? 12.5 : 13,
    fontWeight: FontWeight.w400,
    height: isIOS ? 1.4 : 1.45,
  );

  TextStyle sectionTitle() => _base(
    color: _devicePrimaryText,
    fontSize: isIOS ? (isNarrow ? 16 : 17) : (isNarrow ? 17 : 18),
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.25,
  );

  TextStyle cardTitle() => _base(
    color: _devicePrimaryText,
    fontSize: isIOS ? 13.5 : 14,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.25,
  );

  TextStyle bodySecondary() => _base(
    color: _deviceSecondaryText,
    fontSize: isIOS ? 12.5 : 13,
    fontWeight: FontWeight.w400,
    height: isIOS ? 1.38 : 1.45,
  );

  TextStyle caption() => _base(
    color: _deviceSecondaryText,
    fontSize: isIOS ? 11.5 : 12,
    fontWeight: isIOS ? FontWeight.w500 : FontWeight.w600,
    height: 1.25,
  );

  TextStyle badge(Color color) => _base(
    color: color,
    fontSize: isIOS ? 12 : 12.5,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.3,
  );

  TextStyle deviceIdValue() => _base(
    color: _devicePrimaryText,
    fontSize: isIOS ? 14.5 : 15,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.3,
  );

  TextStyle buttonOnPrimary() => _base(
    color: Colors.white,
    fontSize: isIOS ? 14.5 : 15,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.1,
  );

  TextStyle buttonSecondary() => _base(
    color: _brandColor,
    fontSize: isIOS ? 13.5 : 14,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.1,
  );

  TextStyle buttonDanger() => _base(
    color: const Color(0xFFD64545),
    fontSize: isIOS ? 13 : 13.5,
    fontWeight: isIOS ? FontWeight.w600 : FontWeight.w700,
    height: 1.1,
  );

  TextStyle _base({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      fontFamilyFallback: familyFallback,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}
