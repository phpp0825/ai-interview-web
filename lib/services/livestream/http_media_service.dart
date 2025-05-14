import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'http_streaming_service.dart';
import '../common/video_recording_service.dart';
import '../common/audio_service.dart';
import '../common/image_capture_service.dart';

/// HTTP를 통한 미디어 스트리밍 서비스
/// 비디오와 오디오 데이터 스트리밍 기능을 담당합니다.
class HttpMediaService {
  // 서비스 인스턴스
  final HttpStreamingService _httpService;

  // 카메라 및 오디오 서비스
  final VideoRecordingService _videoRecordingService = VideoRecordingService();
  final AudioService _audioService = AudioService();
  late final ImageCaptureService _imageCaptureService;

  // 타이머
  Timer? _videoStreamTimer;
  Timer? _audioStreamTimer;

  // 스트리밍 상태
  bool _isVideoStreaming = false;
  bool _isAudioStreaming = false;
  bool _isVideoRecording = false;
  bool _isProcessingData = false;

  // 비디오/오디오 프레임 수집을 위한 콜백
  Function()? _getVideoFrameCallback;
  Function()? _getAudioDataCallback;

  // 캡처된 마지막 프레임
  Uint8List? _lastCapturedVideoFrame;
  Uint8List? _lastCapturedAudioData;
  String? _recordedVideoPath;

  // 콜백 함수
  final Function(String) onError;
  final Function()? onStateChanged;

  // 비디오 프레임 null 발생 횟수 (연속으로 5회 이상이면 문제 있음)
  int _consecutiveNullVideoFrames = 0;
  static const int _maxConsecutiveNullFrames = 5;

  // 상태 getter
  bool get isVideoStreaming => _isVideoStreaming;
  bool get isAudioStreaming => _isAudioStreaming;
  bool get isVideoRecording => _isVideoRecording;
  Uint8List? get lastCapturedVideoFrame => _lastCapturedVideoFrame;
  Uint8List? get lastCapturedAudioData => _lastCapturedAudioData;
  String? get recordedVideoPath => _recordedVideoPath;

  HttpMediaService({
    required HttpStreamingService httpService,
    required this.onError,
    this.onStateChanged,
  }) : _httpService = httpService {
    // 이미지 캡처 서비스 초기화
    _imageCaptureService = ImageCaptureService(_videoRecordingService);

    // 기본 비디오 프레임 콜백 설정
    _getVideoFrameCallback = () async {
      return await _imageCaptureService.captureFrame();
    };

    // 기본 오디오 데이터 콜백 설정
    _getAudioDataCallback = () async {
      return await _audioService.captureAudioData();
    };

    // 연결 상태 변경 감지
    _httpService.connectionStatus.listen(_handleConnectionStatusChanged);
  }

  /// 연결 상태 변경 처리
  void _handleConnectionStatusChanged(ConnectionStatus status) {
    if (status != ConnectionStatus.connected) {
      // 연결이 끊어지면 스트리밍 중단
      if (_isVideoStreaming) {
        stopVideoStreaming();
      }

      if (_isAudioStreaming) {
        // Future 반환 메서드이므로 async 사용 불가 - 결과를 무시하고 호출
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
    if (_isVideoStreaming) {
      return true;
    }

    try {
      // 카메라 시작
      await _videoRecordingService.startCamera();

      // 이미지 스트림 시작
      await _imageCaptureService.startImageStream();

      // 비디오 스트리밍 시작
      _isVideoStreaming = true;
      _consecutiveNullVideoFrames = 0;

      // 기존 타이머 종료
      _stopVideoStreamTimer();

      // 새 타이머 시작 (3초마다 프레임 캡처만 진행하고 저장)
      _videoStreamTimer =
          Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (!_isVideoStreaming) {
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
              // 연속으로 null 프레임이 너무 많으면 로그만 출력
              print(
                  '연속 ${_consecutiveNullVideoFrames}번 비디오 프레임을 가져올 수 없습니다. 카메라가 없거나 비활성화되었을 수 있습니다.');
            }
            return;
          }

          // 정상 프레임을 받으면 카운터 초기화
          _consecutiveNullVideoFrames = 0;

          // 마지막 캡처 프레임 저장 (서버로 전송하지 않고 로컬에만 저장)
          _lastCapturedVideoFrame = jpegData;

          // 서버로 전송하는 코드는 제거
        } catch (e) {
          print('비디오 프레임 캡처 오류: $e');
        }
      });

      onStateChanged?.call();
      return true;
    } catch (e) {
      onError('비디오 스트리밍 시작 오류: $e');
      return false;
    }
  }

  /// 비디오 스트리밍 중지
  void stopVideoStreaming() {
    if (!_isVideoStreaming) {
      return;
    }

    _isVideoStreaming = false;
    _stopVideoStreamTimer();

    // 이미지 스트림 중지
    _imageCaptureService.stopImageStream();

    onStateChanged?.call();
  }

  /// 비디오 스트림 타이머 종료
  void _stopVideoStreamTimer() {
    _videoStreamTimer?.cancel();
    _videoStreamTimer = null;
  }

  /// 비디오 녹화 시작
  Future<bool> startVideoRecording() async {
    if (_isVideoRecording) {
      return true;
    }

    try {
      // 비디오 스트리밍이 활성화되어 있지 않다면 시작
      if (!_isVideoStreaming) {
        final success = await startVideoStreaming();
        if (!success) {
          onError('비디오 스트리밍을 시작할 수 없어 녹화를 시작할 수 없습니다.');
          return false;
        }
      }

      // 카메라 서비스를 통해 비디오 녹화 시작
      final success = await _videoRecordingService.startVideoRecording();
      if (success) {
        _isVideoRecording = true;
        onStateChanged?.call();
        print('비디오 녹화가 시작되었습니다.');
        return true;
      } else {
        onError('비디오 녹화를 시작할 수 없습니다.');
        return false;
      }
    } catch (e) {
      onError('비디오 녹화 시작 오류: $e');
      return false;
    }
  }

  /// 비디오 녹화 중지
  Future<String?> stopVideoRecording() async {
    if (!_isVideoRecording) {
      return null;
    }

    try {
      // 카메라 서비스를 통해 비디오 녹화 중지
      final videoPath = await _videoRecordingService.stopVideoRecording();
      _isVideoRecording = false;
      _recordedVideoPath = videoPath;

      onStateChanged?.call();
      print('비디오 녹화가 중지되었습니다. 경로: $videoPath');
      return videoPath;
    } catch (e) {
      onError('비디오 녹화 중지 오류: $e');
      _isVideoRecording = false;
      onStateChanged?.call();
      return null;
    }
  }

  /// 녹화된 비디오 파일 가져오기
  Future<Uint8List?> getRecordedVideoBytes() async {
    if (_recordedVideoPath == null) {
      return null;
    }

    try {
      return await _videoRecordingService.getRecordedVideoBytes();
    } catch (e) {
      onError('녹화된 비디오 파일 읽기 오류: $e');
      return null;
    }
  }

  /// 오디오 스트리밍 시작
  Future<bool> startAudioStreaming() async {
    if (_isAudioStreaming) {
      return true;
    }

    try {
      // 오디오 시작 - await만 사용하고 결과는 무시 (void 반환)
      await _audioService.startRecording();

      // AudioService가 시작됐다고 가정
      _isAudioStreaming = true;

      // 기존 타이머 종료
      _stopAudioStreamTimer();

      // 새 타이머 시작 (1초마다 오디오 데이터 캡처만 진행)
      _audioStreamTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!_isAudioStreaming) {
          timer.cancel();
          return;
        }

        try {
          // 콜백으로부터 현재 오디오 데이터 가져오기
          final Uint8List? audioData = await _getAudioDataCallback!();

          // 오디오 데이터가 null인 경우 처리
          if (audioData == null || audioData.isEmpty) {
            return;
          }

          // 마지막 캡처된 오디오 데이터 저장 (서버로 전송하지 않고 로컬에만 저장)
          _lastCapturedAudioData = audioData;

          // 서버로 전송하는 코드는 제거
        } catch (e) {
          print('오디오 데이터 캡처 오류: $e');
        }
      });

      onStateChanged?.call();
      return true;
    } catch (e) {
      onError('오디오 스트리밍 시작 오류: $e');
      return false;
    }
  }

  /// 오디오 스트리밍 중지
  Future<bool> stopAudioStreaming() async {
    if (!_isAudioStreaming) {
      return true;
    }

    try {
      // void를 반환하는 메서드 호출 후 결과 무시
      await _audioService.stopRecording();
      _isAudioStreaming = false;
      _stopAudioStreamTimer();
      onStateChanged?.call();

      return true;
    } catch (e) {
      onError('오디오 스트리밍 중지 오류: $e');
      return false;
    }
  }

  /// 오디오 스트림 타이머 종료
  void _stopAudioStreamTimer() {
    _audioStreamTimer?.cancel();
    _audioStreamTimer = null;
  }

  /// 서버로 업로드를 위한 처리 여부 설정
  void setProcessingData(bool processing) {
    _isProcessingData = processing;
  }

  /// 리소스 해제
  void dispose() {
    try {
      if (_isVideoStreaming) {
        stopVideoStreaming();
      }

      if (_isAudioStreaming) {
        // Future를 반환하지만 동기 컨텍스트에서 호출되므로 결과 무시
        stopAudioStreaming();
      }

      if (_isVideoRecording) {
        // Future를 반환하지만 동기 컨텍스트에서 호출되므로 결과 무시
        stopVideoRecording();
      }

      // 이미지 캡처 서비스 해제
      _imageCaptureService.dispose();

      // 카메라 및 오디오 서비스 해제
      _videoRecordingService.dispose();
      _audioService.dispose();
    } catch (e) {
      print('미디어 서비스 해제 오류: $e');
    }
  }
}
