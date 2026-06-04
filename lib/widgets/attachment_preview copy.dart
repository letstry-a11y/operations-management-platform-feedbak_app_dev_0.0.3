import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class AttachmentPreview extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;

  AttachmentPreview({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = attachments[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AttachmentPreviewPage(
                      attachments: attachments,
                      initialIndex: index,
                    ),
              ),
            );
          },
          child:
              item["type"] == "images"
                  ? CachedNetworkImage(
                    imageUrl: item["url"],
                    fit: BoxFit.cover,
                    placeholder:
                        (context, _) => Container(color: Colors.grey[300]),
                    errorWidget: (context, _, __) => Icon(Icons.broken_image),
                  )
                  : Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.black12),
                      Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}

class AttachmentPreviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> attachments;
  final int initialIndex;

  const AttachmentPreviewPage({
    required this.attachments,
    required this.initialIndex,
  });

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  late PageController _pageController;
  late int currentIndex;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _initializeVideoController(currentIndex);
  }

  Future<void> _initializeVideoController(int index) async {
    final item = widget.attachments[index];
    if (item['type'] == 'video' && !_videoControllers.containsKey(index)) {
      final videoController = VideoPlayerController.network(item['url']);
      await videoController.initialize();
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
      );
      _videoControllers[index] = videoController;
      _chewieControllers[index] = chewieController;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _chewieControllers.forEach((_, c) => c.dispose());
    _videoControllers.forEach((_, c) => c.dispose());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
          _initializeVideoController(index);
        },
        itemBuilder: (context, index) {
          final item = widget.attachments[index];
          if (item['type'] == 'images') {
            return PhotoView(
              backgroundDecoration: BoxDecoration(color: Colors.black),
              imageProvider: CachedNetworkImageProvider(item['url']),
            );
          } else if (item['type'] == 'video') {
            final chewie = _chewieControllers[index];
            return Center(
              child:
                  chewie != null
                      ? Chewie(controller: chewie)
                      : CircularProgressIndicator(),
            );
          } else {
            return Center(
              child: Icon(Icons.insert_drive_file, color: Colors.white),
            );
          }
        },
      ),
    );
  }
}
