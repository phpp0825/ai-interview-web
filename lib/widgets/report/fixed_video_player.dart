import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Flutter 기본 video_player를 사용하되 duration 문제를 우회하는 플레이어
class FixedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FixedVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  State<FixedVideoPlayer> createState() => _FixedVideoPlayerState();
}

class _FixedVideoPlayerState extends State<FixedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _estimatedDuration = const Duration(minutes: 5); // 기본 5분으로 추정

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('🎬 Fixed VideoPlayer 초기화 시작');
      print('🔗 비디오 URL: ${widget.videoUrl}');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();

      // duration 검사 및 처리
      final duration = _controller.value.duration;
      print('📹 원본 Duration: $duration');

      if (duration.isNegative ||
          duration.inSeconds > 7200 ||
          duration == Duration.zero) {
        print('⚠️ 이상한 duration 감지: $duration');

        // 기본 추정 duration 사용
        _estimatedDuration = const Duration(minutes: 5); // 5분으로 추정
        print('🔄 기본 추정 duration 사용: $_estimatedDuration');
      } else {
        _estimatedDuration = duration;
        print('✅ 정상 duration 사용: $_estimatedDuration');
      }

      // 진행률 추적
      _controller.addListener(() {
        if (mounted) {
          final position = _controller.value.position;
          setState(() {
            // 음수 position 필터링
            _currentPosition = position.isNegative ? Duration.zero : position;
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      print('✅ Fixed VideoPlayer 초기화 완료');
    } catch (e, stackTrace) {
      print('❌ Fixed VideoPlayer 초기화 실패: $e');
      print('스택 트레이스: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = '비디오 초기화 실패: $e';
      });
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekTo(double value) {
    if (_estimatedDuration.inSeconds > 0) {
      final position = Duration(
        seconds: (value * _estimatedDuration.inSeconds).round(),
      );
      _controller.seekTo(position);
    }
  }

  String _formatDuration(Duration duration) {
    // 음수나 이상한 값 필터링
    if (duration.isNegative ||
        duration.inSeconds < 0 ||
        duration.inSeconds > 7200) {
      return '00:00';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Container(
        height: 400,
        color: Colors.grey,
        child: const Center(
          child: Text('웹에서만 지원됩니다'),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              '비디오를 재생할 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? '알 수 없는 오류가 발생했습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                '비디오를 불러오는 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 비디오 플레이어
            Positioned.fill(
              child: VideoPlayer(_controller),
            ),

            // 커스텀 컨트롤
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 중앙 재생 버튼
                    Expanded(
                      child: Center(
                        child: IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // 하단 컨트롤 바
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 진행률 슬라이더
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor:
                                  Colors.white.withValues(alpha: 0.3),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withValues(alpha: 0.2),
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: _estimatedDuration.inSeconds > 0 &&
                                      _currentPosition.inSeconds >= 0
                                  ? (_currentPosition.inSeconds /
                                          _estimatedDuration.inSeconds)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              onChanged: _seekTo,
                            ),
                          ),

                          // 시간 표시
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDuration(_estimatedDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
