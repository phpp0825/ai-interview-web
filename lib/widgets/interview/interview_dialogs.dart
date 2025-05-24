import 'package:flutter/material.dart';
import '../../views/resume_view.dart';

/// 면접 관련 다이얼로그들을 관리하는 클래스
class InterviewDialogs {
  /// 이력서 선택 다이얼로그 표시
  static void showResumeSelectionDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> resumeList,
    required Function(String) onResumeSelected,
    required VoidCallback onCreateResume,
  }) {
    if (resumeList.isEmpty) {
      showCreateResumeDialog(
        context: context,
        onCreateResume: onCreateResume,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('이력서 선택'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: resumeList.length,
            itemBuilder: (context, index) {
              final resume = resumeList[index];
              return ListTile(
                title: Text(resume['position'] ?? '직무 정보 없음'),
                subtitle: Text(resume['field'] ?? '분야 정보 없음'),
                onTap: () {
                  Navigator.pop(context);
                  onResumeSelected(resume['id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showCreateResumeDialog(
                context: context,
                onCreateResume: onCreateResume,
              );
            },
            child: const Text('새 이력서'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 이력서 작성 안내 다이얼로그
  static void showCreateResumeDialog({
    required BuildContext context,
    required VoidCallback onCreateResume,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이력서가 필요합니다'),
        content: const Text('면접을 시작하려면 이력서가 필요합니다. 이력서를 작성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumeView()),
              ).then((_) => onCreateResume());
            },
            child: const Text('이력서 작성'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그 표시
  static void showErrorDialog({
    required BuildContext context,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 확인 다이얼로그 표시
  static void showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시 유틸리티
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
}
