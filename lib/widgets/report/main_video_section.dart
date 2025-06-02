import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';
import 'video_player_section.dart';

/// 메인 비디오 섹션 위젯
/// 현재 선택된 질문의 영상을 재생하는 섹션입니다
class MainVideoSection extends StatelessWidget {
  final ReportController controller;
  final ReportModel reportData;

  const MainVideoSection({
    Key? key,
    required this.controller,
    required this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        _buildCurrentQuestionInfo(
          currentQuestionTitle,
          currentQuestionText,
          hasVideoForCurrentQuestion,
        ),
        const SizedBox(height: 12),

        // 메인 비디오 플레이어
        _buildVideoPlayer(hasVideoForCurrentQuestion),
      ],
    );
  }

  /// 현재 질문 정보 표시
  Widget _buildCurrentQuestionInfo(
    String title,
    String text,
    bool hasVideo,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasVideo ? Colors.deepPurple.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasVideo ? Colors.deepPurple.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasVideo ? Icons.play_circle_filled : Icons.info_outline,
                size: 20,
                color: hasVideo
                    ? Colors.deepPurple.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                hasVideo ? '현재 재생: $title' : '영상 없음: $title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasVideo
                      ? Colors.deepPurple.shade700
                      : Colors.orange.shade700,
                ),
              ),
              if (hasVideo) ...[
                const Spacer(),
                _buildVideoAvailableBadge(),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 영상 있음 배지
  Widget _buildVideoAvailableBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }

  /// 비디오 플레이어 영역
  Widget _buildVideoPlayer(bool hasVideo) {
    return Container(
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
            : _buildEmptyVideoState(hasVideo),
      ),
    );
  }

  /// 영상이 없을 때의 상태
  Widget _buildEmptyVideoState(bool hasVideo) {
    return Container(
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
              hasVideo ? '영상을 로드하는 중입니다...' : '이 질문에는 답변 영상이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasVideo) ...[
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
    );
  }
}
