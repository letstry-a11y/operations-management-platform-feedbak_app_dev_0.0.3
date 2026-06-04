// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';

// class VideoPlayerDialogContent extends StatefulWidget {
//   final File videoFile;

//   const VideoPlayerDialogContent({required this.videoFile});

//   @override
//   _VideoPlayerDialogContentState createState() =>
//       _VideoPlayerDialogContentState();
// }

// class _VideoPlayerDialogContentState extends State<VideoPlayerDialogContent> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(widget.videoFile)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Center(
//           child: _controller.value.isInitialized
//               ? AspectRatio(
//                   aspectRatio: _controller.value.aspectRatio,
//                   child: VideoPlayer(_controller),
//                 )
//               : CircularProgressIndicator(),
//         ),
//         Positioned(
//           top: 40,
//           right: 20,
//           child: IconButton(
//             icon: Icon(Icons.close, color: Colors.white),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         )
//       ],
//     );
//   }
// }


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerDialogContent extends StatefulWidget {
  final dynamic videoFile; // File 或 String（URL）

  const VideoPlayerDialogContent({super.key, required this.videoFile});

  @override
  _VideoPlayerDialogContentState createState() => _VideoPlayerDialogContentState();
}

class _VideoPlayerDialogContentState extends State<VideoPlayerDialogContent> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final source = widget.videoFile;

    if (source is String) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(source));
    } else if (source is File) {
      _controller = VideoPlayerController.file(source);
    } else {
      throw Exception("Unsupported video source type");
    }

    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
        _controller.play();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        if (_isInitialized)
          Positioned(
            bottom: 40,
            left: 20,
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
          ),
      ],
    );
  }
}

