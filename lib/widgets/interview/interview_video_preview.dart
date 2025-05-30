import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../services/common/video_recording_service.dart';

/// 인터뷰 비디오 미리보기 위젯
class InterviewVideoPreview extends StatelessWidget {
  final VideoRecordingService cameraService;
  final bool isInterviewStarted;
  final VoidCallback onStartInterview;

  const InterviewVideoPreview({
    Key? key,
    required this.cameraService,
    required this.isInterviewStarted,
    required this.onStartInterview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: _buildCameraPreview(),
      ),
    );
  }

  /// 카메라 미리보기 위젯 생성
  Widget _buildCameraPreview() {
    // 카메라가 초기화되지 않았거나 컨트롤러가 없는 경우
    if (!cameraService.isInitialized) {
      return _buildLoadingView();
    }

    // 더미 카메라를 사용 중인 경우
    if (cameraService.isUsingDummyCamera) {
      return _buildNoCameraView();
    }

    // 컨트롤러가 없는 경우 (초기화는 됐지만 컨트롤러가 생성되지 않음)
    if (cameraService.controller == null) {
      return _buildErrorView("카메라 컨트롤러를 찾을 수 없습니다");
    }

    // 실제 카메라 미리보기 (꽉 차게 표시)
    return _buildCameraPreviewWidget();
  }

  /// 카메라 로딩 화면
  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              '카메라를 초기화하는 중...',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 표시 화면
  Widget _buildErrorView(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              onPressed: () {
                cameraService.initialize();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 카메라 없음 화면
  Widget _buildNoCameraView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              '카메라를 사용할 수 없습니다',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade100.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: const Column(
                children: [
                  Text(
                    '🚫 카메라 권한이 필요합니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. 브라우저 주소창 옆의 카메라 아이콘을 클릭\n2. 카메라 권한을 허용으로 변경\n3. 페이지 새로고침 또는 아래 버튼 클릭',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('카메라 다시 시도'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    print('🔄 카메라 재초기화 시도...');
                    await cameraService.initialize();
                  },
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: isInterviewStarted ? null : onStartInterview,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('카메라 없이 계속'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '⚠️ 카메라 없이 진행하면 영상이 녹화되지 않습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 실제 카메라 미리보기 위젯 (꽉 차게 표시)
  Widget _buildCameraPreviewWidget() {
    try {
      if (kIsWeb) {
        // 웹에서는 전체 화면에 꽉 차게 표시
        return Container(
          color: Colors.black,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 컨테이너 크기에 맞게 비율 계산
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                // 화면에 꽉 차도록 FittedBox 사용
                return FittedBox(
                  fit: BoxFit.cover, // 화면을 꽉 채우도록 설정
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: CameraPreview(cameraService.controller!),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // 모바일에서도 화면에 꽉 차게 표시
        return Container(
          color: Colors.black,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: CameraPreview(cameraService.controller!),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('카메라 미리보기 위젯 생성 오류: $e');
      // 오류 발생 시 대체 화면 표시
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            '카메라 미리보기를 표시할 수 없습니다',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
