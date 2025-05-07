import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import '../../views/resume_view.dart';
import '../../views/interview_view.dart';
import '../../views/report_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      // 테마 색상들
      final primaryColor = Theme.of(context).colorScheme.primary;
      final secondaryColor = Colors.deepPurple.shade300; // 다시 보라색으로 변경

      // Stack을 사용하여 전체 화면에 흰색 배경을 덮습니다
      return Stack(
        children: [
          // 배경 레이어 - 화면 전체를 흰색으로 칠합니다
          Positioned.fill(child: Container(color: Colors.white)),

          // 콘텐츠 레이어
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '면접 준비 대시보드',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 이력서 작성 카드
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildResumeCard(context, primaryColor),
                        ),

                        // 면접 연습 카드
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildInterviewCard(context, secondaryColor),
                        ),

                        // 면접 보고서 카드
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildReportCard(
                            context,
                            Colors.deepPurple.shade500,
                          ), // 다시 보라색으로 변경
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      // 오류 발생 시 기본 화면 표시
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('대시보드 로딩 중 오류가 발생했습니다: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardView()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: BorderSide(color: Colors.deepPurple),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
  }

  // 이력서 카드 생성
  Widget _buildResumeCard(BuildContext context, Color color) {
    return DashboardCard(
      title: '이력서 작성',
      icon: Icons.description,
      color: color,
      description: '당신의 경력, 기술, 학력을 정리하여 효과적인 이력서를 작성하세요.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResumeView()),
        );
      },
    );
  }

  // 면접 카드 생성
  Widget _buildInterviewCard(BuildContext context, Color color) {
    return DashboardCard(
      title: '면접 연습',
      icon: Icons.record_voice_over,
      color: color,
      description: 'AI와 모의 면접을 통해 실제 면접 상황에 대비하세요.',
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('면접 시작하기'),
              content: const Text('면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서를 작성하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InterviewView(),
                      ),
                    );
                  },
                  child: const Text('이력서 없이 진행'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResumeView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    elevation: 1,
                    side: BorderSide(color: Colors.deepPurple),
                  ),
                  child: const Text('이력서 작성하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 보고서 카드 생성
  Widget _buildReportCard(BuildContext context, Color color) {
    return DashboardCard(
      title: '면접 보고서',
      icon: Icons.assessment,
      color: color,
      description: '과거 면접 결과를 분석하고 개선점을 확인하세요.',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportView()),
        );
      },
    );
  }
}
