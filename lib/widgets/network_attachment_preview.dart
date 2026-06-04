// import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

// class NetworkMediaList extends StatefulWidget {
//   final List<Map<String, dynamic>> attachmentsMedia;
//   final Function(String url) onDelete;
//   final Function(String url, bool isImage) onPreview;

//   const NetworkMediaList({
//     Key? key,
//     required this.attachmentsMedia,
//     required this.onDelete,
//     required this.onPreview,
//   }) : super(key: key);

//   @override
//   State<NetworkMediaList> createState() => _NetworkMediaListState();
// }

// class _NetworkMediaListState extends State<NetworkMediaList> {
//   late List<Map<String, dynamic>> _mediaItems;

//   @override
//   void initState() {
//     super.initState();
//     _mediaItems = List.from(widget.attachmentsMedia);
//   }

//   @override
//   void didUpdateWidget(covariant NetworkMediaList oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.attachmentsMedia != widget.attachmentsMedia) {
//       _mediaItems = List.from(widget.attachmentsMedia);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_mediaItems.isEmpty) {
//       return SizedBox();
//     }

//     final screenWidth = MediaQuery.of(context).size.width;
//     final deleteButtonWidth = screenWidth * 0.3;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children:
//           _mediaItems.asMap().entries.map((entry) {
//             final index = entry.key;
//             final item = entry.value;
//             final url = item['url'] ?? '';
//             final type = item['type'] ?? '';
//             final isImage = type == 'image';

//             return Slidable(
//               key: ValueKey(url),
//               endActionPane: ActionPane(
//                 motion: ScrollMotion(),
//                 extentRatio: 0.3, // 显示删除按钮宽度占item宽度30%
//                 children: [
//                   SlidableAction(
//                     onPressed: (context) {
//                       setState(() {
//                         _mediaItems.removeAt(index);
//                       });
//                       widget.onDelete(url);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('已删除 ${url.split('/').last}')),
//                       );
//                     },
//                     backgroundColor: Colors.red,
//                     foregroundColor: Colors.white,
//                     icon: Icons.delete,
//                     label: '删除',
//                     flex: 1, // 这里flex无效，因为extentRatio固定了宽度
//                   ),
//                 ],
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: GestureDetector(
//                   onTap: () => widget.onPreview(url, isImage),
//                   child: Row(
//                     children: [
//                       isImage
//                           ? Image.network(
//                             url,
//                             width: 50,
//                             height: 50,
//                             fit: BoxFit.cover,
//                             errorBuilder:
//                                 (_, __, ___) =>
//                                     Icon(Icons.broken_image, size: 50),
//                           )
//                           : Icon(Icons.videocam, size: 50),
//                       SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           url.split('/').last,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//     );
//   }
// }
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MediaItem {
  final String? url; // 网络资源URL
  final File? file;  // 本地File对象
  final String? id;  // 本地File对象
  final String type; // 'image' 或 'video'

  MediaItem({
    this.url,
    this.file,
    this.id,
    required this.type,
  });
}

class MediaList extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final Function(MediaItem item) onDelete;
  final Function(MediaItem item) onPreview;

  const MediaList({
    Key? key,
    required this.mediaItems,
    required this.onDelete,
    required this.onPreview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isImage = item.type == 'image';

        return Slidable(
          key: ValueKey(item.url ?? item.file?.path ?? index),
          endActionPane: ActionPane(
            motion: ScrollMotion(),
            extentRatio: 0.3,
            children: [
              SlidableAction(
                onPressed: (context) {
                  onDelete(item);
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '删除',
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onPreview(item),
                  child:
                      isImage
                          ? _buildImage(item)
                          : const Icon(Icons.videocam, size: 50),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onPreview(item),
                    child: Text(
                      _getDisplayName(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(item),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImage(MediaItem item) {
    if (item.file != null) {
      // 本地文件
      return Image.file(
        item.file!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (item.url != null) {
      // 网络图片
      return Image.network(
        item.url!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image,
          size: 50,
        ),
      );
    } else {
      return Icon(
        Icons.broken_image,
        size: 50,
      );
    }
  }

  String _getDisplayName(MediaItem item) {
    if (item.file != null) {
      return item.file!.path.split('/').last;
    } else if (item.url != null) {
      return item.url!.split('/').last;
    } else {
      return "未知文件";
    }
  }
}
