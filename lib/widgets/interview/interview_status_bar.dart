import 'package:flutter/material.dart';
import '../../models/resume_model.dart';

/// 인터뷰 상태 표시줄 위젯
class InterviewStatusBar extends StatelessWidget {
  final bool isConnected;
  final bool isInterviewStarted;
  final ResumeModel? selectedResume;

  const InterviewStatusBar({
    Key? key,
    required this.isConnected,
    required this.isInterviewStarted,
    this.selectedResume,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          // 연결 상태
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? '서버 연결됨' : '서버 연결 안됨',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),

          // 이력서 정보
          if (selectedResume != null) ...[
            const Icon(Icons.description, size: 16),
            const SizedBox(width: 4),
            Text(
              '이력서: ${selectedResume!.position}',
              style: const TextStyle(fontSize: 14),
            ),
          ],

          const Spacer(),

          // 인터뷰 상태
          if (isInterviewStarted)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '인터뷰 진행 중',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
