import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'http_streaming_service.dart';

/// HTTP를 통한 미디어 스트리밍 서비스
/// 비디오와 오디오 데이터 스트리밍 기능을 담당합니다.
class HttpMediaService {
  // 서비스 인스턴스
  final HttpStreamingService _httpService;

  // 타이머
  Timer? _videoStreamTimer;
  Timer? _audioStreamTimer;

  // 스트리밍 상태
  bool _isVideoStreamingEnabled = false;
  bool _isAudioStreamingEnabled = false;

  // 비디오/오디오 프레임 수집을 위한 콜백
  Function()? _getVideoFrameCallback;
  Function()? _getAudioDataCallback;

  // 캡처된 마지막 프레임
  Uint8List? _lastCapturedVideoFrame;
  Uint8List? _lastCapturedAudioData;

  // 콜백 함수
  final Function(String) onError;
  final Function()? onStateChanged;

  // 비디오 프레임 null 발생 횟수 (연속으로 5회 이상이면 문제 있음)
  int _consecutiveNullVideoFrames = 0;
  static const int _maxConsecutiveNullFrames = 5;

  // 상태 getter
  bool get isVideoStreamingEnabled => _isVideoStreamingEnabled;
  bool get isAudioStreamingEnabled => _isAudioStreamingEnabled;
  Uint8List? get lastCapturedVideoFrame => _lastCapturedVideoFrame;
  Uint8List? get lastCapturedAudioData => _lastCapturedAudioData;

  HttpMediaService({
    required HttpStreamingService httpService,
    required this.onError,
    this.onStateChanged,
  }) : _httpService = httpService {
    // 연결 상태 변경 감지
    _httpService.connectionStatus.listen(_handleConnectionStatusChanged);
  }

  /// 연결 상태 변경 처리
  void _handleConnectionStatusChanged(ConnectionStatus status) {
    if (status != ConnectionStatus.connected) {
      // 연결이 끊어지면 스트리밍 중단
      if (_isVideoStreamingEnabled) {
        stopVideoStreaming();
      }
      if (_isAudioStreamingEnabled) {
        stopAudioStreaming();
      }
    }
  }

  /// 비디오 프레임 수집 콜백 설정
  void setVideoFrameCallback(Function() getVideoFrame) {
    _getVideoFrameCallback = getVideoFrame;
  }

  /// 오디오 데이터 수집 콜백 설정
  void setAudioDataCallback(Function() getAudioData) {
    _getAudioDataCallback = getAudioData;
  }

  /// 비디오 스트리밍 시작
  Future<bool> startVideoStreaming() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 비디오 스트리밍을 시작할 수 없습니다');
      return false;
    }

    if (_getVideoFrameCallback == null) {
      onError('비디오 프레임 콜백이 설정되지 않았습니다');
      return false;
    }

    _isVideoStreamingEnabled = true;
    _consecutiveNullVideoFrames = 0;

    // 기존 타이머 종료
    _stopVideoStreamTimer();

    // 새 타이머 시작 (3초마다 프레임 전송)
    _videoStreamTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isVideoStreamingEnabled || !_httpService.isConnected) {
        timer.cancel();
        return;
      }

      try {
        // 콜백으로부터 현재 비디오 프레임 가져오기
        final Uint8List? jpegData = await _getVideoFrameCallback!();

        // 비디오 프레임이 null인 경우 처리
        if (jpegData == null || jpegData.isEmpty) {
          _consecutiveNullVideoFrames++;
          if (_consecutiveNullVideoFrames >= _maxConsecutiveNullFrames) {
            // 연속으로 null 프레임이 너무 많으면 로그만 출력 (인터뷰는 계속 진행)
            print(
                '연속 ${_consecutiveNullVideoFrames}번 비디오 프레임을 가져올 수 없습니다. 카메라가 없거나 비활성화되었을 수 있습니다.');
          }
          return;
        }

        // 정상 프레임을 받으면 카운터 초기화
        _consecutiveNullVideoFrames = 0;

        // 마지막 캡처 프레임 저장
        _lastCapturedVideoFrame = jpegData;

        // 서버로 전송
        final response = await _httpService.post(
          'video',
          jpegData,
          headers: {'Content-Type': 'application/octet-stream'},
        );

        if (response?.statusCode != 200) {
          print('비디오 프레임 전송 실패: ${response?.statusCode}');
        }
      } catch (e) {
        print('비디오 프레임 전송 오류: $e');
      }
    });

    onStateChanged?.call();
    return true;
  }

  /// 오디오 스트리밍 시작
  Future<bool> startAudioStreaming() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 오디오 스트리밍을 시작할 수 없습니다');
      return false;
    }

    if (_getAudioDataCallback == null) {
      onError('오디오 데이터 콜백이 설정되지 않았습니다');
      return false;
    }

    _isAudioStreamingEnabled = true;

    // 기존 타이머 종료
    _stopAudioStreamTimer();

    // 새 타이머 시작 (1초마다 오디오 데이터 전송)
    _audioStreamTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isAudioStreamingEnabled || !_httpService.isConnected) {
        timer.cancel();
        return;
      }

      try {
        // 콜백으로부터 현재 오디오 데이터 가져오기
        final Uint8List? audioData = await _getAudioDataCallback!();
        if (audioData == null || audioData.isEmpty) return;

        // 마지막 캡처 오디오 데이터 저장
        _lastCapturedAudioData = audioData;

        // 서버로 전송
        final response = await _httpService.post(
          'audio',
          audioData,
          headers: {'Content-Type': 'application/octet-stream'},
        );

        if (response?.statusCode != 200) {
          print('오디오 데이터 전송 실패: ${response?.statusCode}');
        }
      } catch (e) {
        print('오디오 데이터 전송 오류: $e');
      }
    });

    onStateChanged?.call();
    return true;
  }

  /// 비디오 스트리밍 중지
  void stopVideoStreaming() {
    _isVideoStreamingEnabled = false;
    _stopVideoStreamTimer();
    onStateChanged?.call();
  }

  /// 오디오 스트리밍 중지
  void stopAudioStreaming() {
    _isAudioStreamingEnabled = false;
    _stopAudioStreamTimer();
    onStateChanged?.call();
  }

  /// 비디오 스트림 타이머 종료
  void _stopVideoStreamTimer() {
    _videoStreamTimer?.cancel();
    _videoStreamTimer = null;
  }

  /// 오디오 스트림 타이머 종료
  void _stopAudioStreamTimer() {
    _audioStreamTimer?.cancel();
    _audioStreamTimer = null;
  }

  /// 리소스 해제
  void dispose() {
    if (_isVideoStreamingEnabled) {
      stopVideoStreaming();
    }
    if (_isAudioStreamingEnabled) {
      stopAudioStreaming();
    }
  }
}
