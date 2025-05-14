import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../utils/camera_utils.dart';

/// 카메라 관련 기능을 관리하는 서비스
class CameraService {
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isWeb = false;
  bool _isUsingDummyCamera = false;

  final StreamController<CameraImage> _cameraImageStreamController =
      StreamController<CameraImage>.broadcast();

  // 마지막으로 캡처된 이미지 저장
  CameraImage? _lastCapturedImage;
  Uint8List? _lastCapturedImageData;

  // 외부에서 접근할 수 있는 스트림 getter
  Stream<CameraImage> get cameraImageStream =>
      _cameraImageStreamController.stream;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  bool get isWeb => _isWeb;
  bool get isUsingDummyCamera => _isUsingDummyCamera;

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
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 카메라 초기화
      await _controller!.initialize();
      print('웹 카메라 컨트롤러 초기화 성공');

      // 이미지 스트림 설정 시도
      try {
        await _controller!.startImageStream((CameraImage image) {
          if (!_cameraImageStreamController.isClosed) {
            _cameraImageStreamController.add(image);
            _lastCapturedImage = image;
          }
        });
        print('웹 카메라 이미지 스트림 시작됨');
      } catch (e) {
        print('웹 카메라 이미지 스트림 시작 실패: $e');
        // 이미지 스트림이 지원되지 않는 경우에도 초기화는 유지
      }

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

      // 이미지 스트림 설정
      await _controller?.startImageStream((CameraImage image) {
        if (!_cameraImageStreamController.isClosed) {
          _cameraImageStreamController.add(image);
          _lastCapturedImage = image; // 마지막 이미지 저장
        }
      });
      print('네이티브 카메라 이미지 스트림 시작됨');
    } catch (e) {
      _isInitialized = false;
      print('네이티브 카메라 컨트롤러 초기화 오류: $e');
      // 오류 발생 시 더미 카메라로 대체
      await _initializeDummyCamera();
    }
  }

  /// 현재 비디오 프레임을 JPEG 형식으로 캡처
  Future<Uint8List?> captureFrame() async {
    // 더미 카메라 사용 중일 때
    if (_isUsingDummyCamera) {
      // 더미 이미지 대신 null 반환 (필요한 경우 호출자가 처리)
      return null;
    }

    // 웹 환경에서 카메라 사용 중일 때
    if (_isWeb && _controller != null && _controller!.value.isInitialized) {
      try {
        // 사진 찍기
        final XFile photo = await _controller!.takePicture();

        // 사진 데이터 읽기
        final Uint8List imageData = await photo.readAsBytes();
        _lastCapturedImageData = imageData;

        // 데이터 리사이징 및 압축
        final Uint8List resizedData =
            CameraUtils.resizeImage(imageData, 640, 480);
        final Uint8List compressedData =
            CameraUtils.compressImage(resizedData, 70);

        return compressedData;
      } catch (e) {
        print('웹 카메라 프레임 캡처 오류: $e');
        return null;
      }
    }

    // 네이티브 환경에서 실제 카메라 사용 중일 때
    if (!_isUsingDummyCamera && _lastCapturedImage != null) {
      try {
        // 카메라 이미지를 JPEG로 변환
        final Uint8List jpegData =
            await CameraUtils.convertCameraImageToJpeg(_lastCapturedImage!);

        // 전송할 크기로 조정 및 압축 (대역폭 절약을 위해)
        final Uint8List resizedData =
            CameraUtils.resizeImage(jpegData, 640, 480);
        final Uint8List compressedData =
            CameraUtils.compressImage(resizedData, 70);

        return compressedData;
      } catch (e) {
        print('프레임 캡처 오류: $e');
        return null;
      }
    }

    return null;
  }

  /// 카메라 스트리밍 시작
  Future<void> startCamera() async {
    if (_isUsingDummyCamera) {
      // 더미 카메라는 아무것도 하지 않음
      return;
    }

    if (!_isInitialized || _controller == null) {
      print('카메라가 초기화되지 않았습니다.');
      return;
    }

    if (!_controller!.value.isStreamingImages) {
      await startImageStream();
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

    await stopImageStream();
    await _controller?.dispose();

    if (_isWeb) {
      await _initializeWebCamera(_cameras![newIndex]);
    } else {
      await _initializeCamera(_cameras![newIndex]);
    }
  }

  /// 이미지 스트림 시작
  Future<void> startImageStream() async {
    if (_isUsingDummyCamera) {
      // 더미 카메라는 아무것도 하지 않음
      return;
    }

    if (_controller == null || !_isInitialized) {
      print('카메라가 초기화되지 않았습니다.');
      return;
    }

    try {
      if (!_controller!.value.isStreamingImages) {
        await _controller!.startImageStream((CameraImage image) {
          if (!_cameraImageStreamController.isClosed) {
            _cameraImageStreamController.add(image);
            _lastCapturedImage = image; // 마지막 이미지 저장
          }
        });
      }
    } catch (e) {
      print('이미지 스트림 시작 오류: $e');
    }
  }

  /// 이미지 스트림 정지
  Future<void> stopImageStream() async {
    if (_isUsingDummyCamera) {
      // 더미 카메라에서는 아무것도 하지 않음
      return;
    }

    if (_controller == null || !_isInitialized) {
      return;
    }

    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      print('이미지 스트림 정지 오류: $e');
    }
  }

  /// 카메라 서비스 해제
  Future<void> dispose() async {
    try {
      if (!_isUsingDummyCamera && _controller != null) {
        await stopImageStream();
        await _controller!.dispose();
      }
      _cameraImageStreamController.close();
    } catch (e) {
      print('카메라 서비스 해제 오류: $e');
    }
  }
}
