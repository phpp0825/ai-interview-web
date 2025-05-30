import 'package:flutter/material.dart';

/// 인터뷰 컨트롤 바 위젯
class InterviewControlBar extends StatelessWidget {
  final bool isInterviewStarted;
  final bool isUploadingVideo;
  final bool hasSelectedResume;
  final VoidCallback onStartInterview;
  final VoidCallback onStopInterview;
  final VoidCallback? onNextVideo;

  const InterviewControlBar({
    Key? key,
    required this.isInterviewStarted,
    this.isUploadingVideo = false,
    required this.hasSelectedResume,
    required this.onStartInterview,
    required this.onStopInterview,
    this.onNextVideo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: _buildMainButton(),
    );
  }

  /// 메인 버튼 (면접 시작/종료)
  Widget _buildMainButton() {
    // 업로드 중일 때는 진행 상태 표시
    if (isUploadingVideo) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            '🤖 AI가 면접 데이터를 분석하고 클라우드에 저장하고 있습니다...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      );
    }

    // 면접 진행 중일 때는 다음 영상/종료 버튼
    if (isInterviewStarted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 다음 영상 버튼
          if (onNextVideo != null)
            ElevatedButton.icon(
              onPressed: onNextVideo,
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('다음 질문'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

          // 면접 종료 버튼
          ElevatedButton.icon(
            onPressed: onStopInterview,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('면접 종료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      );
    }

    // 면접 시작 버튼
    return ElevatedButton.icon(
      onPressed: hasSelectedResume ? onStartInterview : null,
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(
        hasSelectedResume ? '🎬 면접 시작' : '📋 이력서를 먼저 선택하세요',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            hasSelectedResume ? Colors.green.shade100 : Colors.grey.shade200,
        foregroundColor:
            hasSelectedResume ? Colors.green.shade700 : Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(250, 48),
      ),
    );
  }
}
