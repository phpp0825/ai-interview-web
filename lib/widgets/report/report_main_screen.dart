import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';
import 'timeline_section.dart';
import 'report_header_section.dart';

/// 메인 리포트 화면 위젯
class ReportMainScreen extends StatelessWidget {
  final ReportController controller;
  final ReportModel reportData;

  const ReportMainScreen({
    Key? key,
    required this.controller,
    required this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(reportData.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (제목, 지원 정보)
                ReportHeaderSection(reportData: reportData),
                const SizedBox(height: 24),

                // 통합 타임라인 (질문별 영상 + 피드백)
                TimelineSection(
                  controller: controller,
                  reportData: reportData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
