import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';

/// 질문별 타임라인 섹션 위젯
/// 각 질문을 클릭하여 해당 영상을 볼 수 있는 타임라인입니다
class QuestionTimelineSection extends StatelessWidget {
  final ReportController controller;
  final ReportModel reportData;

  const QuestionTimelineSection({
    Key? key,
    required this.controller,
    required this.reportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reportData.questionAnswers == null ||
        reportData.questionAnswers!.isEmpty) {
      return const SizedBox.shrink();
    }

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
          _buildHeader(allQuestions.length),
          const Divider(height: 1),

          // 질문 목록
          _buildQuestionList(allQuestions),
        ],
      ),
    );
  }

  /// 헤더 영역
  Widget _buildHeader(int questionCount) {
    return Padding(
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
                '총 $questionCount개 질문 | 클릭하여 해당 질문 확인',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 질문 목록
  Widget _buildQuestionList(List<MapEntry<int, dynamic>> allQuestions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allQuestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = allQuestions[index];
        final originalIndex = entry.key;
        final qa = entry.value;
        final isSelected = controller.selectedQuestionIndex == originalIndex;
        final hasVideo = qa.videoUrl.isNotEmpty;

        return _buildQuestionItem(
          originalIndex,
          qa,
          isSelected,
          hasVideo,
        );
      },
    );
  }

  /// 개별 질문 아이템
  Widget _buildQuestionItem(
    int originalIndex,
    dynamic qa,
    bool isSelected,
    bool hasVideo,
  ) {
    return InkWell(
      onTap: () {
        print('🎯 질문 ${originalIndex + 1} 선택됨');
        controller.selectQuestion(originalIndex);
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
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
            _buildQuestionBadge(originalIndex, qa.score, isSelected),
            const SizedBox(width: 16),

            // 질문 내용
            _buildQuestionContent(originalIndex, qa, isSelected, hasVideo),

            // 아이콘
            _buildQuestionIcon(hasVideo, isSelected),
          ],
        ),
      ),
    );
  }

  /// 질문 번호 배지
  Widget _buildQuestionBadge(int index, int score, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple : _getScoreColor(score),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// 질문 내용 영역
  Widget _buildQuestionContent(
    int index,
    dynamic qa,
    bool isSelected,
    bool hasVideo,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '질문 ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? Colors.deepPurple.shade700 : Colors.black,
                  ),
                ),
              ),
              // 영상 상태 표시
              if (hasVideo) ...[
                _buildVideoBadge(),
                const SizedBox(width: 8),
              ],
              // 점수 배지
              _buildScoreBadge(qa.score),
              const SizedBox(width: 8),
              // 시간 배지 (영상이 있는 경우만)
              if (hasVideo) _buildTimeBadge(qa.answerDuration),
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
    );
  }

  /// 영상 배지
  Widget _buildVideoBadge() {
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
            '영상',
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

  /// 점수 배지
  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getScoreColor(score),
          width: 1,
        ),
      ),
      child: Text(
        '${score}점',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getScoreColor(score),
        ),
      ),
    );
  }

  /// 시간 배지
  Widget _buildTimeBadge(int duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatTime(duration),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 질문 아이콘
  Widget _buildQuestionIcon(bool hasVideo, bool isSelected) {
    return Icon(
      hasVideo
          ? (isSelected ? Icons.pause_circle_filled : Icons.play_circle_filled)
          : Icons.description,
      color: isSelected
          ? Colors.deepPurple
          : (hasVideo ? Colors.grey.shade600 : Colors.grey.shade400),
      size: 32,
    );
  }

  /// 점수에 따른 색상 반환
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// 시간 포맷팅
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
