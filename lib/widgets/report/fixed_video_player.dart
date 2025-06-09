import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

/// HTML5 video 태그를 직접 사용하는 웹 전용 비디오 플레이어
/// Firebase Storage와의 호환성 문제를 해결합니다
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
  html.VideoElement? _videoElement;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _estimatedDuration = Duration.zero;
  String _viewId = '';
  bool _hasDurationLoaded = false; // Duration이 정상적으로 로드되었는지 추적
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeWebVideoPlayer();
    }
  }

  void _updateDuration() {
    final duration = _videoElement?.duration;
    print('📹 HTML5 Duration: ${duration}초');

    if (duration != null && duration > 0 && duration.isFinite) {
      _estimatedDuration = Duration(seconds: duration.round());
      print('✅ 정상 duration 로드됨: $_estimatedDuration');

      setState(() {
        _isInitialized = true;
        _hasError = false;
        _hasDurationLoaded = true; // Duration 로드 완료 표시
      });
    } else {
      print('⏳ Duration이 ${duration}초 - 재생 후 메타데이터 로딩 예정');

      // Duration이 Infinity인 경우에도 초기화는 하되, 시간은 숨김
      setState(() {
        _isInitialized = true;
        _hasError = false;
        _hasDurationLoaded = false; // Duration 아직 로드 안됨
      });
    }
  }

  // 대체 방법으로 비디오 로드 시도
  void _tryAlternativeVideoLoad() {
    print('🔄 대체 비디오 로드 방법 시도');

    try {
      // 기존 소스들 제거
      _videoElement!.children.clear();

      // 직접 src 속성 사용 (source 엘리먼트 대신)
      _videoElement!.src = widget.videoUrl;
      _videoElement!.load(); // 강제 리로드

      print('🔄 직접 src 속성으로 재시도 완료');
    } catch (e) {
      print('❌ 대체 방법도 실패: $e');
      setState(() {
        _hasError = true;
        _errorMessage = '모든 비디오 로드 방법이 실패했습니다\n브라우저에서 지원하지 않는 비디오 포맷일 수 있습니다.';
      });
    }
  }

  Future<void> _initializeWebVideoPlayer() async {
    try {
      print('🎬 HTML5 VideoPlayer 초기화 시작');
      print('🔗 비디오 URL: ${widget.videoUrl}');

      // 고유한 view ID 생성
      _viewId = 'video-${DateTime.now().millisecondsSinceEpoch}';

      // HTML5 video 엘리먼트 생성
      _videoElement = html.VideoElement()
        ..controls = false
        ..autoplay = false
        ..preload = 'auto' // metadata -> auto로 변경
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.backgroundColor = '#000000';

      // CORS 설정 (src 설정 전에)
      _videoElement!.crossOrigin = 'anonymous';

      // CORS 우회를 위해 직접 src 속성 사용 (source 엘리먼트 대신)
      _videoElement!.src = widget.videoUrl;

      // 추가 속성 설정
      _videoElement!.setAttribute('playsinline', 'true');
      _videoElement!.setAttribute('webkit-playsinline', 'true');

      // 이벤트 리스너 추가
      _videoElement!.onLoadedMetadata.listen((_) {
        print('✅ HTML5 Video 메타데이터 로드 완료');
        _updateDuration();
      });

      // duration 변경 이벤트 (Firebase Storage는 지연 로딩됨)
      _videoElement!.onDurationChange.listen((_) {
        print('🔄 Duration 변경 감지됨');
        _updateDuration();
      });

      // 재생 가능할 때도 확인
      _videoElement!.onCanPlay.listen((_) {
        print('🎬 재생 가능 상태됨');
        _updateDuration();
      });

      _videoElement!.onError.listen((event) {
        String errorDetails = '';

        // HTML5 비디오 에러 코드 분석
        if (_videoElement!.error != null) {
          final error = _videoElement!.error!;
          switch (error.code) {
            case 1: // MEDIA_ERR_ABORTED
              errorDetails = 'MEDIA_ERR_ABORTED (1): 사용자가 재생을 중단했습니다';
              break;
            case 2: // MEDIA_ERR_NETWORK
              errorDetails = 'MEDIA_ERR_NETWORK (2): 네트워크 오류로 다운로드가 실패했습니다';
              break;
            case 3: // MEDIA_ERR_DECODE
              errorDetails = 'MEDIA_ERR_DECODE (3): 비디오 디코딩 오류가 발생했습니다';
              break;
            case 4: // MEDIA_ERR_SRC_NOT_SUPPORTED
              errorDetails =
                  'MEDIA_ERR_SRC_NOT_SUPPORTED (4): 비디오 포맷이 지원되지 않습니다';
              break;
            default:
              errorDetails = '알 수 없는 에러 (코드: ${error.code})';
          }

          if (error.message != null && error.message!.isNotEmpty) {
            errorDetails += '\n메시지: ${error.message}';
          }
        } else {
          errorDetails = '상세 에러 정보를 가져올 수 없습니다';
        }

        print('❌ HTML5 Video 에러 발생: $errorDetails');
        print('🔍 비디오 URL: ${widget.videoUrl}');

        // 추가 디버깅 정보
        if (_videoElement != null) {
          print('🔍 비디오 readyState: ${_videoElement!.readyState}');
          print('🔍 비디오 networkState: ${_videoElement!.networkState}');
          print('🔍 비디오 crossOrigin: ${_videoElement!.crossOrigin}');
        }

        // 포맷 에러인 경우 대체 방법 시도
        if (errorDetails.contains('MEDIA_ERR_SRC_NOT_SUPPORTED')) {
          print('🔄 대체 방법으로 비디오 로드 재시도');
          _tryAlternativeVideoLoad();
        } else {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Firebase Storage 비디오 로드 실패\n$errorDetails\n\n네트워크 연결이나 권한을 확인해주세요.';
          });
        }
      });

      _videoElement!.onTimeUpdate.listen((_) {
        if (mounted && _videoElement != null) {
          final currentTime = _videoElement!.currentTime;
          if (currentTime != null && currentTime >= 0) {
            setState(() {
              _currentPosition = Duration(seconds: currentTime.round());
              _isPlaying = !_videoElement!.paused;
            });
          }
        }
      });

      _videoElement!.onPlay.listen((_) {
        setState(() {
          _isPlaying = true;
        });
      });

      _videoElement!.onPause.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });

      // Flutter에 HTML 엘리먼트 등록
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      print('✅ HTML5 VideoPlayer 초기화 완료');
    } catch (e, stackTrace) {
      print('❌ HTML5 VideoPlayer 초기화 실패: $e');
      print('📍 스택 트레이스: $stackTrace');

      setState(() {
        _hasError = true;
        _errorMessage = '비디오 초기화 실패: $e';
      });
    }
  }

  void _togglePlayPause() {
    if (_videoElement != null) {
      if (_isPlaying) {
        _videoElement!.pause();
      } else {
        _videoElement!.play();
      }
    }
  }

  void _seekTo(double value) {
    if (_videoElement != null && _estimatedDuration.inSeconds > 0) {
      final targetSeconds = (value * _estimatedDuration.inSeconds);
      _videoElement!.currentTime = targetSeconds;
      print('🎯 HTML5 Seek to: ${targetSeconds.toStringAsFixed(1)}초');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 0 || duration.inSeconds > 7200) {
      return '00:00';
    }

    final minutes = duration.inMinutes.clamp(0, 120);
    final seconds = (duration.inSeconds % 60).clamp(0, 59);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getSliderValue() {
    if (_estimatedDuration.inSeconds > 0 && _currentPosition.inSeconds >= 0) {
      return (_currentPosition.inSeconds / _estimatedDuration.inSeconds)
          .clamp(0.0, 1.0);
    }
    return 0.0;
  }

  @override
  void dispose() {
    _videoElement?.pause();
    _videoElement = null;
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
            // HTML5 비디오 플레이어
            Positioned.fill(
              child: HtmlElementView(viewType: _viewId),
            ),

            // 커스텀 컨트롤 오버레이
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
                              value:
                                  _hasDurationLoaded ? _getSliderValue() : 0.0,
                              onChanged: _hasDurationLoaded ? _seekTo : null,
                            ),
                          ),

                          // 시간 표시 (Duration 로딩된 경우에만)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _hasDurationLoaded
                                    ? _formatDuration(_currentPosition)
                                    : '--:--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _hasDurationLoaded
                                    ? _formatDuration(_estimatedDuration)
                                    : '--:--',
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
