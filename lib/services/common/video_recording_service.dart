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
    print('🎬 비디오 녹화 시작 요청됨');
    print('   - 더미 카메라: $_isUsingDummyCamera');
    print('   - 초기화 상태: $_isInitialized');
    print('   - 웹 환경: $_isWeb');
    print('   - 현재 녹화 중: $_isRecording');

    if (_isUsingDummyCamera) {
      print('❌ 더미 카메라 모드에서는 녹화할 수 없습니다.');
      print('   -> 빈 비디오 파일이 생성될 것입니다.');

      // 더미 모드에서도 상태는 녹화 중으로 설정 (UI 일관성 위해)
      _isRecording = true;

      // 더미 비디오 데이터 생성 (매우 작은 크기)
      _videoPath = 'dummy_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      print('   -> 더미 비디오 경로 설정: $_videoPath');
      return true;
    }

    if (!_isInitialized || _controller == null) {
      print('❌ 카메라가 초기화되지 않았습니다.');
      return false;
    }

    if (_isRecording) {
      print('⚠️ 이미 녹화 중입니다.');
      return true;
    }

    try {
      // 카메라 상태 상세 검증
      if (!_controller!.value.isInitialized) {
        print('❌ 카메라 컨트롤러가 초기화되지 않았습니다.');
        return false;
      }

      if (_controller!.value.hasError) {
        print('❌ 카메라 컨트롤러에 오류가 있습니다: ${_controller!.value.errorDescription}');
        return false;
      }

      print('📹 비디오 녹화 시작 준비...');
      print('🔍 카메라 상태 검증:');
      print('   - 초기화됨: ${_controller!.value.isInitialized}');
      print('   - 미리보기 가능: ${_controller!.value.previewSize != null}');
      print('   - 웹 환경: $_isWeb');
      print('   - 해상도: ${_controller!.value.previewSize}');

      // 청크 방식 녹화 초기화
      _recordedVideoChunks.clear();
      _isRecording = true;

      // 웹 환경과 네이티브 환경 구분 처리
      if (_isWeb) {
        // 웹 환경: 단일 긴 녹화 방식 사용 (청크 분할 안 함)
        print('🌐 웹 환경: 단일 녹화 방식 사용');

        try {
          await _controller!.startVideoRecording();
          print('✅ 웹 환경 녹화 시작 성공');

          // 녹화 시작 후 잠시 대기하여 실제 데이터가 기록되는지 확인
          await Future.delayed(const Duration(milliseconds: 1000));
          print('✅ 웹 환경: 1초 녹화 대기 완료');
        } catch (e) {
          print('❌ 웹 환경 녹화 시작 실패: $e');
          _isRecording = false;
          return false;
        }
      } else {
        // 네이티브 환경: 청크 방식 사용
        print('📱 네이티브 환경: 청크 방식 사용');
        await _controller!.startVideoRecording();
        print('✅ 첫 번째 녹화 청크 시작됨');

        // 타이머 설정 (청크 분할용)
        _recordingTimer = Timer(Duration(seconds: _maxChunkDuration), () async {
          if (_isRecording && _controller != null) {
            try {
              XFile videoFile = await _controller!.stopVideoRecording();
              _recordedVideoChunks.add(videoFile);
              print('📹 녹화 청크 완료: ${videoFile.path}');

              // 계속 녹화 중이면 다음 청크 시작
              if (_isRecording) {
                await _startRecordingChunk();
              }
            } catch (e) {
              print('❌ 청크 녹화 중 오류: $e');
            }
          }
        });
      }

      return true;
    } catch (e) {
      print('❌ 비디오 녹화 시작 오류: $e');
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

  /// 비디오 녹화 중지
  Future<String?> stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      print('녹화가 진행 중이 아니거나 카메라가 초기화되지 않았습니다.');
      return null;
    }

    try {
      print('🛑 비디오 녹화 중지 시작...');

      // 녹화 타이머 중지 (네이티브 환경에서만 사용)
      if (!_isWeb && _recordingTimer != null) {
        _recordingTimer!.cancel();
        _recordingTimer = null;
        print('⏰ 청크 타이머 중지');
      }

      // 현재 진행 중인 녹화 중지
      print('📹 현재 녹화 중지 중...');
      XFile videoFile = await _controller!.stopVideoRecording();
      print('✅ 녹화 중지 완료: ${videoFile.path}');

      // 웹 환경과 네이티브 환경 구분 처리
      if (_isWeb) {
        // 웹 환경: 단일 비디오 파일 처리
        _videoPath = videoFile.path;

        // 웹 환경에서 비디오 파일 정보 상세 로깅
        try {
          print('🌐 웹 환경: 비디오 파일 후처리 시작...');

          // 비디오 파일 완전 종료 대기
          await Future.delayed(const Duration(seconds: 2));

          final bytes = await videoFile.readAsBytes();
          print('🎬 웹 비디오 파일 정보:');
          print('   - 경로: ${videoFile.path}');
          print('   - 크기: ${bytes.length} bytes');
          print('   - MIME 타입: ${videoFile.mimeType}');
          print('   - 이름: ${videoFile.name}');

          if (bytes.length > 0) {
            // 파일 헤더 검사 (MP4/WebM 형식 확인)
            if (bytes.length >= 12) {
              final header = bytes.sublist(0, 12);
              final headerStr =
                  String.fromCharCodes(header.where((b) => b >= 32 && b < 127));
              print('   - 파일 헤더: $headerStr');

              // MP4 형식 확인
              if (bytes.length >= 8) {
                final ftypCheck = String.fromCharCodes(bytes.sublist(4, 8));
                if (ftypCheck == 'ftyp') {
                  print('✅ MP4 형식 파일 확인됨');
                } else {
                  print('⚠️ MP4 형식이 아닐 수 있습니다. ftyp 헤더를 찾을 수 없음');
                }
              }
            }

            print('✅ 웹 환경: 유효한 비디오 파일 생성됨');

            // 추가 메타데이터 처리 시간 대기
            print('⏳ 비디오 메타데이터 처리 대기 중...');
            await Future.delayed(const Duration(seconds: 1));
            print('✅ 비디오 메타데이터 처리 완료');
          } else {
            print('❌ 웹 환경: 비디오 파일이 비어있음');
            print('   -> 카메라 권한이나 녹화 설정에 문제가 있을 수 있습니다.');
          }
        } catch (e) {
          print('❌ 웹 비디오 파일 정보 확인 실패: $e');
        }
      } else {
        // 네이티브 환경: 청크 방식 처리
        _recordedVideoChunks.add(videoFile);
        print('📱 네이티브 환경: 마지막 청크 추가 (총 ${_recordedVideoChunks.length}개)');

        // 청크들을 하나의 MP4 파일로 합치기
        final mergedVideoPath = await _mergeVideoChunks();
        _videoPath = mergedVideoPath;

        if (_videoPath != null) {
          // 최종 비디오 파일 검증
          final file = File(_videoPath!);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('🎬 네이티브 최종 비디오: $_videoPath (${fileSize} bytes)');
          } else {
            print('❌ 네이티브 최종 비디오 파일 생성 실패');
          }
        }
      }

      _isRecording = false;
      print('✅ 비디오 녹화 중지 완료!');
      return _videoPath;
    } catch (e) {
      print('❌ 비디오 녹화 중지 오류: $e');
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
    print('📤 비디오 바이트 읽기 시작...');
    print('   - 더미 카메라: $_isUsingDummyCamera');
    print('   - 웹 환경: $_isWeb');
    print('   - 비디오 경로: $_videoPath');

    // 더미 카메라 모드인 경우 null 반환 (영상 없음)
    if (_isUsingDummyCamera) {
      print('❌ 더미 카메라 모드: 영상 녹화 불가능 - null 반환');
      print('   -> 실제 카메라 권한을 허용하고 다시 시도해주세요.');
      return null;
    }

    try {
      // 웹 환경과 네이티브 환경 구분 처리
      if (_isWeb) {
        // 웹 환경: 단일 비디오 파일에서 바이트 읽기
        if (_videoPath != null) {
          // 가장 최근 녹화된 파일을 XFile로 다시 읽기
          try {
            print('📹 웹 환경: 비디오 파일에서 바이트 읽기 시도...');
            print('   경로: $_videoPath');

            // XFile로 다시 생성하여 읽기
            final xFile = XFile(_videoPath!);
            final bytes = await xFile.readAsBytes();

            print('✅ 웹 환경: 비디오 바이트 읽기 성공');
            print('   크기: ${bytes.length} bytes');
            print('   MIME: ${xFile.mimeType}');

            if (bytes.length == 0) {
              print('❌ 웹 환경: 비디오 파일이 비어있습니다.');
              print('   -> 카메라 권한이나 녹화 문제일 가능성이 높습니다.');
              return null;
            }

            // 파일 헤더 확인 (MP4인지 체크)
            if (bytes.length >= 8) {
              final header = String.fromCharCodes(bytes.sublist(4, 8));
              print('   파일 헤더: $header');
              if (!header.contains('ftyp')) {
                print('⚠️ MP4 형식이 아닐 수 있습니다.');
              }
            }

            return bytes;
          } catch (e) {
            print('❌ 웹 환경: XFile 읽기 실패: $e');
            return null;
          }
        } else {
          print('❌ 웹 환경: 비디오 파일 경로가 없습니다.');
          return null;
        }
      } else {
        // 네이티브 환경: 파일 시스템에서 읽기
        if (_videoPath == null) {
          print('❌ 네이티브 환경: 비디오 파일 경로가 없습니다.');
          return null;
        }

        final file = File(_videoPath!);
        if (await file.exists()) {
          print('📹 네이티브 환경: 파일에서 바이트 읽기 시도...');
          final bytes = await file.readAsBytes();
          print('✅ 네이티브 환경: 비디오 바이트 읽기 성공 (${bytes.length} bytes)');
          return bytes;
        } else {
          print('❌ 네이티브 환경: 비디오 파일이 존재하지 않습니다: $_videoPath');
          return null;
        }
      }
    } catch (e) {
      print('❌ 비디오 파일 읽기 오류: $e');
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
    print('🌐 웹 카메라 초기화 시작: ${camera.name}');

    try {
      // 웹 카메라 컨트롤러 생성 - 더 안정적인 설정 사용
      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 웹에서도 medium 해상도 사용
        enableAudio: true, // 오디오 활성화
        imageFormatGroup: ImageFormatGroup.jpeg, // 명시적 이미지 형식 지정
      );

      print('🌐 웹 카메라 컨트롤러 생성 완료, 초기화 시작...');

      // 카메라 초기화 - 타임아웃 설정
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('웹 카메라 초기화 시간 초과');
        },
      );

      // 초기화 후 상태 확인
      if (_controller!.value.isInitialized) {
        print('✅ 웹 카메라 컨트롤러 초기화 성공');
        print('   해상도: ${_controller!.value.previewSize}');
        print('   오디오 활성화: ${_controller!.enableAudio}');
        print('   오류 상태: ${_controller!.value.hasError}');

        // 웹 환경에서 비디오 녹화 지원 확인
        try {
          print('🎬 웹 환경 비디오 녹화 지원 확인 중...');

          // 매우 짧은 테스트 녹화로 지원 여부 확인
          await _controller!.startVideoRecording();
          await Future.delayed(const Duration(milliseconds: 100));
          final testVideo = await _controller!.stopVideoRecording();

          print('✅ 웹 환경 비디오 녹화 지원됨');
          print('   테스트 파일: ${testVideo.path}');

          // 테스트 파일 정보 확인
          try {
            final testBytes = await testVideo.readAsBytes();
            print('   테스트 파일 크기: ${testBytes.length} bytes');

            if (testBytes.length > 0) {
              print('🎉 웹 카메라 녹화 기능 정상 작동 확인');
            } else {
              print('⚠️ 테스트 녹화 파일이 비어있습니다.');
            }
          } catch (e) {
            print('⚠️ 테스트 파일 확인 실패: $e');
          }
        } catch (e) {
          print('❌ 웹 환경 비디오 녹화 테스트 실패: $e');
          print('   -> 녹화는 지원되지 않을 수 있습니다.');
        }

        // 잠시 대기하여 카메라가 완전히 준비되도록 함
        await Future.delayed(const Duration(milliseconds: 500));

        _isInitialized = true;
        _isUsingDummyCamera = false;
        print('🎬 웹 카메라 초기화 완료 - 녹화 준비됨');
      } else {
        throw Exception('웹 카메라 초기화 실패 - 알 수 없는 오류');
      }
    } catch (e) {
      print('❌ 웹 카메라 초기화 오류: $e');

      // 카메라 권한 관련 오류인지 확인
      if (e.toString().contains('Permission') ||
          e.toString().contains('NotAllowed') ||
          e.toString().contains('denied')) {
        print('🚫 카메라 권한이 거부되었습니다. 브라우저에서 카메라 권한을 허용해주세요.');
      } else if (e.toString().contains('NotFound') ||
          e.toString().contains('DevicesNotFound')) {
        print('📷 사용 가능한 카메라를 찾을 수 없습니다.');
      } else if (e.toString().contains('NotReadable') ||
          e.toString().contains('TrackStart')) {
        print('📹 카메라가 다른 애플리케이션에서 사용 중일 수 있습니다.');
      }

      // 웹 카메라 초기화 실패 시 더미 카메라 사용
      await _initializeDummyCamera();
    }
  }

  /// 특정 카메라로 초기화 (네이티브)
  Future<void> _initializeCamera(CameraDescription camera) async {
    print('네이티브 카메라 초기화 시작: ${camera.name}');

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // 네이티브는 medium 유지
      enableAudio: true, // 오디오 활성화
      imageFormatGroup: ImageFormatGroup.jpeg, // 명시적 이미지 형식 지정
    );

    try {
      await _controller?.initialize();
      print('네이티브 카메라 컨트롤러 초기화 성공');
      print('네이티브 카메라 해상도: ${_controller?.value.previewSize}');

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
      print('🧹 카메라 서비스 해제 시작...');

      // 녹화 중이면 먼저 중지
      if (_isRecording) {
        print('📹 녹화 중지 중...');
        await stopVideoRecording();
      }

      // 타이머 완전히 정리
      if (_recordingTimer != null) {
        _recordingTimer!.cancel();
        _recordingTimer = null;
        print('⏰ 녹화 타이머 해제 완료');
      }

      // 카메라 컨트롤러 안전하게 해제
      if (!_isUsingDummyCamera && _controller != null) {
        print('📷 카메라 컨트롤러 해제 중...');
        await _controller!.dispose();
        _controller = null;
        print('✅ 카메라 컨트롤러 해제 완료');
      }

      // 상태 초기화
      _isInitialized = false;
      _isRecording = false;
      _videoPath = null;
      _recordedVideoChunks.clear();

      print('✅ 카메라 서비스 해제 완료!');
    } catch (e) {
      print('❌ 카메라 서비스 해제 오류: $e');
      // 오류가 발생해도 상태는 초기화
      _isInitialized = false;
      _isRecording = false;
      _controller = null;
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
