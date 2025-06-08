import 'package:flutter/material.dart';
import '../../models/report_model.dart';

/// 질문별 피드백 섹션 위젯
/// 각 질문에 대한 AI 분석 결과와 점수를 표시합니다
/// 질문을 클릭하면 피드백이 펼쳐지는 accordion 형태로 동작합니다
class QuestionFeedbackSection extends StatefulWidget {
  final List<QuestionAnswerModel>? questionAnswers;

  const QuestionFeedbackSection({
    Key? key,
    this.questionAnswers,
  }) : super(key: key);

  @override
  State<QuestionFeedbackSection> createState() =>
      _QuestionFeedbackSectionState();
}

class _QuestionFeedbackSectionState extends State<QuestionFeedbackSection> {
  // 각 질문의 펼침 상태를 관리하는 Set
  final Set<int> _expandedQuestions = <int>{};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.quiz,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '질문별 분석 결과',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'AI 평가',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 설명
          Text(
            '각 면접 질문에 대한 답변을 AI가 분석하여 평가한 결과입니다. 질문을 클릭하면 상세한 피드백을 확인할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // 질문별 피드백 리스트
          _buildQuestionFeedbackList(),
        ],
      ),
    );
  }

  Widget _buildQuestionFeedbackList() {
    if (widget.questionAnswers == null || widget.questionAnswers!.isEmpty) {
      return _buildNoFeedback();
    }

    return Column(
      children: widget.questionAnswers!.asMap().entries.map((entry) {
        int index = entry.key;
        QuestionAnswerModel qa = entry.value;
        return _buildQuestionFeedbackItem(index, qa);
      }).toList(),
    );
  }

  Widget _buildQuestionFeedbackItem(int questionIndex, QuestionAnswerModel qa) {
    final isExpanded = _expandedQuestions.contains(questionIndex);
    final questionNumber = questionIndex + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 헤더 (클릭 가능)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedQuestions.remove(questionIndex);
                  } else {
                    _expandedQuestions.add(questionIndex);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isExpanded ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: isExpanded
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )
                      : BorderRadius.circular(12),
                  border: isExpanded
                      ? Border(
                          bottom: BorderSide(color: Colors.blue.shade100),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Q$questionNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        qa.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // 점수 표시
                    _buildScoreBadge(qa.score),
                    const SizedBox(width: 8),
                    // 펼침/접힘 아이콘
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 피드백 내용 (펼쳐진 경우에만 표시)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded ? _buildFeedbackContent(qa) : null,
          ),
        ],
      ),
    );
  }

  /// 피드백 내용을 표시하는 위젯
  Widget _buildFeedbackContent(QuestionAnswerModel qa) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 평가 피드백
          if (qa.evaluation.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 평가 피드백',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                qa.evaluation,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],

          // 포즈 분석 (있는 경우)
          if (qa.poseAnalysis != null && qa.poseAnalysis!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '포즈 분석',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                qa.poseAnalysis!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
          ],

          // 답변 시간 표시
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '답변 시간: ${qa.answerDuration}초',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    MaterialColor badgeColor;
    String label;

    if (score >= 90) {
      badgeColor = Colors.green;
      label = '우수';
    } else if (score >= 80) {
      badgeColor = Colors.blue;
      label = '좋음';
    } else if (score >= 70) {
      badgeColor = Colors.orange;
      label = '보통';
    } else if (score >= 60) {
      badgeColor = Colors.amber;
      label = '개선 필요';
    } else {
      badgeColor = Colors.red;
      label = '미흡';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score점',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: badgeColor.shade700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: badgeColor.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFeedback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '분석 결과가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아직 면접 분석이 완료되지 않았거나\n분석 데이터를 찾을 수 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
