import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// 서버로부터 받아온 영상을 표시하는 위젯
class InterviewServerVideoView extends StatefulWidget {
  final Uint8List? serverResponseImage;
  final bool isConnected;
  final bool isInterviewStarted;
  final String? videoPath;
  final bool isVideoPlaying;

  const InterviewServerVideoView({
    Key? key,
    required this.serverResponseImage,
    required this.isConnected,
    required this.isInterviewStarted,
    this.videoPath,
    this.isVideoPlaying = false,
  }) : super(key: key);

  @override
  State<InterviewServerVideoView> createState() =>
      _InterviewServerVideoViewState();
}

class _InterviewServerVideoViewState extends State<InterviewServerVideoView> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(InterviewServerVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoPath != oldWidget.videoPath) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.videoPath == null || widget.videoPath!.isEmpty) {
      return;
    }

    // 기존 컨트롤러 해제
    await _videoController?.dispose();

    // 새 컨트롤러 생성
    _videoController = VideoPlayerController.asset(widget.videoPath!);

    try {
      await _videoController!.initialize();
      if (widget.isVideoPlaying) {
        await _videoController!.play();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('비디오 초기화 실패: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            _buildContent(),
          ],
        ),
      ),
    );
  }

  /// 내용 표시
  Widget _buildContent() {
    // 서버에 연결되지 않은 경우
    if (!widget.isConnected) {
      return _buildNotConnectedView();
    }

    // 인터뷰가 시작되지 않은 경우
    if (!widget.isInterviewStarted) {
      return _buildNotStartedView();
    }

    // 비디오가 재생 중인 경우
    if (widget.isVideoPlaying && _isInitialized && _videoController != null) {
      return _buildVideoPlayer();
    }

    // 서버 응답 이미지가 있는 경우
    if (widget.serverResponseImage != null &&
        widget.serverResponseImage!.isNotEmpty) {
      return _buildServerImageView();
    }

    // 기본 화면
    return _buildDefaultView();
  }

  /// 비디오 플레이어 위젯
  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  /// 서버 연결 안됨 화면
  Widget _buildNotConnectedView() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '서버에 연결되지 않았습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '면접을 시작하려면 서버에 연결해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 면접 시작 전 화면
  Widget _buildNotStartedView() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '면접이 시작되지 않았습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '면접 시작 버튼을 눌러주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 서버 응답 이미지 표시
  Widget _buildServerImageView() {
    return Image.memory(
      widget.serverResponseImage!,
      fit: BoxFit.cover,
    );
  }

  /// 기본 화면
  Widget _buildDefaultView() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(
          Icons.videocam,
          size: 48,
          color: Colors.blue,
        ),
      ),
    );
  }
}
