import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'video_recording_service.dart';

/// 이미지 캡처 관련 기능을 관리하는 서비스
/// 카메라에서 이미지 캡처, 압축, 스트리밍 관련 기능을 처리합니다.
class ImageCaptureService {
  // 의존성
  final VideoRecordingService _videoRecordingService;

  // 이미지 스트림 관련 변수
  final StreamController<CameraImage> _cameraImageStreamController =
      StreamController<CameraImage>.broadcast();

  // 마지막으로 캡처된 이미지 저장
  CameraImage? _lastCapturedImage;
  Uint8List? _lastCapturedImageData;

  // 스트리밍 상태
  bool _isImageStreamActive = false;

  // 외부에서 접근할 수 있는 스트림 getter
  Stream<CameraImage> get cameraImageStream =>
      _cameraImageStreamController.stream;

  // 초기화 여부 및 더미 모드 확인 (VideoRecordingService에서 위임)
  bool get isInitialized => _videoRecordingService.isInitialized;
  bool get isUsingDummyCamera => _videoRecordingService.isUsingDummyCamera;

  // 생성자
  ImageCaptureService(this._videoRecordingService);

  /// 이미지 스트림 시작
  Future<void> startImageStream() async {
    // 더미 카메라이거나 초기화되지 않은 경우 처리
    if (isUsingDummyCamera || !isInitialized) {
      return;
    }

    // 컨트롤러 가져오기
    final controller = _videoRecordingService.controller;
    if (controller == null) {
      print('카메라 컨트롤러가 초기화되지 않았습니다.');
      return;
    }

    try {
      if (!controller.value.isStreamingImages) {
        await controller.startImageStream((CameraImage image) {
          if (!_cameraImageStreamController.isClosed) {
            _cameraImageStreamController.add(image);
            _lastCapturedImage = image;
          }
        });
        _isImageStreamActive = true;
        print('이미지 스트림 시작됨');
      }
    } catch (e) {
      print('이미지 스트림 시작 오류: $e');
    }
  }

  /// 이미지 스트림 정지
  Future<void> stopImageStream() async {
    if (!_isImageStreamActive) {
      return;
    }

    final controller = _videoRecordingService.controller;
    if (controller == null) {
      return;
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        _isImageStreamActive = false;
        print('이미지 스트림 정지됨');
      }
    } catch (e) {
      print('이미지 스트림 정지 오류: $e');
    }
  }

  /// 현재 비디오 프레임을 JPEG 형식으로 캡처
  Future<Uint8List?> captureFrame() async {
    // 더미 카메라 사용 중일 때
    if (isUsingDummyCamera) {
      return null;
    }

    final controller = _videoRecordingService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    // 웹 환경에서 카메라 사용 중일 때
    if (kIsWeb) {
      try {
        // 사진 찍기
        final XFile photo = await controller.takePicture();

        // 사진 데이터 읽기
        final Uint8List imageData = await photo.readAsBytes();
        _lastCapturedImageData = imageData;

        // 간단한 크기 제한 (100KB 이상일 경우)
        if (imageData.length > 100 * 1024) {
          return _simpleCompressImage(imageData);
        }

        return imageData;
      } catch (e) {
        print('웹 카메라 프레임 캡처 오류: $e');
        return null;
      }
    }

    // 네이티브 환경에서 실제 카메라 사용 중일 때
    if (_lastCapturedImage != null) {
      try {
        // 네이티브에서는 가장 기본적인 방법으로 이미지 데이터 사용
        final Uint8List jpegData = _lastCapturedImage!.planes[0].bytes;
        _lastCapturedImageData = jpegData;
        return jpegData;
      } catch (e) {
        print('프레임 캡처 오류: $e');
      }
    }

    return null;
  }

  /// 간단한 이미지 압축 (대역폭 절약용)
  Uint8List _simpleCompressImage(Uint8List imageData) {
    // 이미지가 이미 작으면 그대로 반환
    if (imageData.length < 100 * 1024) {
      return imageData;
    }

    // 100KB 넘는 경우 간단한 데이터 샘플링 (절반 크기로 줄임)
    final result = Uint8List((imageData.length / 2).ceil());
    for (int i = 0; i < result.length; i++) {
      result[i] =
          imageData[i * 2 >= imageData.length ? imageData.length - 1 : i * 2];
    }
    return result;
  }

  /// 리소스 해제
  void dispose() {
    stopImageStream();
    _cameraImageStreamController.close();
  }
}
