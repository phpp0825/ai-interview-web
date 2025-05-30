import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/report_controller.dart';
import '../models/report_model.dart';
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

                // 메인 비디오 플레이어
                _buildMainVideoSection(controller, reportData),

                const SizedBox(height: 16),

                // 질문별 타임라인
                _buildQuestionTimeline(controller, reportData),

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

  Widget _buildMainVideoSection(
      ReportController controller, ReportModel reportData) {
    // 현재 선택된 질문 정보 표시
    String currentQuestionTitle = '전체 면접 영상';
    String currentQuestionText = '면접 전체 내용';
    bool hasVideoForCurrentQuestion = false;

    if (reportData.questionAnswers != null &&
        reportData.questionAnswers!.isNotEmpty &&
        controller.selectedQuestionIndex < reportData.questionAnswers!.length) {
      final currentQuestion =
          reportData.questionAnswers![controller.selectedQuestionIndex];
      currentQuestionTitle = '질문 ${controller.selectedQuestionIndex + 1}';
      currentQuestionText = currentQuestion.question;
      hasVideoForCurrentQuestion = currentQuestion.videoUrl.isNotEmpty;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 현재 재생 중인 질문 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasVideoForCurrentQuestion
                ? Colors.deepPurple.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasVideoForCurrentQuestion
                  ? Colors.deepPurple.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasVideoForCurrentQuestion
                        ? Icons.play_circle_filled
                        : Icons.info_outline,
                    size: 20,
                    color: hasVideoForCurrentQuestion
                        ? Colors.deepPurple.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasVideoForCurrentQuestion
                        ? '현재 재생: $currentQuestionTitle'
                        : '영상 없음: $currentQuestionTitle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasVideoForCurrentQuestion
                          ? Colors.deepPurple.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  if (hasVideoForCurrentQuestion) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '영상 있음',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                currentQuestionText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 메인 비디오 플레이어
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: controller.currentVideoUrl.isNotEmpty
                ? VideoPlayerSection(
                    videoUrl: controller.currentVideoUrl,
                    key: ValueKey('main_${controller.currentVideoUrl}'),
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hasVideoForCurrentQuestion
                                ? '영상을 로드하는 중입니다...'
                                : '이 질문에는 답변 영상이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!hasVideoForCurrentQuestion) ...[
                            const SizedBox(height: 8),
                            Text(
                              '왼쪽 타임라인에서 영상이 있는 다른 질문을 선택해주세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTimeline(
      ReportController controller, ReportModel reportData) {
    // 질문-답변 데이터가 있는 경우 질문 선택 타임라인 생성
    if (reportData.questionAnswers != null &&
        reportData.questionAnswers!.isNotEmpty) {
      // 모든 질문을 순서대로 표시
      final allQuestions = reportData.questionAnswers!.asMap().entries.toList();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.playlist_play, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '면접 질문별 타임라인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '총 ${allQuestions.length}개 질문 | 클릭하여 해당 질문 확인',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 질문 목록
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allQuestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = allQuestions[index];
                final originalIndex = entry.key;
                final qa = entry.value;
                final isSelected =
                    controller.selectedQuestionIndex == originalIndex;
                final hasVideo = qa.videoUrl.isNotEmpty;

                return InkWell(
                  onTap: () {
                    print('🎯 질문 ${originalIndex + 1} 선택됨');
                    controller.selectQuestion(originalIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.deepPurple.shade50 : Colors.white,
                      border: isSelected
                          ? Border(
                              left: BorderSide(
                                color: Colors.deepPurple,
                                width: 4,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // 질문 번호 원형 배지
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple
                                : _getScoreColor(qa.score),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              '${originalIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 질문 내용
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '질문 ${originalIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.deepPurple.shade700
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  // 영상 상태 표시
                                  if (hasVideo) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.green.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.videocam,
                                            size: 12,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '영상',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // 점수 배지
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(qa.score)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _getScoreColor(qa.score),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${qa.score}점',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getScoreColor(qa.score),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 시간 배지 (영상이 있는 경우만)
                                  if (hasVideo) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _formatTime(qa.answerDuration),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                qa.question,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.deepPurple.shade600
                                      : Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // 아이콘
                        Icon(
                          hasVideo
                              ? (isSelected
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled)
                              : Icons.description,
                          color: isSelected
                              ? Colors.deepPurple
                              : (hasVideo
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      // 기존 타임스탬프 방식 (하위 호환성)
      return _buildLegacyTimestamps(controller, reportData);
    }
  }

  Widget _buildLegacyTimestamps(
      ReportController controller, ReportModel reportData) {
    // 기존 타임스탬프 방식 (하위 호환성)
    List<Map<String, dynamic>> questionTimestamps = reportData.timestamps
        .map((t) => {
              'time': t.time,
              'label': t.label,
              'description': t.description,
            })
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '면접 타임라인 (레거시)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '총 면접 시간: ${_formatTime(reportData.duration)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '클릭하여 해당 시간으로 이동',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questionTimestamps.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final timestamp = questionTimestamps[index];

              return InkWell(
                onTap: () {
                  print('🎯 시간으로 이동: ${timestamp['time']}초');
                  controller.seekToTime(timestamp['time']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatTime(timestamp['time']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timestamp['label'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timestamp['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.play_circle_filled,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
