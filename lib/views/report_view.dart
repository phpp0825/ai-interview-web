import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/report_controller.dart';
import '../models/report_model.dart';
import '../widgets/report/report_loading_screen.dart';
import '../widgets/report/report_error_screen.dart';
import '../widgets/report/report_empty_screen.dart';
import '../widgets/report/report_main_screen.dart';

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
      return const ReportLoadingScreen();
    }

    // 오류 발생
    if (controller.error != null) {
      return ReportErrorScreen(
        controller: controller,
        reportId: widget.reportId,
      );
    }

    // 데이터 없음
    if (controller.reportData == null) {
      return const ReportEmptyScreen();
    }

    // 정상 화면
    return ReportMainScreen(
      controller: controller,
      reportData: controller.reportData!,
    );
  }
}
