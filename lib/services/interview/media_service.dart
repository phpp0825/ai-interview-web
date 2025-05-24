import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'interfaces/media_service_interface.dart';
import 'interfaces/streaming_service_interface.dart';
import '../common/video_recording_service.dart';

/// HTTP 통신을 이용한 미디어 서비스 구현
class MediaService implements IMediaService {
  // 서비스 인스턴스
  final IStreamingService _httpService;
  final VideoRecordingService _cameraService;

  // 콜백 함수
  final Function(String) onError;
  final Function()? onStateChanged;

  // 상태 변수
  bool _isVideoStreaming = false;
  bool _isAudioStreaming = false;
  bool _isVideoRecording = false;
  Timer? _videoStreamTimer;
  Timer? _audioStreamTimer;

  // 비디오/오디오 프레임 수집을 위한 콜백
  Future<Uint8List?> Function()? _videoFrameCallback;
  Future<Uint8List?> Function()? _audioDataCallback;

  // 캡처된 마지막 프레임
  Uint8List? _lastVideoFrame;
  Uint8List? _lastAudioData;
  String? _recordedVideoPath;

  // 상태 getter
  bool get isVideoStreaming => _isVideoStreaming;
  bool get isAudioStreaming => _isAudioStreaming;
  bool get isVideoRecording => _isVideoRecording;

  @override
  Uint8List? get lastCapturedVideoFrame => _lastVideoFrame;

  @override
  Uint8List? get lastCapturedAudioData => _lastAudioData;

  String? get recordedVideoPath => _recordedVideoPath;

  MediaService({
    required IStreamingService httpService,
    required VideoRecordingService cameraService,
    required this.onError,
    this.onStateChanged,
  })  : _httpService = httpService,
        _cameraService = cameraService;

  /// 서버 연결
  @override
  Future<bool> connect(String serverUrl) async {
    try {
      return await _httpService.connect(serverUrl);
    } catch (e) {
      onError('미디어 서비스: 서버 연결 실패 - $e');
      return false;
    }
  }

  /// 서버 연결 해제
  @override
  Future<void> disconnect() async {
    try {
      // 스트리밍 중이면 먼저 중지
      stopVideoStreaming();
      stopAudioStreaming();

      await _httpService.disconnect();
    } catch (e) {
      onError('미디어 서비스: 서버 연결 해제 실패 - $e');
    }
  }

  /// 비디오 프레임 콜백 설정
  @override
  void setVideoFrameCallback(Future<Uint8List?> Function() callback) {
    _videoFrameCallback = callback;
  }

  /// 오디오 데이터 콜백 설정
  @override
  void setAudioDataCallback(Future<Uint8List?> Function() callback) {
    _audioDataCallback = callback;
  }

  /// 비디오 스트리밍 시작
  @override
  Future<bool> startVideoStreaming() async {
    if (_isVideoStreaming) return true;

    if (_videoFrameCallback == null) {
      onError('미디어 서비스: 비디오 프레임 콜백이 설정되지 않았습니다');
      return false;
    }

    try {
      // 비디오 초기화 요청
      final response = await _httpService.post('start_video', {});

      if (response?.statusCode != 200) {
        onError('미디어 서비스: 비디오 스트리밍 시작 실패 - ${response?.statusCode}');
        return false;
      }

      // 타이머 설정 (초당 30프레임)
      _videoStreamTimer = Timer.periodic(
        const Duration(milliseconds: 33), // 약 30 FPS
        (_) => _sendVideoFrame(),
      );

      _isVideoStreaming = true;
      onStateChanged?.call();
      return true;
    } catch (e) {
      onError('미디어 서비스: 비디오 스트리밍 시작 오류 - $e');
      return false;
    }
  }

  /// 비디오 스트리밍 중지
  @override
  void stopVideoStreaming() {
    if (!_isVideoStreaming) return;

    try {
      _videoStreamTimer?.cancel();
      _isVideoStreaming = false;

      // 서버에 비디오 중지 요청
      _httpService.post('stop_video', {}).catchError((e) {
        onError('미디어 서비스: 비디오 중지 요청 실패 - $e');
      });
    } catch (e) {
      onError('미디어 서비스: 비디오 스트리밍 중지 오류 - $e');
    }
  }

  /// 오디오 스트리밍 시작
  @override
  Future<bool> startAudioStreaming() async {
    if (_isAudioStreaming) return true;

    if (_audioDataCallback == null) {
      onError('미디어 서비스: 오디오 데이터 콜백이 설정되지 않았습니다');
      return false;
    }

    try {
      // 오디오 초기화 요청
      final response = await _httpService.post('start_audio', {});

      if (response?.statusCode != 200) {
        onError('미디어 서비스: 오디오 스트리밍 시작 실패 - ${response?.statusCode}');
        return false;
      }

      // 타이머 설정 (200ms 간격)
      _audioStreamTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) => _sendAudioData(),
      );

      _isAudioStreaming = true;
      onStateChanged?.call();
      return true;
    } catch (e) {
      onError('미디어 서비스: 오디오 스트리밍 시작 오류 - $e');
      return false;
    }
  }

  /// 오디오 스트리밍 중지
  @override
  void stopAudioStreaming() {
    if (!_isAudioStreaming) return;

    try {
      _audioStreamTimer?.cancel();
      _isAudioStreaming = false;

      // 서버에 오디오 중지 요청
      _httpService.post('stop_audio', {}).catchError((e) {
        onError('미디어 서비스: 오디오 중지 요청 실패 - $e');
      });
    } catch (e) {
      onError('미디어 서비스: 오디오 스트리밍 중지 오류 - $e');
    }
  }

  /// 비디오 프레임 전송
  Future<void> _sendVideoFrame() async {
    try {
      if (_videoFrameCallback != null) {
        final frameData = await _videoFrameCallback!();
        if (frameData != null && frameData.isNotEmpty) {
          _lastVideoFrame = frameData;
          await sendVideoFrame();
        }
      }
    } catch (e) {
      print('미디어 서비스: 비디오 프레임 전송 오류 - $e');
    }
  }

  /// 오디오 데이터 전송
  Future<void> _sendAudioData() async {
    try {
      if (_audioDataCallback != null) {
        final audioData = await _audioDataCallback!();
        if (audioData != null && audioData.isNotEmpty) {
          _lastAudioData = audioData;
          await sendAudioData();
        }
      }
    } catch (e) {
      print('미디어 서비스: 오디오 데이터 전송 오류 - $e');
    }
  }

  /// 비디오 프레임 전송
  @override
  Future<http.Response?> sendVideoFrame() async {
    if (!_httpService.isConnected || _lastVideoFrame == null) {
      return null;
    }

    try {
      return await _httpService.post(
        'video_frame',
        _lastVideoFrame!,
        headers: {'Content-Type': 'application/octet-stream'},
      );
    } catch (e) {
      print('미디어 서비스: 비디오 프레임 전송 오류 - $e');
      return null;
    }
  }

  /// 오디오 데이터 전송
  @override
  Future<http.Response?> sendAudioData() async {
    if (!_httpService.isConnected || _lastAudioData == null) {
      return null;
    }

    try {
      return await _httpService.post(
        'audio_data',
        _lastAudioData!,
        headers: {'Content-Type': 'application/octet-stream'},
      );
    } catch (e) {
      print('미디어 서비스: 오디오 데이터 전송 오류 - $e');
      return null;
    }
  }

  /// 리소스 해제
  @override
  void dispose() {
    if (_isVideoStreaming) {
      stopVideoStreaming();
    }

    if (_isAudioStreaming) {
      stopAudioStreaming();
    }
    if (_isVideoRecording) {
      stopVideoRecording();
    }
  }

  // 로컬 비디오 녹화 기능
  Future<bool> startVideoRecording() async {
    if (_isVideoRecording) {
      return true;
    }

    try {
      final success = await _cameraService.startVideoRecording();
      _isVideoRecording = success;
      onStateChanged?.call();
      return success;
    } catch (e) {
      onError('비디오 녹화 시작 중 오류 발생: $e');
      return false;
    }
  }

  Future<String?> stopVideoRecording() async {
    if (!_isVideoRecording) {
      return null;
    }

    try {
      final videoPath = await _cameraService.stopVideoRecording();
      _isVideoRecording = false;
      _recordedVideoPath = videoPath;
      onStateChanged?.call();
      return videoPath;
    } catch (e) {
      onError('비디오 녹화 중지 중 오류 발생: $e');
      _isVideoRecording = false;
      return null;
    }
  }
}
