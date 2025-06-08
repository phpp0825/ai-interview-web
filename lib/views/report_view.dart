import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/report_controller.dart';
import '../models/report_model.dart';

import '../widgets/report/timeline_section.dart';
import '../widgets/report/report_header_section.dart';

/// 면접 보고서 화면
/// 면접 결과를 차트와 영상으로 분석해서 보여줍니다
class ReportView extends StatelessWidget {
  final String? reportId;

  const ReportView({Key? key, this.reportId = 'sample-report-1'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportController(),
      child: _ReportViewContent(reportId: reportId),
    );
  }
}

class _ReportViewContent extends StatefulWidget {
  final String? reportId;

  const _ReportViewContent({Key? key, this.reportId}) : super(key: key);

  @override
  State<_ReportViewContent> createState() => _ReportViewContentState();
}

class _ReportViewContentState extends State<_ReportViewContent> {
  @override
  void initState() {
    super.initState();
    // 보고서 데이터 로드
    Future.microtask(() {
      context
          .read<ReportController>()
          .loadReport(widget.reportId ?? 'sample-report-1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReportController>(context);

    // 로딩 중
    if (controller.isLoading) {
      return _buildLoadingScreen();
    }

    // 오류 발생
    if (controller.error != null) {
      return _buildErrorScreen(controller);
    }

    // 데이터 없음
    if (controller.reportData == null) {
      return _buildNoDataScreen();
    }

    // 정상 화면
    return _buildReportScreen(controller, controller.reportData!);
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('면접 보고서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 오류 화면
  Widget _buildErrorScreen(ReportController controller) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('면접 보고서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error ?? '알 수 없는 오류가 발생했습니다',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<ReportController>()
                    .loadReport(widget.reportId ?? 'sample-report-1');
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 데이터 없음 화면
  Widget _buildNoDataScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('면접 보고서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('데이터를 찾을 수 없습니다'),
      ),
    );
  }

  /// 메인 보고서 화면
  Widget _buildReportScreen(
      ReportController controller, ReportModel reportData) {
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
