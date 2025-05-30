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
  final bool isCountdownActive;
  final int countdownSeconds;
  final VoidCallback? onVideoCompleted;

  const InterviewServerVideoView({
    Key? key,
    required this.serverResponseImage,
    required this.isConnected,
    required this.isInterviewStarted,
    this.videoPath,
    this.isVideoPlaying = false,
    this.isCountdownActive = false,
    this.countdownSeconds = 0,
    this.onVideoCompleted,
  }) : super(key: key);

  @override
  State<InterviewServerVideoView> createState() =>
      _InterviewServerVideoViewState();
}

class _InterviewServerVideoViewState extends State<InterviewServerVideoView> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _videoCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(InterviewServerVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 비디오 경로가 변경된 경우에만 재초기화 (카운트다운 상태 변경은 제외)
    if (widget.videoPath != oldWidget.videoPath) {
      _initializeVideo();
    }

    // 재생 상태만 변경된 경우 재생/일시정지 처리
    else if (widget.isVideoPlaying != oldWidget.isVideoPlaying &&
        _videoController != null &&
        _isInitialized) {
      // 비디오가 이미 완료된 경우에는 재생 상태를 변경하지 않음
      if (_videoCompleted) {
        print('⏸️ 비디오 완료됨, 마지막 프레임 유지');
        return;
      }

      if (widget.isVideoPlaying && !_videoController!.value.isPlaying) {
        print('▶️ 비디오 재생 재시작');
        _videoController!.play();
      } else if (!widget.isVideoPlaying && _videoController!.value.isPlaying) {
        print('⏸️ 비디오 일시정지');
        _videoController!.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.videoPath == null || widget.videoPath!.isEmpty) {
      print('⚠️ 비디오 경로가 비어있습니다');
      return;
    }

    print('🎭 면접관 영상 초기화 시작: ${widget.videoPath}');
    print('🌐 웹 환경에서 assets 비디오 로드 시도');

    // 기존 컨트롤러 해제
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoComplete);
      await _videoController!.dispose();
      print('🔄 기존 비디오 컨트롤러 해제 완료');
    }

    // 상태 초기화
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _videoCompleted = false;
      });
    }

    try {
      // 새 컨트롤러 생성 (웹 환경 고려)
      print('📱 VideoPlayerController.asset 생성 중...');
      _videoController = VideoPlayerController.asset(widget.videoPath!);

      print('⏳ 비디오 초기화 시작...');
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('비디오 초기화 타임아웃 (10초)');
        },
      );

      print('✅ 비디오 초기화 성공!');
      print('📊 비디오 정보:');
      print('   - 길이: ${_videoController!.value.duration}');
      print('   - 크기: ${_videoController!.value.size}');
      print('   - 종횡비: ${_videoController!.value.aspectRatio}');

      // 재생 완료 리스너 추가
      _videoController!.addListener(_onVideoComplete);

      // 자동 재생 시작 (중복 재생 방지)
      if (widget.isVideoPlaying &&
          !_videoController!.value.isPlaying &&
          !_videoCompleted) {
        print('▶️ 비디오 자동 재생 시작...');
        await _videoController!.play();
        print('🎬 면접관 영상 재생 시작됨');
      } else {
        print('⏸️ 비디오 로드 완료, 첫 번째 프레임 표시');
        await _videoController!.pause();
        // 첫 번째 프레임으로 이동 (완료된 경우 제외)
        if (!_videoCompleted) {
          await _videoController!.seekTo(Duration.zero);
        }
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ 면접관 영상 초기화 실패: $e');
      print('📝 에러 타입: ${e.runtimeType}');
      print('📍 비디오 경로: ${widget.videoPath}');

      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  /// 비디오 재생 완료 확인
  void _onVideoComplete() {
    if (_videoController != null &&
        _videoController!.value.position >= _videoController!.value.duration) {
      print('🎭 면접관 영상 재생 완료');

      // 영상을 일시정지하여 마지막 프레임 유지 (먼저 정지)
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        print('⏸️ 영상을 마지막 프레임에서 정지');
      }

      if (mounted) {
        setState(() {
          _videoCompleted = true;
        });
      }

      // 부모 컴포넌트에 비디오 완료 알림
      if (widget.onVideoCompleted != null) {
        widget.onVideoCompleted!();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoComplete);
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

    // 비디오가 있고 초기화된 경우 (모든 상태에서 비디오 표시)
    if (widget.videoPath != null &&
        widget.videoPath!.isNotEmpty &&
        _isInitialized &&
        _videoController != null) {
      return _buildVideoPlayer();
    }

    // 비디오 로딩 중인 경우
    if (widget.videoPath != null &&
        widget.videoPath!.isNotEmpty &&
        !_isInitialized) {
      return _buildLoadingWithCountdown();
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
    return Stack(
      children: [
        // 메인 비디오 플레이어
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),

        // 카운트다운 오버레이 (오른쪽 위)
        if (widget.isCountdownActive)
          Positioned(
            top: 16,
            right: 16,
            child: _buildCountdownOverlay(),
          ),
      ],
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

  /// 카운트다운 오버레이
  Widget _buildCountdownOverlay() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.countdownSeconds}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 중 카운트다운 표시
  Widget _buildLoadingWithCountdown() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '비디오를 로드하는 중입니다...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
