import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerSection extends StatefulWidget {
  final String videoUrl;
  final VideoPlayerController? externalController;

  const VideoPlayerSection({
    Key? key,
    required this.videoUrl,
    this.externalController,
  }) : super(key: key);

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _usingExternalController = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    // 외부 컨트롤러가 있으면 사용
    if (widget.externalController != null) {
      _videoPlayerController = widget.externalController!;
      _usingExternalController = true;
    } else {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      await _videoPlayerController.initialize();
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      placeholder: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
        bufferedColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        backgroundColor: Colors.grey.shade300,
      ),
    );

    setState(() {
      _isVideoInitialized = true;
    });
  }

  void seekToTime(int seconds) {
    if (_isVideoInitialized) {
      _videoPlayerController.seekTo(Duration(seconds: seconds));
    }
  }

  @override
  void dispose() {
    if (!_usingExternalController) {
      _videoPlayerController.dispose();
    }
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isVideoInitialized
            ? Chewie(controller: _chewieController!)
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}
