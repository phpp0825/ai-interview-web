import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isVideoInitialized = false;
  bool _usingExternalController = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    // dispose된 상태면 중단
    if (!mounted) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // 외부 컨트롤러가 있으면 사용
      if (widget.externalController != null) {
        _videoPlayerController = widget.externalController!;
        _usingExternalController = true;
      } else {
        // 비어있거나 잘못된 URL 체크
        if (widget.videoUrl.isEmpty || !_isValidUrl(widget.videoUrl)) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _errorMessage = '비디오 URL이 유효하지 않습니다.';
          });
          return;
        }

        print('🎬 Firebase Storage 비디오 초기화 (단순화)...');
        print('🔗 비디오 URL: ${widget.videoUrl}');

        // Firebase Storage URL 처리 개선
        if (widget.videoUrl.contains('firebase') ||
            widget.videoUrl.contains('googleapis')) {
          print('🔥 Firebase Storage URL 감지됨');
          print('🌐 CORS 정책 적용 중...');

          // Firebase 인증 상태 확인
          try {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              print('✅ Firebase 인증됨: ${currentUser.uid}');
              print('📧 사용자 이메일: ${currentUser.email}');
            } else {
              print('❌ Firebase 인증되지 않음');
            }
          } catch (e) {
            print('⚠️ Firebase 인증 상태 확인 실패: $e');
          }
        }

        // 단순한 초기화 방식 사용 (더 안전한 방식)
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
          httpHeaders: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        );

        // 기본 초기화 시도 (타임아웃 연장)
        await _videoPlayerController.initialize().timeout(
          const Duration(seconds: 30), // 30초로 연장
          onTimeout: () {
            throw Exception('비디오 초기화 타임아웃 (30초)');
          },
        );

        // 상태 확인
        final duration = _videoPlayerController.value.duration;
        final hasError = _videoPlayerController.value.hasError;

        print('📊 비디오 초기화 결과:');
        print('   - 오류: $hasError');
        if (duration.inMilliseconds > 0) {
          print('   - 길이: ${_formatDuration(duration)}');
        } else {
          print('   - 메타데이터: 재생 중 로드됨 (웹 환경 특성)');
        }

        if (hasError) {
          throw Exception(
              '비디오 플레이어 오류: ${_videoPlayerController.value.errorDescription}');
        }

        print('✅ 비디오 초기화 완료!');

        if (!mounted) return;
        setState(() {
          _isVideoInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      print('❌ 비디오 초기화 실패: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = _getErrorMessage(e);
        _isVideoInitialized = false;
      });
    }
  }

  /// Firebase Storage 비디오 파일이 완전히 처리될 때까지 재시도하는 메서드
  /// (사용하지 않음 - 너무 복잡해서 문제 발생)
  Future<void> _initializeWithRetry() async {
    // 이 메서드는 사용하지 않음
    // 대신 단순한 초기화 방식 사용
  }

  /// 비디오 메타데이터가 완전히 로드될 때까지 대기
  /// (사용하지 않음 - 메모리 누수 문제 발생)
  Future<bool> _waitForMetadataLoading() async {
    // 이 메서드는 사용하지 않음
    // 웹 환경에서는 재생 중에 메타데이터가 로드됨
    return false;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds <= 0) {
      return '00:00';
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return '비디오 파일을 찾을 수 없습니다.\n파일이 삭제되었거나 URL이 잘못되었을 수 있습니다.';
    } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return '비디오 파일에 접근할 수 없습니다.\n파일 권한을 확인해주세요.';
    } else if (errorStr.contains('network') || errorStr.contains('연결')) {
      return '네트워크 연결을 확인해주세요.\n인터넷 연결이 불안정할 수 있습니다.';
    } else if (errorStr.contains('timeout') || errorStr.contains('시간')) {
      return '비디오 로딩 시간이 초과되었습니다.\n파일이 큰 경우 시간이 오래 걸릴 수 있습니다.';
    } else if (errorStr.contains('cors')) {
      return 'CORS 오류가 발생했습니다.\n브라우저 설정 또는 서버 설정을 확인해주세요.';
    } else if (errorStr.contains('codec') || errorStr.contains('format')) {
      return '지원하지 않는 비디오 형식입니다.\n MP4 형식을 사용해주세요.';
    } else if (errorStr.contains('비디오 플레이어 오류')) {
      return '비디오 재생 중 오류가 발생했습니다.\n파일이 손상되었을 수 있습니다.';
    } else {
      return '비디오 로딩 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.\n\n오류 세부사항: ${error.toString().length > 100 ? error.toString().substring(0, 100) + '...' : error.toString()}';
    }
  }

  void seekToTime(int seconds) {
    if (_isVideoInitialized && !_hasError) {
      _videoPlayerController.seekTo(Duration(seconds: seconds));
    }
  }

  @override
  void dispose() {
    if (!_usingExternalController) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 비디오 URL이 비어있는 경우
    if (widget.videoUrl.isEmpty) {
      return _buildNoVideoWidget();
    }

    // 에러가 발생한 경우
    if (_hasError) {
      return _buildErrorWidget(_errorMessage ?? '비디오를 로드할 수 없습니다.');
    }

    // 비디오가 초기화되지 않은 경우 (로딩 중)
    if (!_isVideoInitialized) {
      return _buildLoadingWidget();
    }

    // 정상적으로 비디오 플레이어 표시 (커스텀 컨트롤 포함)
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
            VideoPlayer(_videoPlayerController),

            // 커스텀 컨트롤 오버레이
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 재생/일시정지 버튼 (중앙)
                        Expanded(
                          child: Center(
                            child: IconButton(
                              onPressed: () async {
                                if (_videoPlayerController.value.isPlaying) {
                                  _videoPlayerController.pause();
                                } else {
                                  print('🎬 재생 버튼 클릭됨');
                                  await _videoPlayerController.play();

                                  // 재생 시작 후 메타데이터 업데이트 확인 (더 안전한 방식)
                                  _scheduleMetadataUpdate();
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                _videoPlayerController.value.isPlaying
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
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _videoPlayerController,
                                builder: (context, value, child) {
                                  final duration = value.duration;
                                  final position = value.position;

                                  // 길이가 0이거나 매우 작은 경우 간단한 재생 상태만 표시
                                  final isSliderEnabled =
                                      duration.inMilliseconds > 1000;

                                  if (!isSliderEnabled) {
                                    // 슬라이더 대신 재생 상태 표시
                                    return Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (value.isPlaying) ...[
                                            Icon(
                                              Icons.play_circle_filled,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '재생 중...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ] else ...[
                                            Icon(
                                              Icons.pause_circle_filled,
                                              color: Colors.white54,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '일시정지',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }

                                  return SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      thumbColor: Colors.deepPurple,
                                      activeTrackColor: Colors.deepPurple,
                                      inactiveTrackColor: Colors.grey.shade600,
                                      overlayColor: Colors.deepPurple
                                          .withValues(alpha: 0.3),
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                    ),
                                    child: Slider(
                                      value: (position.inMilliseconds /
                                              duration.inMilliseconds)
                                          .clamp(0.0, 1.0),
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .round(),
                                        );
                                        _videoPlayerController
                                            .seekTo(newPosition);
                                      },
                                    ),
                                  );
                                },
                              ),

                              // 시간 표시 (duration이 있을 때만)
                              ValueListenableBuilder<VideoPlayerValue>(
                                valueListenable: _videoPlayerController,
                                builder: (context, value, child) {
                                  final duration = value.duration;
                                  final position = value.position;
                                  final hasValidDuration =
                                      duration.inMilliseconds > 1000;

                                  if (!hasValidDuration) {
                                    // duration이 0이면 시간 표시 숨김
                                    return const SizedBox.shrink();
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVideoWidget() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '답변 영상이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이 질문에는 녹화된 답변이 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
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
              _errorMessage ?? message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideoPlayer,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'URL: ${widget.videoUrl.isNotEmpty ? widget.videoUrl.substring(0, widget.videoUrl.length > 50 ? 50 : widget.videoUrl.length) + '...' : '없음'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
              '영상을 불러오는 중...',
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

  void _scheduleMetadataUpdate() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final currentDuration = _videoPlayerController.value.duration;
        if (currentDuration.inMilliseconds > 1000) {
          print('🎬 재생 후 메타데이터 확인: ${_formatDuration(currentDuration)}');
        }
        setState(() {});
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final currentDuration = _videoPlayerController.value.duration;
        if (currentDuration.inMilliseconds > 1000) {
          print('✅ 메타데이터 업데이트 확인됨: ${_formatDuration(currentDuration)}');
        }
        setState(() {});
      }
    });
  }
}
