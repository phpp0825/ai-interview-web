import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// 카메라 관련 유틸리티 함수들
class CameraUtils {
  /// YUV420 형식의 CameraImage를 Uint8List(JPEG)로 변환
  static Future<Uint8List> convertCameraImageToJpeg(CameraImage image) async {
    try {
      // 웹 환경에서는 이미 JPEG 형식으로 제공될 수 있음
      if (kIsWeb) {
        // 웹 환경에서는 일반적으로 플레인 데이터가 이미 JPEG 형식
        return image.planes[0].bytes;
      } else {
        // 네이티브 환경에서는 YUV420 -> JPEG 변환 필요
        // 실제 프로덕션에서는 더 복잡한 변환 로직 필요

        // 첫 번째 plane의 데이터 사용 (간소화된 예제)
        // 참고: 실제로는 YUV -> RGB -> JPEG 변환 필요
        final Uint8List bytes = image.planes[0].bytes;
        return bytes;
      }
    } catch (e) {
      print('카메라 이미지 변환 오류: $e');
      // 오류 발생 시 빈 데이터 반환
      return Uint8List(0);
    }
  }

  /// 이미지 크기 조정 (간소화 버전)
  static Uint8List resizeImage(
      Uint8List imageData, int targetWidth, int targetHeight) {
    // 실제 구현에서는 이미지 라이브러리를 사용한 리사이징 필요
    // 여기서는 간단한 다운샘플링만 수행

    // 이미지가 너무 작으면 그대로 반환
    if (imageData.length < 1024) {
      return imageData;
    }

    // 웹 환경에서는 이미지 크기를 줄이지 않고 그대로 반환
    // 실제 구현에서는 HTML5 Canvas나 이미지 처리 라이브러리 사용 권장
    if (kIsWeb) {
      return _reduceSizeForWeb(imageData);
    }

    // 간단한 다운샘플링 (모든 이미지 형식에 적용되지는 않음)
    // 실제 구현에서는 image 패키지 등의 라이브러리 사용 권장
    return imageData;
  }

  /// 웹 환경에서 간단히 데이터 크기 줄이기 (실제 이미지 리사이징은 아님)
  static Uint8List _reduceSizeForWeb(Uint8List imageData) {
    // 실제 구현에서는 HTML5 Canvas 등을 사용하여 이미지 리사이징
    // 여기서는 간단히 이미지 크기만 줄임

    // 웹캠 이미지가 너무 크면 샘플링하여 크기 줄이기
    if (imageData.length > 100 * 1024) {
      // 100KB 이상이면
      // 절반 크기로 간단히 샘플링 (실제로는 적절한 리사이징 알고리즘 필요)
      final result = Uint8List((imageData.length / 2).ceil());
      for (int i = 0; i < result.length; i++) {
        result[i] = imageData[i * 2];
      }
      return result;
    }

    return imageData;
  }

  /// 이미지 품질 압축 (간소화 버전)
  static Uint8List compressImage(Uint8List imageData, int quality) {
    // 실제 구현에서는 이미지 압축 라이브러리 사용 필요
    // 웹 환경에서는 이미지 품질을 낮추는 기능 구현 필요

    // 이미지가 이미 작으면 그대로 반환
    if (imageData.length < 50 * 1024) {
      // 50KB 미만이면 압축 안 함
      return imageData;
    }

    // 간단한 데이터 줄이기 (실제 압축이 아님)
    // 데이터 크기에 따라 샘플링 비율 조정
    final int maxSize = 100 * 1024; // 최대 100KB 목표
    if (imageData.length > maxSize) {
      final double ratio = maxSize / imageData.length;
      final int step = (1 / ratio).ceil();

      // 스텝 단위로 샘플링하여 크기 줄이기
      final result = Uint8List((imageData.length / step).ceil());
      for (int i = 0; i < result.length; i++) {
        final srcIdx = math.min(i * step, imageData.length - 1);
        result[i] = imageData[srcIdx];
      }
      return result;
    }

    return imageData;
  }
}
