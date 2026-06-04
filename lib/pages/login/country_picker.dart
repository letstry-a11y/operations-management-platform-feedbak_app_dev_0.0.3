// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:medbot_ai_app/data/models/country.dart';
// import 'package:medbot_ai_app/data/constants/all_countries.dart';

// class CountryPickerPage extends StatefulWidget {
//   const CountryPickerPage({super.key});

//   @override
//   State<CountryPickerPage> createState() => _CountryPickerPageState();
// }

// class _CountryPickerPageState extends State<CountryPickerPage> {
//   final ScrollController _scrollController = ScrollController();
//   final Map<String, GlobalKey> _letterKeys = {};
//   OverlayEntry? _overlayEntry;
//   String? _currentLetter;
//   bool _isTouching = false;

//   late Map<String, List<Country>> _groupedCountries;
//   late List<String> _letters;

//   final List<Country> _allCountries = allCountries;

//   @override
//   void initState() {
//     super.initState();
//     _groupCountries();
//   }

//   void _groupCountries() {
//     List<Country> sorted = List.from(_allCountries);
//     sorted.sort((a, b) => a.name.compareTo(b.name));

//     _groupedCountries = {};
//     for (var country in sorted) {
//       String letter = country.name[0].toUpperCase();
//       _groupedCountries.putIfAbsent(letter, () => []).add(country);
//     }

//     _letters = _groupedCountries.keys.toList()..sort();
//     for (var letter in _letters) {
//       _letterKeys[letter] = GlobalKey();
//     }
//   }

//   final double headerHeight = 40;
//   final double itemHeight = 50;

//   void _jumpToLetter(String letter) {
//     int offsetIndex = 0;

//     for (var l in _letters) {
//       if (l == letter) break;
//       offsetIndex += 1; // header height
//       offsetIndex +=
//           _groupedCountries[l]?.length ?? 0; // all items under this letter
//     }

//     final double offset =
//         offsetIndex * itemHeight +
//         _letters.indexOf(letter) * (headerHeight - itemHeight);

//     _scrollController.animateTo(
//       offset,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   void _showLetterOverlay(String letter) {
//     _removeOverlay();

//     _overlayEntry = OverlayEntry(
//       builder:
//           (context) => Center(
//             child: Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.6),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 letter,
//                 style: const TextStyle(fontSize: 40, color: Colors.white),
//               ),
//             ),
//           ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);

//     Future.delayed(const Duration(milliseconds: 700), () {
//       _removeOverlay();
//     });
//   }

//   void _removeOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }

//   Widget _buildSideBar() {
//     return Positioned(
//       right: 0,
//       top: 80,
//       bottom: 80,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onVerticalDragStart: (_) => setState(() => _isTouching = true),
//         onVerticalDragEnd: (_) {
//           setState(() => _isTouching = false);
//           _removeOverlay();
//         },
//         onVerticalDragUpdate: (details) {
//           RenderBox box = context.findRenderObject() as RenderBox;
//           Offset localOffset = box.globalToLocal(details.globalPosition);

//           int index = (localOffset.dy ~/ 16).clamp(0, _letters.length - 1);
//           String letter = _letters[index];

//           setState(() => _currentLetter = letter);
//           _showLetterOverlay(letter);
//           _jumpToLetter(letter);
//         },
//         child: Container(
//           width: 40,
//           color: Colors.transparent,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children:
//                 _letters.map((letter) {
//                   final isCurrent = letter == _currentLetter;
//                   return GestureDetector(
//                     onTap: () {
//                       print(letter);
//                       setState(() => _currentLetter = letter);
//                       _showLetterOverlay(letter);
//                       _jumpToLetter(letter);
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       width: 40,
//                       height: 20,
//                       child: AnimatedDefaultTextStyle(
//                         duration: const Duration(milliseconds: 150),
//                         style: TextStyle(
//                           fontSize: isCurrent ? 16 : 12,
//                           fontWeight: FontWeight.bold,
//                           color: isCurrent ? Colors.red : Colors.blue,
//                         ),
//                         child: Text(letter),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGroupedList() {
//     return ListView.builder(
//       controller: _scrollController,
//       itemCount: _letters.length,
//       itemBuilder: (context, index) {
//         String letter = _letters[index];
//         List<Country> countries = _groupedCountries[letter]!;

//         return Column(
//           key: _letterKeys[letter],
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: MediaQuery.of(context).size.width,
//               color: Colors.grey.shade200,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               child: Text(
//                 letter,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ...countries.map((country) {
//               return ListTile(
//                 title: Text('${country.flag} ${country.name}'),
//                 onTap: () => Navigator.pop(context, country.name),
//               );
//             }).toList(),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('选择国家'), leading: const BackButton()),
//       body: Stack(children: [_buildGroupedList(), _buildSideBar()]),
//     );
//   }
// }



import 'package:azlistview/azlistview.dart';
import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:medbot_ai_app/data/constants/all_countries.dart';
import 'package:medbot_ai_app/data/models/country.dart';
import 'package:medbot_ai_app/generated/l10n.dart';

class CountryPickerPage extends StatefulWidget {
  const CountryPickerPage({super.key});

  @override
  State<CountryPickerPage> createState() => _CountryPickerPageState();
}

class _CountryPickerPageState extends State<CountryPickerPage> {
  final List<Country> _countryList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // 假设你从 API 或常量导入国家列表
    final rawCountries = allCountries;

    for (var country in rawCountries) {
      final pinyin = PinyinHelper.getPinyinE(country.name);
      final tag = pinyin.isNotEmpty ? pinyin[0].toUpperCase() : '#';
      country.tag = RegExp(r'[A-Z]').hasMatch(tag) ? tag : '#';
      _countryList.add(country);
    }

    SuspensionUtil.sortListBySuspensionTag(_countryList);
    SuspensionUtil.setShowSuspensionStatus(_countryList);

    setState(() {});
  }

  Widget _buildHeader(String tag) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[300],
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildListItem(Country model) {
    return ListTile(
      title: Text('${model.flag} ${model.name}'),
      onTap: () {
        // Navigator.pop(context, model.name);
        Navigator.pop(context, {'name': model.name, 'flag': model.flag});

      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).selectCountry)),
      body: AzListView(
        data: _countryList,
        itemCount: _countryList.length,
        itemBuilder: (context, index) {
          final model = _countryList[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              model.isShowSuspension
                  ? _buildHeader(model.getSuspensionTag())
                  : const SizedBox.shrink(),
              _buildListItem(model),
            ],
          );
        },
        indexBarData: SuspensionUtil.getTagIndexList(_countryList),
        indexBarOptions: const IndexBarOptions(
          needRebuild: true,
          selectTextStyle: TextStyle(color: Colors.white, fontSize: 12),
          selectItemDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          indexHintAlignment: Alignment.centerRight,
          indexHintTextStyle: TextStyle(fontSize: 24, color: Colors.white),
          indexHintDecoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
