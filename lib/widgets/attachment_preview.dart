import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class AttachmentPreview extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;

  AttachmentPreview({required this.attachments});

  bool isImage(String url) {
    return url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.gif');
  }

  bool isVideo(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return  GridView.builder(
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
          if (item["file_type"] == "image") {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => Scaffold(
                          appBar: AppBar(backgroundColor: Colors.black),
                          backgroundColor: Colors.black,
                          body: PhotoView(
                            imageProvider: CachedNetworkImageProvider(
                              item["file_url"],
                            ),
                          ),
                        ),
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: item["file_url"],
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(color: Colors.grey[300]),
                errorWidget: (context, _, __) => Icon(Icons.broken_image),
              ),
            );
          } else if (item["file_type"] == "video") {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(videoUrl: item["file_url"]),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black12), // 背景占位
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
          } else {
            return Icon(Icons.insert_drive_file);
          }
        },
      );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: false,
          );
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("播放视频")),
      body: Center(
        child:
            _chewieController != null
                ? Chewie(controller: _chewieController!)
                : CircularProgressIndicator(),
      ),
    );
  }
}