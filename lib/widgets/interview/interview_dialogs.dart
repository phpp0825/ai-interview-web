import 'package:flutter/material.dart';

/// 면접 관련 다이얼로그들을 관리하는 클래스
class InterviewDialogs {
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
