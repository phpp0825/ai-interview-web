import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import 'dart:math';

/// 이력서 화면에서 사용되는 다이얼로그 모음
class ResumeDialogs {
  // 로딩 다이얼로그 컨텍스트를 추적하기 위한 키
  static BuildContext? _loadingDialogContext;
  // 원본 컨텍스트를 저장하기 위한 변수
  static BuildContext? _originalContext;
  // 성공 다이얼로그 표시 여부
  static bool _isSuccessDialogShowing = false;
  // 전역 네비게이터 키
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// 제출 다이얼로그 표시
  static void showSubmitDialog(
      BuildContext context, ResumeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              const Text(
                '입력 내용 확인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '다음 내용으로 제출하시겠습니까?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('지원 분야:', controller.field),
                _buildInfoRow('희망 직무:', controller.position),
                _buildInfoRow('경력 여부:', controller.experience),
                _buildInfoRow('면접 유형:', controller.interviewTypes.join(', ')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleSubmit(context, controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: const BorderSide(color: Colors.deepPurple),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 정보 행 위젯 빌더
  static Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// 제출 처리 - 컨트롤러에 위임
  static Future<void> handleSubmit(
      BuildContext context, ResumeController controller) async {
    print('=== handleSubmit 시작 ===');
    // 초기화
    _isSuccessDialogShowing = false;
    // 원본 컨텍스트 저장
    _originalContext = context;
    // 네비게이터 상태 저장
    final navigatorState = Navigator.of(context, rootNavigator: true);

    // 로딩 시작 시간 기록
    final startTime = DateTime.now();

    // 로딩 다이얼로그 표시
    showLoadingDialog(context);
    print('로딩 다이얼로그 표시됨');

    // 타임아웃 설정 - 10초 후에 자동으로 닫힘
    Future.delayed(const Duration(seconds: 10), () {
      if (_loadingDialogContext != null) {
        print('타임아웃으로 로딩 다이얼로그 닫힘');
        closeLoadingDialog();
      }
    });

    bool success = false;
    try {
      // 컨트롤러에게 저장 요청
      print('이력서 저장 시작');
      success = await controller.submitForm();
      print('이력서 저장 완료: success=$success');

      // 최소 로딩 시간 계산 (2초)
      final endTime = DateTime.now();
      final elapsedMs = endTime.difference(startTime).inMilliseconds;
      final remainingMs = max(0, 2000 - elapsedMs); // 최소 2초 보장

      if (remainingMs > 0) {
        // 남은 시간만큼 대기
        print('추가 대기 시간: $remainingMs ms');
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      // 로딩 다이얼로그 닫기
      print('로딩 다이얼로그 닫기 시도');
      closeLoadingDialog();
      print('로딩 다이얼로그 닫기 완료');

      // 성공 여부에 따른 처리
      if (success) {
        // 저장 성공 시 완료 다이얼로그 표시
        print('성공 다이얼로그 표시 준비');

        // 약간의 지연 후 다이얼로그 표시 (UI 업데이트 시간 고려)
        await Future.delayed(const Duration(milliseconds: 300));

        if (!_isSuccessDialogShowing) {
          print('성공 다이얼로그 표시 시도 - BuildContext 대신 NavigatorState 사용');
          _isSuccessDialogShowing = true;

          // 저장된 Navigator 상태를 통해 다이얼로그 표시
          try {
            _showSuccessDialogWithNavigator(navigatorState);
          } catch (e) {
            print('NavigatorState 접근 실패: $e');
            // 앱 전체를 다시 시작하거나 다른 복구 방법 시도
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        }
      } else if (!success && context.mounted) {
        // 저장 실패 시 스낵바 표시
        print('실패 스낵바 표시');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이력서 제출에 실패했습니다.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('이력서 제출 중 예외 발생: $e');

      // 최소 로딩 시간 계산 (2초)
      final endTime = DateTime.now();
      final elapsedMs = endTime.difference(startTime).inMilliseconds;
      final remainingMs = max(0, 2000 - elapsedMs); // 최소 2초 보장

      if (remainingMs > 0) {
        // 남은 시간만큼 대기
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      // 로딩 다이얼로그 닫기
      closeLoadingDialog();

      // 오류 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      print('=== handleSubmit 종료 ===');
    }
  }

  /// 네비게이터 상태를 사용하여 성공 다이얼로그 표시
  static void _showSuccessDialogWithNavigator(NavigatorState navigatorState) {
    print('NavigatorState를 사용하여 성공 다이얼로그 표시');
    navigatorState.push(
      DialogRoute(
        context: navigatorState.context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                const Text('완료'),
              ],
            ),
            content: const Text(
              '새 이력서가 성공적으로 생성되었습니다!',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 홈 화면으로 이동
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  elevation: 1,
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                child: const Text('확인'),
              ),
            ],
          );
        },
      ),
    );
    print('NavigatorState를 사용하여 성공 다이얼로그 표시 완료');
  }

  /// 로딩 다이얼로그 닫기
  static void closeLoadingDialog() {
    if (_loadingDialogContext != null) {
      try {
        Navigator.of(_loadingDialogContext!, rootNavigator: true).pop();
        print('로딩 다이얼로그 닫기 성공');
        _loadingDialogContext = null;
      } catch (e) {
        print('로딩 다이얼로그 닫기 실패: $e');
        _loadingDialogContext = null;
      }
    }
  }

  /// 로딩 다이얼로그 표시
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // 로딩 다이얼로그 컨텍스트 저장
        _loadingDialogContext = dialogContext;

        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const Text(
                '이력서를 저장 중입니다...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 성공 다이얼로그 표시 (더 이상 직접 사용하지 않음)
  static void showSuccessDialog(BuildContext context) {
    print('⚠️ 이 메서드는 더 이상 직접 사용하지 않습니다');
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                const Text('완료'),
              ],
            ),
            content: const Text(
              '새 이력서가 성공적으로 생성되었습니다!',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 홈 화면으로 이동
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  elevation: 1,
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      print('성공 다이얼로그 표시 성공');
    } catch (e) {
      print('성공 다이얼로그 표시 실패: $e');
      // 홈 화면으로 이동
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}
