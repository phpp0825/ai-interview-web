import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// 오디오 녹음 및 재생을 담당하는 서비스
class AudioService {
  // 상태 변수
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isInitialized = false;

  // 플랫폼 지원 여부 확인
  bool _isWebSupported = kIsWeb;

  // 오디오 플레이어
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 스트림 컨트롤러
  final StreamController<bool> _recordingStatusController =
      StreamController<bool>.broadcast();

  final StreamController<Uint8List> _audioDataController =
      StreamController<Uint8List>.broadcast();

  final StreamController<bool> _playbackStatusController =
      StreamController<bool>.broadcast();

  // 스트림 게터
  Stream<bool> get recordingStatus => _recordingStatusController.stream;
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  Stream<bool> get playbackStatus => _playbackStatusController.stream;

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

      // 오디오 플레이어 상태 리스너 설정
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _playbackStatusController.add(_isPlaying);
      });

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

  /// 오디오 바이트 데이터 재생 (TTS 음성 재생 등에 사용)
  Future<void> playAudioBytes(Uint8List audioBytes,
      {String? format, String? contentType}) async {
    if (!_isInitialized) {
      print('오디오 서비스가 초기화되지 않았습니다.');
      return;
    }

    if (_isPlaying) {
      await stopPlayback();
    }

    try {
      // 파일 형식 자동 감지 (contentType이 제공된 경우)
      String audioFormat = format ?? 'mp3';
      if (contentType != null) {
        if (contentType.contains('audio/mp3') ||
            contentType.contains('audio/mpeg')) {
          audioFormat = 'mp3';
        } else if (contentType.contains('audio/wav')) {
          audioFormat = 'wav';
        } else if (contentType.contains('audio/ogg')) {
          audioFormat = 'ogg';
        }
      } else if (format == null) {
        // 헤더 시그니처로 오디오 형식 추측 시도
        if (audioBytes.length > 4) {
          // MP3 파일 헤더 확인 (ID3 또는 MPEG 프레임 헤더)
          if ((audioBytes[0] == 0x49 &&
                  audioBytes[1] == 0x44 &&
                  audioBytes[2] == 0x33) || // "ID3"
              ((audioBytes[0] == 0xFF) && ((audioBytes[1] & 0xE0) == 0xE0))) {
            audioFormat = 'mp3';
          }
          // WAV 파일 헤더 확인 ("RIFF" + "WAVE")
          else if (audioBytes[0] == 0x52 &&
              audioBytes[1] == 0x49 &&
              audioBytes[2] == 0x46 &&
              audioBytes[3] == 0x46 &&
              audioBytes.length > 11 &&
              audioBytes[8] == 0x57 &&
              audioBytes[9] == 0x41 &&
              audioBytes[10] == 0x56 &&
              audioBytes[11] == 0x45) {
            audioFormat = 'wav';
          }
          // OGG 파일 헤더 확인 ("OggS")
          else if (audioBytes[0] == 0x4F &&
              audioBytes[1] == 0x67 &&
              audioBytes[2] == 0x67 &&
              audioBytes[3] == 0x53) {
            audioFormat = 'ogg';
          }
        }
      }

      print('오디오 형식 감지: $audioFormat (${audioBytes.length} 바이트)');

      // 웹 환경에서는 just_audio의 메모리 스트림 기능을 사용
      if (kIsWeb) {
        // 웹에서는 메모리에서 직접 재생
        try {
          final audioSource = LockCachingAudioSource(Uri.parse(
              'data:audio/$audioFormat;base64,${base64.encode(audioBytes)}'));
          await _audioPlayer.setAudioSource(audioSource);
        } catch (e) {
          print('웹에서 오디오 소스 설정 실패, 대체 방법 시도: $e');
          // 웹 환경에서 대체 방식: 메모리 소스 직접 사용
          // 임시 파일로 저장했다가 재생
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_audio.$audioFormat');
          await tempFile.writeAsBytes(audioBytes);
          await _audioPlayer.setFilePath(tempFile.path);
        }
      } else {
        // 네이티브 환경에서는 임시 파일에 쓰고 재생
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_audio.$audioFormat');
        await tempFile.writeAsBytes(audioBytes);
        await _audioPlayer.setFilePath(tempFile.path);
      }

      await _audioPlayer.play();
      _isPlaying = true;
      _playbackStatusController.add(_isPlaying);
      print('오디오 재생 시작');
    } catch (e) {
      print('오디오 재생 중 오류 발생: $e');
      _isPlaying = false;
      _playbackStatusController.add(_isPlaying);
      rethrow; // 상위 호출자에게 오류 전파 (오류 처리 개선)
    }
  }

  /// 재생 중지
  Future<void> stopPlayback() async {
    if (!_isPlaying) {
      return;
    }

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _playbackStatusController.add(_isPlaying);
      print('오디오 재생 중지');
    } catch (e) {
      print('오디오 재생 중지 중 오류 발생: $e');
    }
  }

  /// 리소스 해제
  void dispose() {
    if (_isRecording) {
      stopRecording();
    }

    if (_isPlaying) {
      stopPlayback();
    }

    _audioPlayer.dispose();
    _recordingStatusController.close();
    _audioDataController.close();
    _playbackStatusController.close();
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
