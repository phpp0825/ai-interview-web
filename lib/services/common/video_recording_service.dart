import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 비디오 녹화 관련 기능을 관리하는 서비스
/// 카메라 초기화 및 비디오 녹화와 관련된 기능만 처리합니다.
class VideoRecordingService {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isWeb = false;
  bool _isUsingDummyCamera = false;
  bool _isRecording = false;

  // 비디오 녹화 관련 변수
  String? _videoPath;
  List<XFile> _recordedVideoChunks = [];
  Timer? _recordingTimer;
  final int _maxChunkDuration = 5; // 청크 길이 (초)

  // 상태 게터
  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  bool get isWeb => _isWeb;
  bool get isUsingDummyCamera => _isUsingDummyCamera;
  bool get isRecording => _isRecording;
  String? get videoPath => _videoPath;

  /// 비디오 녹화 시작
  Future<bool> startVideoRecording() async {
    if (_isUsingDummyCamera) {
      print('더미 카메라 모드에서는 녹화할 수 없습니다.');
      return false;
    }

    if (!_isInitialized || _controller == null) {
      print('카메라가 초기화되지 않았습니다.');
      return false;
    }

    if (_isRecording) {
      print('이미 녹화 중입니다.');
      return true;
    }

    try {
      // 청크 방식 녹화 시작
      _recordedVideoChunks = [];
      _isRecording = true;

      // 첫 번째 청크 녹화 시작
      await _startRecordingChunk();

      return true;
    } catch (e) {
      print('비디오 녹화 시작 오류: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 청크 단위로 비디오 녹화 (길이 제한 방지)
  Future<void> _startRecordingChunk() async {
    if (!_isRecording || _controller == null) return;

    try {
      await _controller!.startVideoRecording();
      print('녹화 청크 시작');

      // 일정 시간 후 현재 청크 종료하고 새 청크 시작
      _recordingTimer = Timer(Duration(seconds: _maxChunkDuration), () async {
        if (_isRecording) {
          XFile videoFile = await _controller!.stopVideoRecording();
          _recordedVideoChunks.add(videoFile);
          print('녹화 청크 저장: ${videoFile.path}');

          // 계속 녹화 중이면 다음 청크 시작
          if (_isRecording) {
            await _startRecordingChunk();
          }
        }
      });
    } catch (e) {
      print('청크 녹화 시작 오류: $e');
    }
  }

  /// 비디오 녹화 중지 및 최종 파일 생성
  Future<String?> stopVideoRecording() async {
    if (!_isRecording) {
      print('녹화 중이 아닙니다.');
      return null;
    }

    try {
      // 타이머 취소
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // 현재 진행 중인 청크 종료
      XFile videoFile = await _controller!.stopVideoRecording();
      _recordedVideoChunks.add(videoFile);
      print('마지막 녹화 청크 저장: ${videoFile.path}');

      _isRecording = false;

      // 웹 환경인 경우 단일 청크만 반환 (병합 불가능)
      if (_isWeb) {
        if (_recordedVideoChunks.isNotEmpty) {
          _videoPath = _recordedVideoChunks.last.path;
          return _videoPath;
        }
        return null;
      }

      // 청크들을 하나의 MP4 파일로 합치기
      final mergedVideoPath = await _mergeVideoChunks();
      _videoPath = mergedVideoPath;

      return mergedVideoPath;
    } catch (e) {
      print('비디오 녹화 중지 오류: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 비디오 청크들을 하나의 MP4 파일로 합치기
  Future<String?> _mergeVideoChunks() async {
    if (_recordedVideoChunks.isEmpty) return null;

    try {
      // 비디오가 단일 청크인 경우 합칠 필요 없음
      if (_recordedVideoChunks.length == 1) {
        return _recordedVideoChunks.first.path;
      }

      // 임시 디렉토리 가져오기
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${tempDir.path}/merged_video_$timestamp.mp4';

      print('비디오 청크 합치기 시작: ${_recordedVideoChunks.length}개 청크');

      // TODO: 실제 구현에서는 FFmpeg 등을 사용하여 비디오 청크 병합
      // 현재는 단순히 첫 번째 청크 파일을 사용
      final firstChunk = _recordedVideoChunks.first;
      final File outputFile = File(outputPath);
      await File(firstChunk.path).copy(outputPath);

      print('비디오 청크 합치기 완료: $outputPath');
      return outputPath;
    } catch (e) {
      print('비디오 청크 합치기 오류: $e');
      // 실패 시 첫 번째 청크 반환
      return _recordedVideoChunks.isNotEmpty
          ? _recordedVideoChunks.first.path
          : null;
    }
  }

  /// 녹화된 비디오 파일 가져오기
  Future<Uint8List?> getRecordedVideoBytes() async {
    if (_videoPath == null) return null;

    try {
      final file = File(_videoPath!);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('비디오 파일 읽기 오류: $e');
      return null;
    }
  }

  /// 사용 가능한 카메라 목록 초기화
  Future<void> initialize() async {
    try {
      // 웹 환경 확인
      _isWeb = kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux;

      print(
          '카메라 초기화 시작: 웹 환경=$_isWeb, 플랫폼=${defaultTargetPlatform.toString()}');

      if (_isWeb) {
        // 웹 환경에서는 다른 초기화 처리
        try {
          _cameras = await availableCameras();
          print('웹 환경: 사용 가능한 카메라: ${_cameras?.length ?? 0}');

          if (_cameras != null && _cameras!.isNotEmpty) {
            await _initializeWebCamera(_cameras![0]);
          } else {
            print('웹 환경: 카메라를 찾을 수 없습니다.');
            await _initializeDummyCamera();
          }
        } catch (e) {
          print('웹 환경: 카메라 초기화 오류: $e');
          await _initializeDummyCamera();
        }
      } else {
        // 모바일 환경에서는 기존 방식으로 초기화
        try {
          _cameras = await availableCameras();
          print('모바일 환경: 사용 가능한 카메라: ${_cameras?.length ?? 0}');

          if (_cameras != null && _cameras!.isNotEmpty) {
            await _initializeCamera(_cameras![0]);
          } else {
            print('모바일 환경: 카메라를 찾을 수 없습니다.');
            await _initializeDummyCamera();
          }
        } catch (e) {
          print('모바일 환경: 카메라 초기화 오류: $e');
          await _initializeDummyCamera();
        }
      }
    } catch (e) {
      print('카메라 초기화 중 예외 발생: $e');
      await _initializeDummyCamera();
    }
  }

  /// 더미 카메라 초기화 (실제 카메라를 사용할 수 없는 환경용)
  Future<void> _initializeDummyCamera() async {
    print('더미 카메라 초기화 시작');
    _isUsingDummyCamera = true;
    _isInitialized = true;
    print('더미 카메라 초기화 완료');
  }

  /// 웹 카메라 초기화 (camera 패키지의 웹 구현 사용)
  Future<void> _initializeWebCamera(CameraDescription camera) async {
    print('웹 카메라 초기화 시작: ${camera.name}');

    try {
      // 웹 카메라 컨트롤러 생성
      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 웹에서 지원하는 해상도
        enableAudio: false, // 오디오 비활성화
      );

      // 카메라 초기화
      await _controller!.initialize();
      print('웹 카메라 컨트롤러 초기화 성공');

      _isInitialized = true;
      _isUsingDummyCamera = false;
      print('웹 카메라 초기화 완료');
    } catch (e) {
      print('웹 카메라 초기화 오류: $e');
      // 웹 카메라 초기화 실패 시 더미 카메라 사용
      await _initializeDummyCamera();
    }
  }

  /// 특정 카메라로 초기화 (네이티브)
  Future<void> _initializeCamera(CameraDescription camera) async {
    print('네이티브 카메라 초기화 시작: ${camera.name}');

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller?.initialize();
      print('네이티브 카메라 컨트롤러 초기화 성공');

      _isInitialized = true;
      _isUsingDummyCamera = false;
      print('네이티브 카메라 초기화 완료');
    } catch (e) {
      _isInitialized = false;
      print('네이티브 카메라 컨트롤러 초기화 오류: $e');
      // 오류 발생 시 더미 카메라로 대체
      await _initializeDummyCamera();
    }
  }

  /// 카메라 서비스 해제
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopVideoRecording();
      }

      if (!_isUsingDummyCamera && _controller != null) {
        await _controller!.dispose();
      }

      _recordingTimer?.cancel();
    } catch (e) {
      print('카메라 서비스 해제 오류: $e');
    }
  }

  /// 카메라 시작
  Future<void> startCamera() async {
    if (_isUsingDummyCamera) {
      // 더미 카메라는 아무것도 하지 않음
      return;
    }

    if (!_isInitialized || _controller == null) {
      print('카메라가 초기화되지 않았습니다.');
      return;
    }
  }

  /// 카메라 전환 (전면/후면)
  Future<void> switchCamera() async {
    if (_isUsingDummyCamera) {
      // 더미 카메라 모드에서는 아무것도 하지 않음
      return;
    }

    if (_cameras == null || _cameras!.length < 2) {
      print('카메라 전환 불가: 사용 가능한 카메라가 충분하지 않습니다.');
      return;
    }

    final int currentIndex = _cameras!.indexOf(_controller!.description);
    final int newIndex = (currentIndex + 1) % _cameras!.length;

    await _controller?.dispose();

    if (_isWeb) {
      await _initializeWebCamera(_cameras![newIndex]);
    } else {
      await _initializeCamera(_cameras![newIndex]);
    }
  }
}
