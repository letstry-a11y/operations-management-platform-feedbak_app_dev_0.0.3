import 'package:shared_preferences/shared_preferences.dart';

class DeviceBindingRepository {
  static const String _prefsKey = 'bound_device_ids';

  Future<List<String>> getBoundDeviceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_prefsKey) ?? <String>[];
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: true);
  }

  Future<void> bindDevice(String deviceId) async {
    final normalized = deviceId.trim();
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final items = await getBoundDeviceIds();
    if (items.contains(normalized)) return;
    await prefs.setStringList(_prefsKey, <String>[normalized, ...items]);
  }

  Future<void> unbindDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getBoundDeviceIds();
    items.removeWhere((item) => item == deviceId.trim());
    await prefs.setStringList(_prefsKey, items);
  }
}
