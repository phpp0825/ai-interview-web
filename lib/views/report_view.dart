import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/report_controller.dart';
import '../widgets/report/speech_speed_chart.dart';
import '../widgets/report/timestamp_section.dart';
import '../widgets/report/video_player_section.dart';
import '../widgets/report/gaze_analysis_chart.dart';
import '../widgets/report/feedback_section.dart';

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
    // 컨트롤러 데이터 로드
    Future.microtask(() {
      context
          .read<ReportController>()
          .loadReport(widget.reportId ?? 'sample-report-1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReportController>(context);

    // 로딩 중 상태
    if (controller.isLoading) {
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

    // 에러 상태
    if (controller.error != null) {
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

    // 데이터가 없는 경우
    if (controller.reportData == null) {
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

    // 데이터가 로드된 정상 상태
    final reportData = controller.reportData!;

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
                // 면접 보고서 제목 및 요약 정보
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportData.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${reportData.position} | ${reportData.field} | ${reportData.interviewType}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 비디오 플레이어
                controller.isVideoInitialized
                    ? VideoPlayerSection(
                        videoUrl: reportData.videoUrl,
                        externalController: controller.videoPlayerController!,
                      )
                    : const SizedBox(
                        height: 400,
                        child: Center(child: CircularProgressIndicator()),
                      ),

                const SizedBox(height: 16),

                // 타임스탬프 영역
                TimestampSection(
                  timestamps: reportData.timestamps
                      .map((t) => {
                            'time': t.time,
                            'label': t.label,
                            'description': t.description,
                          })
                      .toList(),
                  onTimeTapped: controller.seekToTime,
                  formatDuration: controller.formatDuration,
                ),

                const SizedBox(height: 32),

                // 말하기 속도 차트
                SpeechSpeedChart(
                  speechData: reportData.speechSpeedData,
                  formatDuration: controller.formatDuration,
                ),

                const SizedBox(height: 32),

                // 시선 처리 분석 차트
                GazeAnalysisChart(
                  gazeData: reportData.gazeData,
                  formatDuration: controller.formatDuration,
                ),

                const SizedBox(height: 24),

                // 전체적인 면접 피드백
                const FeedbackSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
