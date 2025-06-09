import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 비디오 플레이어 관련 로직을 담당하는 서비스
/// 
/// 이 서비스는 비디오 플레이어 초기화, 제어, 상태 관리를 처리합니다.
/// UI 상태와 비디오 플레이어 로직을 분리하여 코드를 더 깔끔하게 만듭니다.
class VideoPlayerService {
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  String _currentVideoUrl = '';

  // Getters
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  bool get isVideoInitialized => _isVideoInitialized;
  String get currentVideoUrl => _currentVideoUrl;

  /// 비디오 플레이어를 초기화합니다
  /// 
  /// [videoUrl]: 재생할 비디오 URL
  /// 성공 시 true, 실패 시 Exception을 throw합니다
  Future<bool> initializeVideoPlayer(String videoUrl) async {
    try {
      print('🎬 VideoPlayerService: 비디오 플레이어 초기화 시작');
      print('🔗 비디오 URL: $videoUrl');

      // 기존 컨트롤러가 있으면 해제
      await disposeVideoPlayer();

      // 새 컨트롤러 생성
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // 초기화 수행
      await _videoPlayerController!.initialize();
      
      _isVideoInitialized = true;
      _currentVideoUrl = videoUrl;

      print('✅ VideoPlayerService: 비디오 플레이어 초기화 완료');
      print('   - 비디오 길이: ${_videoPlayerController!.value.duration}');
      print('   - 비디오 크기: ${_videoPlayerController!.value.size}');
      
      return true;
    } catch (e) {
      print('❌ VideoPlayerService: 비디오 플레이어 초기화 실패 - $e');
      _isVideoInitialized = false;
      _currentVideoUrl = '';
      throw Exception('비디오를 로드할 수 없습니다: $e');
    }
  }

  /// 비디오를 특정 시간으로 이동합니다
  /// 
  /// [duration]: 이동할 시간 (Duration 객체)
  /// HTML5 플레이어의 경우 실제 구현은 각 플레이어에서 처리됩니다
  Future<void> seekToTime(Duration duration) async {
    try {
      print('🎯 VideoPlayerService: 시간 이동 요청 - ${duration.inSeconds}초');

      // Duration 유효성 검사
      if (duration.isNegative) {
        print('⚠️ 음수 duration 감지: $duration - HTML5 플레이어에서 처리');
        return;
      }

      // 1시간을 초과하는 경우 거부
      if (duration.inSeconds > 3600) {
        print('⚠️ 과도하게 긴 duration: ${duration.inSeconds}초');
        return;
      }

      // 비디오 플레이어가 초기화되어 있는 경우에만 시도
      if (_isVideoInitialized && _videoPlayerController != null) {
        await _videoPlayerController!.seekTo(duration);
        print('✅ VideoPlayerService: 시간 이동 완료 - ${duration.inSeconds}초');
      } else {
        // HTML5 비디오 플레이어의 경우 로그만 출력
        print('📝 VideoPlayerService: HTML5 플레이어로 위임 - ${duration.inSeconds}초');
      }
    } catch (e, stackTrace) {
      print('❌ VideoPlayerService: 시간 이동 실패 - $e');
      print('스택 트레이스: $stackTrace');
    }
  }

  /// 비디오를 특정 시간으로 이동합니다 (초 단위)
  /// 
  /// [seconds]: 이동할 시간 (초 단위)
  Future<void> seekToTimeInSeconds(int seconds) async {
    await seekToTime(Duration(seconds: seconds));
  }

  /// 비디오 재생을 시작합니다
  Future<void> playVideo() async {
    try {
      if (_isVideoInitialized && _videoPlayerController != null) {
        await _videoPlayerController!.play();
        print('▶️ VideoPlayerService: 비디오 재생 시작');
      } else {
        print('⚠️ VideoPlayerService: 비디오가 초기화되지 않음');
      }
    } catch (e) {
      print('❌ VideoPlayerService: 비디오 재생 실패 - $e');
    }
  }

  /// 비디오 재생을 일시정지합니다
  Future<void> pauseVideo() async {
    try {
      if (_isVideoInitialized && _videoPlayerController != null) {
        await _videoPlayerController!.pause();
        print('⏸️ VideoPlayerService: 비디오 일시정지');
      } else {
        print('⚠️ VideoPlayerService: 비디오가 초기화되지 않음');
      }
    } catch (e) {
      print('❌ VideoPlayerService: 비디오 일시정지 실패 - $e');
    }
  }

  /// 현재 재생 위치를 가져옵니다
  Duration getCurrentPosition() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      return _videoPlayerController!.value.position;
    }
    return Duration.zero;
  }

  /// 비디오 총 길이를 가져옵니다
  Duration getVideoDuration() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      return _videoPlayerController!.value.duration;
    }
    return Duration.zero;
  }

  /// 비디오가 현재 재생 중인지 확인합니다
  bool isPlaying() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      return _videoPlayerController!.value.isPlaying;
    }
    return false;
  }

  /// 비디오 URL이 변경되었는지 확인합니다
  /// 
  /// [newVideoUrl]: 새로운 비디오 URL
  /// 반환값: URL이 변경되었으면 true
  bool isVideoUrlChanged(String newVideoUrl) {
    return newVideoUrl != _currentVideoUrl;
  }

  /// 비디오 URL이 유효한지 확인합니다
  /// 
  /// [videoUrl]: 확인할 비디오 URL
  /// 반환값: 유효한 URL이면 true
  bool isValidVideoUrl(String videoUrl) {
    if (videoUrl.isEmpty) {
      return false;
    }

    // HTTP/HTTPS URL 확인
    if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
      return false;
    }

    try {
      Uri.parse(videoUrl);
      return true;
    } catch (e) {
      print('❌ VideoPlayerService: 잘못된 URL 형식 - $e');
      return false;
    }
  }

  /// 비디오 플레이어 리소스를 해제합니다
  Future<void> disposeVideoPlayer() async {
    try {
      if (_videoPlayerController != null) {
        print('🗑️ VideoPlayerService: 비디오 플레이어 리소스 해제');
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }
      
      _isVideoInitialized = false;
      _currentVideoUrl = '';
      
      print('✅ VideoPlayerService: 리소스 해제 완료');
    } catch (e) {
      print('❌ VideoPlayerService: 리소스 해제 중 오류 - $e');
    }
  }

  /// 비디오 에러 상태를 확인합니다
  String? getVideoError() {
    if (_videoPlayerController != null && _videoPlayerController!.value.hasError) {
      return _videoPlayerController!.value.errorDescription;
    }
    return null;
  }

  /// 비디오 상태 정보를 문자열로 반환합니다
  String getVideoStatusInfo() {
    if (!_isVideoInitialized || _videoPlayerController == null) {
      return '비디오 초기화되지 않음';
    }

    final value = _videoPlayerController!.value;
    final position = value.position.inSeconds;
    final duration = value.duration.inSeconds;
    final isPlaying = value.isPlaying;
    final hasError = value.hasError;

    return '재생시간: ${position}/${duration}초, 재생중: $isPlaying, 오류: $hasError';
  }
} 