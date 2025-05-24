import 'package:flutter/material.dart';

/// 인터뷰 컨트롤 바 위젯
class InterviewControlBar extends StatelessWidget {
  final bool isConnected;
  final bool isInterviewStarted;
  final bool isUploadingVideo;
  final bool hasQuestions;
  final bool hasSelectedResume;
  final VoidCallback onConnectToServer;
  final VoidCallback onGenerateQuestions;
  final VoidCallback onStartInterview;
  final VoidCallback onStopInterview;

  const InterviewControlBar({
    Key? key,
    required this.isConnected,
    required this.isInterviewStarted,
    this.isUploadingVideo = false,
    required this.hasQuestions,
    required this.hasSelectedResume,
    required this.onConnectToServer,
    required this.onGenerateQuestions,
    required this.onStartInterview,
    required this.onStopInterview,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 단계별 버튼들
          _buildStepButtons(),
          const SizedBox(height: 12),
          // 하단: 면접 시작/종료 또는 업로드 상태
          _buildMainButton(),
        ],
      ),
    );
  }

  /// 단계별 버튼들
  Widget _buildStepButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1단계: 서버 연결
        _buildStepButton(
          icon: isConnected ? Icons.link : Icons.link_off,
          label: isConnected ? '서버 연결됨' : '서버 연결',
          isCompleted: isConnected,
          isEnabled: !isInterviewStarted,
          onPressed: isConnected ? null : onConnectToServer,
        ),

        // 2단계: 질문 생성
        _buildStepButton(
          icon: hasQuestions ? Icons.check_circle : Icons.quiz,
          label: hasQuestions ? '질문 생성됨' : '질문 생성',
          isCompleted: hasQuestions,
          isEnabled: !isInterviewStarted && isConnected && hasSelectedResume,
          onPressed: hasQuestions ? null : onGenerateQuestions,
        ),

        // 3단계: 면접 준비 완료
        _buildStepButton(
          icon:
              hasQuestions && isConnected ? Icons.check_circle : Icons.pending,
          label: '면접 준비',
          isCompleted: hasQuestions && isConnected,
          isEnabled: false,
          onPressed: null,
        ),
      ],
    );
  }

  /// 단계별 버튼 위젯
  Widget _buildStepButton({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isEnabled,
    required VoidCallback? onPressed,
  }) {
    final color =
        isCompleted ? Colors.green : (isEnabled ? Colors.blue : Colors.grey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted
                ? Colors.green.shade100
                : (isEnabled ? Colors.blue.shade100 : Colors.grey.shade200),
            foregroundColor: color,
            minimumSize: const Size(60, 60),
            shape: const CircleBorder(),
            elevation: isCompleted ? 2 : 0,
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
            '비디오 업로드 중...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      );
    }

    // 면접 시작/종료 버튼
    final canStartInterview = isConnected && hasQuestions && hasSelectedResume;

    return ElevatedButton.icon(
      onPressed: isInterviewStarted
          ? onStopInterview
          : (canStartInterview ? onStartInterview : null),
      icon: Icon(
        isInterviewStarted ? Icons.stop : Icons.play_arrow,
        size: 18,
      ),
      label: Text(
        isInterviewStarted ? '면접 종료' : '면접 시작',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isInterviewStarted
            ? Colors.red.shade100
            : (canStartInterview
                ? Colors.green.shade100
                : Colors.grey.shade200),
        foregroundColor: isInterviewStarted
            ? Colors.red.shade700
            : (canStartInterview
                ? Colors.green.shade700
                : Colors.grey.shade500),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(200, 48),
      ),
    );
  }
}
