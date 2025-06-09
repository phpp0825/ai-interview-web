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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStructuredEvaluation(qa.evaluation),
          ],

          // 포즈 분석 (있는 경우)
          if (qa.poseAnalysis != null && qa.poseAnalysis!.isNotEmpty) ...[
            const SizedBox(height: 24),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                qa.poseAnalysis!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ],

          // 답변 시간 표시
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '답변 시간: ${qa.answerDuration}초',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 구조화된 평가 내용을 표시하는 위젯
  Widget _buildStructuredEvaluation(String evaluationText) {
    // 평가 텍스트를 파싱하여 구조화된 형태로 변환
    final evaluationData = _parseEvaluationText(evaluationText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 평가 항목들을 Grid 형태로 배치
        if (evaluationData['categories'].isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '상세 평가 항목',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Grid 형태로 평가 카드들 배치
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: evaluationData['categories'].length,
                  itemBuilder: (context, index) {
                    final category = evaluationData['categories'][index];
                    return _buildEvaluationCard(category['name'],
                        category['rating'], category['comment']);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 총점 및 등급 표시 - 더 시각적으로 개선
          if (evaluationData['totalScore'] != null ||
              evaluationData['grade'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                    Colors.indigo.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '종합 평가 결과',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (evaluationData['totalScore'] != null)
                        Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${evaluationData['totalScore']}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '총점',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (evaluationData['grade'] != null)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                evaluationData['grade'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '등급',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 추천 답변 표시 - 더 매력적으로 개선
          if (evaluationData['recommendedAnswer'] != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade100, Colors.yellow.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.amber.shade300, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '💡 추천 답변',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      evaluationData['recommendedAnswer'],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // 파싱되지 않은 경우 기본 텍스트 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              evaluationText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 개별 평가 항목 카드 위젯
  Widget _buildEvaluationCard(
      String categoryName, String rating, String comment) {
    // 평가 등급에 따른 색상 설정
    List<Color> gradientColors;
    Color textColor;
    Color accentColor;
    IconData iconData;

    switch (rating.toLowerCase()) {
      case '높음':
      case '매우 높음':
        gradientColors = [Colors.green.shade100, Colors.green.shade50];
        textColor = Colors.green.shade800;
        accentColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        break;
      case '보통':
        gradientColors = [Colors.orange.shade100, Colors.orange.shade50];
        textColor = Colors.orange.shade800;
        accentColor = Colors.orange.shade600;
        iconData = Icons.info_rounded;
        break;
      case '낮음':
      case '매우 낮음':
        gradientColors = [Colors.red.shade100, Colors.red.shade50];
        textColor = Colors.red.shade800;
        accentColor = Colors.red.shade600;
        iconData = Icons.warning_rounded;
        break;
      default:
        gradientColors = [Colors.grey.shade100, Colors.grey.shade50];
        textColor = Colors.grey.shade800;
        accentColor = Colors.grey.shade600;
        iconData = Icons.help_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconData,
                    color: accentColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getCategoryDisplayName(categoryName),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 등급 표시
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 코멘트 (축약된 형태로)
            Text(
              comment.length > 50 ? '${comment.substring(0, 47)}...' : comment,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: textColor.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 평가 카테고리 이름을 한국어로 변환
  String _getCategoryDisplayName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'relevance':
        return '관련성';
      case 'completeness':
        return '완성도';
      case 'correctness':
        return '정확성';
      case 'clarity':
        return '명확성';
      case 'professionalism':
        return '전문성';
      default:
        return categoryName;
    }
  }

  /// 평가 텍스트를 파싱하여 구조화된 데이터로 변환
  Map<String, dynamic> _parseEvaluationText(String evaluationText) {
    final result = <String, dynamic>{
      'categories': <Map<String, String>>[],
      'totalScore': null,
      'grade': null,
      'recommendedAnswer': null,
    };

    try {
      final lines = evaluationText.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // 평가 항목 파싱 (예: "relevance: 높음 - 설명...")
        if (line.contains(':') && line.contains('-')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final categoryName = parts[0].trim();
            final remaining = parts.sublist(1).join(':').trim();
            final dashIndex = remaining.indexOf('-');

            if (dashIndex > 0) {
              final rating = remaining.substring(0, dashIndex).trim();
              final comment = remaining.substring(dashIndex + 1).trim();

              result['categories'].add({
                'name': categoryName,
                'rating': rating,
                'comment': comment,
              });
            }
          }
        }

        // 총점 파싱 (예: "총점: 80점")
        if (line.contains('총점:') || line.contains('점수:')) {
          final scoreMatch = RegExp(r'(\d+)점').firstMatch(line);
          if (scoreMatch != null) {
            result['totalScore'] = scoreMatch.group(1);
          }
        }

        // 등급 파싱 (예: "등급: B+ (양호)")
        if (line.contains('등급:')) {
          final gradeMatch =
              RegExp(r'등급:\s*([A-F][+-]?\s*(?:\([^)]+\))?)').firstMatch(line);
          if (gradeMatch != null) {
            result['grade'] = gradeMatch.group(1)?.trim();
          }
        }

        // 추천 답변 파싱
        if (line.contains('추천 답변:')) {
          // 추천 답변 다음 줄부터 수집
          final recommendedLines = <String>[];
          for (int j = i + 1; j < lines.length; j++) {
            final nextLine = lines[j].trim();
            if (nextLine.isEmpty ||
                nextLine.startsWith('답변 시간:') ||
                nextLine.startsWith('침묵 시간:') ||
                nextLine.startsWith('=')) {
              break;
            }
            recommendedLines.add(nextLine);
          }
          if (recommendedLines.isNotEmpty) {
            result['recommendedAnswer'] = recommendedLines.join(' ').trim();
          }
        }
      }
    } catch (e) {
      print('평가 텍스트 파싱 중 오류: $e');
    }

    return result;
  }

  Widget _buildScoreBadge(int score) {
    List<Color> gradientColors;
    String label;
    IconData iconData;

    if (score >= 90) {
      gradientColors = [Colors.green.shade400, Colors.green.shade600];
      label = '우수';
      iconData = Icons.emoji_events;
    } else if (score >= 80) {
      gradientColors = [Colors.blue.shade400, Colors.blue.shade600];
      label = '좋음';
      iconData = Icons.star;
    } else if (score >= 70) {
      gradientColors = [Colors.orange.shade400, Colors.orange.shade600];
      label = '보통';
      iconData = Icons.star_half;
    } else if (score >= 60) {
      gradientColors = [Colors.amber.shade400, Colors.amber.shade600];
      label = '개선필요';
      iconData = Icons.trending_up;
    } else {
      gradientColors = [Colors.red.shade400, Colors.red.shade600];
      label = '미흡';
      iconData = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$score점',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
