import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';
import 'question_timeline_section.dart';

/// 통합 타임라인 섹션 위젯
/// 질문 데이터가 있으면 질문 타임라인을 표시합니다
class TimelineSection extends StatelessWidget {
  final ReportController controller;
  final ReportModel reportData;

  const TimelineSection({
    Key? key,
    required this.controller,
    required this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 질문-답변 데이터가 있는 경우만 질문 타임라인 사용
    if (reportData.questionAnswers != null &&
        reportData.questionAnswers!.isNotEmpty) {
      return QuestionTimelineSection(
        controller: controller,
        reportData: reportData,
      );
    } else {
      // 질문 데이터가 없으면 빈 위젯 반환
      return const SizedBox.shrink();
    }
  }
}
