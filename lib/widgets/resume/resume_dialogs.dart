import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../../views/interview_view.dart';
import '../../views/report_view.dart';

/// 이력서 화면에서 사용되는 다이얼로그 모음
class ResumeDialogs {
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
    try {
      // 컨트롤러에게 저장 요청
      final bool success = await controller.submitForm();

      if (success) {
        // 저장 성공 시 면접 시작 안내 다이얼로그
        showInterviewStartDialog(context, controller);
      } else {
        // 저장 실패 시 스낵바 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이력서 제출에 실패했습니다.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 스낵바 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 면접 시작 다이얼로그
  static void showInterviewStartDialog(
      BuildContext context, ResumeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.videocam,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              const Text('면접 시작하기'),
            ],
          ),
          content: const Text(
            '이력서 정보가 성공적으로 저장되었습니다. 지금 면접을 시작하시겠습니까?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // 리포트 생성 버튼 추가
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showCreateReportDialog(context, controller);
              },
              icon: const Icon(Icons.assessment),
              label: const Text('리포트 생성'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // 면접 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InterviewView(
                        resumeData: controller.getCurrentResume()),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('면접 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: const BorderSide(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 리포트 생성 다이얼로그
  static void showCreateReportDialog(
      BuildContext context, ResumeController controller) {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 클릭으로 닫기 불가능
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.blue),
              const SizedBox(width: 10),
              const Text('리포트 생성'),
            ],
          ),
          content: const Text(
            '이력서 정보를 바탕으로 모의 면접 리포트를 생성하시겠습니까?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('생성하기'),
              onPressed: () {
                Navigator.of(context).pop();
                createReport(context, controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 리포트 생성 - 컨트롤러에 위임
  static Future<void> createReport(
      BuildContext context, ResumeController controller) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('리포트를 생성 중입니다...'),
          ],
        ),
      ),
    );

    try {
      // 컨트롤러를 통해 리포트 생성 요청
      final String? reportId = await controller.createReportWithResume();

      // 로딩 다이얼로그 닫기
      if (context.mounted) Navigator.of(context).pop();

      if (reportId != null && context.mounted) {
        // 성공 시 생성 완료 다이얼로그 표시
        showReportCreatedDialog(context, reportId);
      } else if (context.mounted) {
        // 실패 시 오류 다이얼로그 표시
        showErrorDialog(context, '리포트 생성에 실패했습니다.');
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) Navigator.of(context).pop();

      // 오류 다이얼로그 표시
      if (context.mounted) {
        showErrorDialog(context, '오류가 발생했습니다: $e');
      }
    }
  }

  /// 리포트 생성 완료 다이얼로그
  static void showReportCreatedDialog(BuildContext context, String reportId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              const Text('리포트 생성 완료'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '모의 면접 리포트가 성공적으로 생성되었습니다.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '리포트 ID: $reportId',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('리포트 보기'),
              onPressed: () {
                Navigator.of(context).pop();
                // 리포트 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportView(reportId: reportId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 오류 다이얼로그
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 10),
              const Text('오류'),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
