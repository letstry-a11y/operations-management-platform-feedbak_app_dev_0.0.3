import 'package:flutter/material.dart';
import 'package:medbot_ai_app/generated/l10n.dart';
import 'package:medbot_ai_app/utils/http_service.dart';

class DeviceSelectionPage extends StatefulWidget {
  DeviceSelectionPage({super.key});

  @override
  State<DeviceSelectionPage> createState() => _DeviceSelectionPageState();
}

class _DeviceSelectionPageState extends State<DeviceSelectionPage> {
  bool _loading = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ensureUserInfo();
  }

  Future<bool> _ensureUserInfo() async {
    try {
      final res = await HttpService().get('user/info');
      print("object : ${res}");
      // 可根据返回结构做校验，这里只要 2xx 即认为成功
      setState(() {
        _loading = false;
        _ready = res.statusCode >= 200 && res.statusCode < 300;
      });
      // if (!_ready && mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(S.of(context).getFailed)),
      //   );
      // }
      return _ready;
    } catch (e) {
      print(e.toString());
      if (mounted) {
        setState(() {
          _loading = false;
          _ready = false;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(S.of(context).getFailed)),
        // );
      }
      return false;
    }
  }

  Future<void> _onSelectAndNavigate(BuildContext context, Map<String, String> device, String feedbackType) async {
    // 跳转前再次校验
    if (!_ready) {
      final ok = await _ensureUserInfo();
      if (!ok) return;
    }
    if (!mounted) return;
    // 先进语音输入页(第一页),由其 AI 整理后再跳转反馈表单(第二页)
    Navigator.pushNamed(
      context,
      "/voice-feedback",
      arguments: {
        "product_id": device["id"],
        "feedback_type": feedbackType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 模拟设备数据
    List<Map<String, String>> devices = [
      {'name': S.of(context).tumaiMultiPort, 'image': 'assets/images/device/tumai.png', "id": "101"},
      // {'name': S.of(context).tumaiSinglePort, 'image': 'assets/images/device/dankong.png', "id": "102"},
      // {'name': S.of(context).dragonflyEye, 'image': 'assets/images/device/qingting.png', "id": "103"},
      // {'name': S.of(context).honghu, 'image': 'assets/images/device/honghu.png', "id": "104"},
      // {'name': S.of(context).rone, 'image': 'assets/images/device/Rone.png', "id": "105"},
      // {'name': S.of(context).monaLisa, 'image': 'assets/images/device/mnls.png', "id": "106"},
      // {
      //   'name': S.of(context).otherService,
      //   'image': 'assets/images/device/other_service.png',
      //   "id": "107",
      // },
    ];
    
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String feedbackType = args?['feedback_type'] ?? '';
    print("feedbackType: $feedbackType");
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).selectDevice,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 根据屏幕宽度动态调整列数
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
            double childAspectRatio = constraints.maxWidth > 600 ? 0.8 : 0.7;
            
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return GestureDetector(
                  onTap: () => _onSelectAndNavigate(context, device, feedbackType),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80, // 固定图片高度
                        width: 80,  // 固定图片宽度
                        child: Image.asset(
                          device['image']!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        device['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: constraints.maxWidth > 600 ? 13 : 11,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}