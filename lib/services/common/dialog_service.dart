import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resume_model.dart';

/// 애플리케이션에서 사용되는 대화상자(다이얼로그) 표시 기능을 담당하는 서비스
class DialogService {
  /// 이력서 없음 알림 대화상자 표시
  void showNoResumeDialog(BuildContext context, Function navigateToResumeView) {
    showDialog(
      context: context,
      barrierDismissible: true, // 외부 클릭으로 닫기 허용
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('이력서 정보 필요'),
          content:
              const Text('AI 면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서 작성 페이지로 이동합니다.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToResumeView();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('이력서 작성하기'),
            ),
          ],
        );
      },
    );
  }

  /// 이력서 선택 대화상자 표시
  void showResumeSelectionDialog({
    required BuildContext context,
    required Function navigateToResumeView,
    required List<Map<String, dynamic>> resumeList,
    required bool isLoading,
    required Function(String) onResumeSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true, // 외부 클릭으로 닫기 허용
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.description, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text('이력서 선택 (필수)'),
            ],
          ),
          content: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: resumeList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '저장된 이력서가 없습니다.\n새 이력서를 작성해주세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: resumeList.length,
                          itemBuilder: (context, index) {
                            final resume = resumeList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  resume['position'] ?? '직무 정보 없음',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(resume['field'] ?? '분야 정보 없음'),
                                    Text('경력: ${resume['experience'] ?? '신입'}'),
                                  ],
                                ),
                                trailing: resume['createdAt'] != null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            formatDate(resume['createdAt']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios,
                                              size: 14),
                                        ],
                                      )
                                    : const Icon(Icons.arrow_forward_ios,
                                        size: 14),
                                onTap: () async {
                                  // 로딩 표시
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    // 이력서 선택 처리
                                    await onResumeSelected(resume['id']);

                                    // 로딩 다이얼로그 닫기
                                    Navigator.of(context).pop();

                                    // 이력서 선택 다이얼로그 닫기
                                    Navigator.of(context).pop();

                                    // 선택 완료 알림 표시
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${resume['position']} 이력서가 선택되었습니다.'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    // 오류 발생 시
                                    Navigator.of(context).pop(); // 로딩 닫기
                                    Navigator.of(context).pop(); // 다이얼로그 닫기

                                    // 오류 메시지 표시
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('이력서 선택 중 오류가 발생했습니다: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToResumeView();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('새 이력서 작성'),
            ),
          ],
        );
      },
    );
  }

  /// 날짜 포맷팅 유틸리티 함수
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return '날짜 정보 없음';

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        // Firestore 타임스탬프 변환
        date = (timestamp as Timestamp).toDate();
      }

      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 정보 오류';
    }
  }

  /// 도움말 다이얼로그 표시
  void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // 외부 클릭으로 닫기 허용
      builder: (context) => AlertDialog(
        title: const Text('AI 면접 도움말'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('이 화면에서는 Python AI 서버를 통해 실제 면접과 유사한 면접 시뮬레이션을 진행할 수 있습니다.'),
            SizedBox(height: 8),
            Text('1. 면접 전 반드시 이력서를 선택해야 합니다.'),
            Text('2. 이력서 정보는 AI에게 전달되어 이에 맞는 맞춤형 질문이 생성됩니다.'),
            Text('3. 서버에 연결하고 면접 시작 버튼을 눌러 면접을 시작하세요.'),
            Text('4. 화면 상단의 질문 목록을 펼쳐 면접 질문들을 확인할 수 있습니다.'),
            Text('5. 면접이 끝나면 면접 종료 버튼을 눌러 분석 결과를 확인하세요.'),
            SizedBox(height: 8),
            Text('주의: 카메라와 마이크 접근 권한이 필요합니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
