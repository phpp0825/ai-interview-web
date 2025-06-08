import 'package:flutter/material.dart';
import '../../models/report_model.dart';

/// 리포트 헤더 섹션 위젯
/// 면접 제목, 지원 직무, 분야 등 기본 정보를 표시합니다
class ReportHeaderSection extends StatelessWidget {
  final ReportModel reportData;

  const ReportHeaderSection({
    Key? key,
    required this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메인 제목
              Text(
                reportData.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 부제목 (직무, 분야, 면접 유형)
              Text(
                '${reportData.position} | ${reportData.field} | ${reportData.interviewType}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
