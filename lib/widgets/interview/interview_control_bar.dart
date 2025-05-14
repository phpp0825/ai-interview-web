import 'package:flutter/material.dart';

/// 인터뷰 컨트롤 바 위젯
class InterviewControlBar extends StatelessWidget {
  final bool isInterviewStarted;
  final VoidCallback onStartInterview;
  final VoidCallback onStopInterview;

  const InterviewControlBar({
    Key? key,
    required this.isInterviewStarted,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 면접 시작/종료 버튼
          ElevatedButton.icon(
            onPressed: isInterviewStarted ? onStopInterview : onStartInterview,
            icon: Icon(
              isInterviewStarted ? Icons.stop : Icons.play_arrow,
              size: 18,
            ),
            label: Text(
              isInterviewStarted ? '면접 종료' : '면접 시작',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isInterviewStarted
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              foregroundColor: isInterviewStarted
                  ? Colors.red.shade700
                  : Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
