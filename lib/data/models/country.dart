import 'package:azlistview/azlistview.dart';

class Country extends ISuspensionBean {
  final String name;
  final String code;
  final String flag;
  String tag; // AZ tag

  Country({
    required this.name,
    required this.code,
    required this.flag,
    this.tag = '',
  });

  @override
  String getSuspensionTag() => tag;
}
