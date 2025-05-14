import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// 오디오 녹음 및 재생을 담당하는 서비스
class AudioService {
  // 상태 변수
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isInitialized = false;

  // 플랫폼 지원 여부 확인
  bool _isWebSupported = kIsWeb;

  // 스트림 컨트롤러
  final StreamController<bool> _recordingStatusController =
      StreamController<bool>.broadcast();

  final StreamController<Uint8List> _audioDataController =
      StreamController<Uint8List>.broadcast();

  // 스트림 게터
  Stream<bool> get recordingStatus => _recordingStatusController.stream;
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;

  // 상태 게터
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  bool get isWebSupported => _isWebSupported;

  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      // 웹 환경에서 오디오 접근 권한 및 지원 여부 확인
      if (kIsWeb) {
        print('웹 오디오 초기화 시도');
        await _initWebAudio();
      }
      // 기타 플랫폼 초기화 (Android, iOS)
      else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        // TODO: 네이티브 플랫폼 오디오 초기화 로직 구현
        print('네이티브 오디오 초기화 - 아직 미구현');
      } else {
        print('현재 플랫폼에서는 오디오 기능이 지원되지 않음: $defaultTargetPlatform');
      }

      _isInitialized = true;
    } catch (e) {
      print('오디오 초기화 오류: $e');
      _isInitialized = false;
    }
  }

  /// 웹 환경에서 오디오 초기화
  Future<void> _initWebAudio() async {
    try {
      // Web Audio API 사용 준비
      // 여기서 자바스크립트 interop으로 실제 초기화를 수행하거나,
      // 웹에서 사용할 패키지 초기화 코드를 작성해야 합니다.
      print('웹 오디오 지원 확인됨');
      _isWebSupported = true;
    } catch (e) {
      print('웹 오디오 초기화 오류: $e');
      _isWebSupported = false;
    }
  }

  /// 오디오 녹음 시작
  Future<void> startRecording() async {
    if (_isRecording) {
      print('이미 녹음 중입니다.');
      return;
    }

    try {
      // 웹 환경에서 오디오 녹음
      if (kIsWeb) {
        if (!_isWebSupported) {
          print('이 브라우저에서는 오디오 녹음이 지원되지 않습니다.');
          return;
        }

        // 웹에서 JavaScript 상호운용을 통해 마이크 접근 및 녹음 시작
        // 실제 구현 시에는 js 패키지나 plugin_web을 통해 구현해야 합니다
        print('웹 브라우저에서 녹음 시작');
        _startWebRecording();
      }
      // 네이티브 환경에서 오디오 녹음 (미구현)
      else {
        print('네이티브 오디오 녹음 - 아직 미구현');
      }

      _isRecording = true;
      _recordingStatusController.add(_isRecording);

      print('녹음 시작됨');
    } catch (e) {
      print('녹음 시작 중 오류 발생: $e');
      _isRecording = false;
      _recordingStatusController.add(_isRecording);
    }
  }

  /// 웹 환경에서 오디오 녹음 시작
  Future<void> _startWebRecording() async {
    // 여기에 웹 환경에서의 녹음 시작 로직 구현
    // JavaScript interop 코드가 필요합니다.
    // 주기적으로 오디오 데이터 샘플을 _audioDataController로 전송하는 코드 구현

    // 예시: 테스트용 더미 데이터 생성 (실제 구현 시 제거)
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      // 더미 오디오 데이터 (실제 구현 시 실제 마이크 데이터로 대체)
      final dummyData = Uint8List.fromList(List.generate(320, (i) => i % 256));
      _audioDataController.add(dummyData);
    });
  }

  /// 오디오 녹음 중지
  Future<void> stopRecording() async {
    if (!_isRecording) {
      print('녹음 중이 아닙니다.');
      return;
    }

    try {
      // 웹 환경에서 오디오 녹음 중지
      if (kIsWeb) {
        // 웹 녹음 중지 로직
        print('웹 브라우저에서 녹음 중지');
      }
      // 네이티브 환경에서 오디오 녹음 중지 (미구현)
      else {
        print('네이티브 오디오 녹음 중지 - 아직 미구현');
      }

      _isRecording = false;
      _recordingStatusController.add(_isRecording);

      print('녹음 중지됨');
    } catch (e) {
      print('녹음 중지 중 오류 발생: $e');
    }
  }

  /// 리소스 해제
  void dispose() {
    if (_isRecording) {
      stopRecording();
    }

    _recordingStatusController.close();
    _audioDataController.close();
  }

  /// 현재 오디오 데이터 캡처
  Future<Uint8List?> captureAudioData() async {
    if (!_isInitialized) {
      print('오디오 서비스가 초기화되지 않았습니다.');
      return null;
    }

    // 녹음 중이 아니면 녹음 시작
    if (!_isRecording) {
      await startRecording();
    }

    // 웹 환경에서는 더미 데이터 생성 (실제 구현 시 마이크에서 데이터 캡처)
    if (kIsWeb) {
      // 더미 오디오 데이터 (실제 구현 시 실제 마이크 데이터로 대체)
      return Uint8List.fromList(List.generate(320, (i) => i % 256));
    }
    // 네이티브 환경에서의 구현 (미구현)
    else {
      print('네이티브 환경에서의 오디오 캡처 - 아직 미구현');
      // 테스트를 위한 더미 데이터
      return Uint8List.fromList(List.generate(320, (i) => i % 256));
    }
  }
}
