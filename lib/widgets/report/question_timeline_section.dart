import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/report_controller.dart';
import '../../models/report_model.dart';
import './fixed_video_player.dart';

/// 질문별 타임라인 섹션 위젯 (통합형)
/// 각 질문을 클릭하면 해당 질문의 영상과 피드백이 바로 아래 펼쳐지는 accordion 형태입니다
class QuestionTimelineSection extends StatefulWidget {
  final ReportController controller;
  final ReportModel reportData;

  const QuestionTimelineSection({
    Key? key,
    required this.controller,
    required this.reportData,
  }) : super(key: key);

  @override
  State<QuestionTimelineSection> createState() =>
      _QuestionTimelineSectionState();
}

class _QuestionTimelineSectionState extends State<QuestionTimelineSection> {
  // 펼쳐진 질문들을 관리하는 Set
  final Set<int> _expandedQuestions = <int>{};

  /// 영상 존재 여부 체크 (Firebase Storage URL)
  bool _checkVideoAvailability(dynamic qa) {
    try {
      // Firebase Storage URL 체크
      if (qa.videoUrl != null && qa.videoUrl.isNotEmpty) {
        // 유효한 Firebase Storage URL인지 확인
        if (qa.videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('영상 존재 여부 체크 실패: $e');
      return false;
    }
  }

  /// 영상 없을 때 메시지 생성
  String _getNoVideoMessage(dynamic qa) {
    try {
      if (qa.videoUrl != null && qa.videoUrl.isNotEmpty) {
        if (qa.videoUrl.startsWith('blob:')) {
          return '이전 방식(blob URL)으로 저장된 영상입니다.\n새로운 면접을 진행해주세요.';
        } else if (qa.videoUrl.startsWith('video_') ||
            qa.videoUrl.contains('localStorage')) {
          return '이전 방식(로컬 저장)으로 저장된 영상입니다.\n새로운 면접을 진행해주세요.';
        } else if (qa.videoUrl.startsWith('http')) {
          return 'Firebase Storage 영상을 불러올 수 없습니다.';
        } else {
          return '유효하지 않은 영상 경로입니다.';
        }
      } else {
        return '이 질문에는 답변 영상이 없습니다.';
      }
    } catch (e) {
      return '영상 상태를 확인할 수 없습니다.';
    }
  }

  /// 빈 데이터일 때 안내 메시지
  Widget _buildEmptyDataMessage() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '면접 질문 데이터가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '면접을 진행하시면 여기에 질문별 분석 결과가 표시됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reportData.questionAnswers == null ||
        widget.reportData.questionAnswers!.isEmpty) {
      return _buildEmptyDataMessage();
    }

    final allQuestions =
        widget.reportData.questionAnswers!.asMap().entries.toList();

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

          // 질문 목록 (accordion 형태)
          _buildAccordionQuestionList(allQuestions),
        ],
      ),
    );
  }

  /// 헤더 영역
  Widget _buildHeader(int questionCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.quiz,
            color: Colors.deepPurple.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '면접 질문별 분석',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),
              Text(
                '총 $questionCount개 질문 | 클릭하여 영상과 피드백 확인',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Accordion 형태의 질문 목록
  Widget _buildAccordionQuestionList(
      List<MapEntry<int, dynamic>> allQuestions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allQuestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = allQuestions[index];
        final originalIndex = entry.key;
        final qa = entry.value;
        final isExpanded = _expandedQuestions.contains(originalIndex);
        // 하위 호환성을 위한 영상 존재 여부 체크
        final hasVideo = _checkVideoAvailability(qa);

        return _buildAccordionQuestionItem(
          originalIndex,
          qa,
          isExpanded,
          hasVideo,
        );
      },
    );
  }

  /// Accordion 형태의 개별 질문 아이템
  Widget _buildAccordionQuestionItem(
    int originalIndex,
    dynamic qa,
    bool isExpanded,
    bool hasVideo,
  ) {
    return Column(
      children: [
        // 질문 헤더 (클릭 가능)
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedQuestions.remove(originalIndex);
              } else {
                _expandedQuestions.add(originalIndex);
                // 질문을 펼칠 때 컨트롤러도 업데이트
                widget.controller.selectQuestion(originalIndex);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isExpanded ? Colors.deepPurple.shade50 : Colors.white,
              border: isExpanded
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
                _buildQuestionBadge(originalIndex, qa.score, isExpanded),
                const SizedBox(width: 16),

                // 질문 내용
                _buildQuestionContent(originalIndex, qa, isExpanded, hasVideo),

                // 펼침/접힘 아이콘
                _buildExpandIcon(hasVideo, isExpanded),
              ],
            ),
          ),
        ),

        // 펼쳐지는 내용 (영상 + 피드백)
        if (isExpanded) _buildExpandedContent(originalIndex, qa, hasVideo),
      ],
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
              // 시간 배지 (영상이 있는 경우만) - 클릭하여 해당 시간으로 이동
              if (hasVideo)
                Tooltip(
                  message: '클릭하여 질문 시작 시간으로 이동',
                  child: _buildTimeBadge(qa.answerDuration, index),
                ),
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

  /// 시간 배지 - 단순 정보 표시용
  Widget _buildTimeBadge(int duration, [int? targetQuestionIndex]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(duration),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 질문 아이콘
  Widget _buildExpandIcon(bool hasVideo, bool isExpanded) {
    return Icon(
      isExpanded ? Icons.expand_less : Icons.expand_more,
      color: Colors.grey.shade600,
      size: 24,
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

  /// 펼쳐지는 내용 (영상 + 피드백)
  Widget _buildExpandedContent(int originalIndex, dynamic qa, bool hasVideo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: Colors.deepPurple.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '질문 ${originalIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  qa.question,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // 영상 플레이어 (영상이 있는 경우)
          if (hasVideo) ...[
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _checkVideoAvailability(qa)
                    ? FixedVideoPlayer(
                        videoUrl: qa.videoUrl,
                        key: ValueKey(
                            'timeline_${originalIndex}_${qa.videoUrl}'),
                      )
                    : _buildNoVideoMessage(_getNoVideoMessage(qa)),
              ),
            ),
          ] else ...[
            // 영상이 없는 경우 안내
            _buildNoVideoMessage('이 질문에는 답변 영상이 없습니다'),
          ],

          // 답변 정보 및 피드백
          _buildAnswerInfo(qa),
        ],
      ),
    );
  }

  /// 답변 정보 및 피드백
  Widget _buildAnswerInfo(dynamic qa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 답변 통계
        Row(
          children: [
            _buildStatCard('점수', '${qa.score}점', _getScoreColor(qa.score)),
            const SizedBox(width: 12),
            _buildStatCard(
                '답변 시간', _formatTime(qa.answerDuration), Colors.blue),
          ],
        ),
        const SizedBox(height: 16),

        // 1. 답변 내용 (있는 경우)
        if (qa.answer.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '답변 내용',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  qa.answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. 포즈 분석 (있는 경우)
        if (qa.poseAnalysis != null && qa.poseAnalysis!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPoseAnalysisTimeSummary(qa.poseAnalysis),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. AI 평가 및 피드백
        if (qa.evaluation.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 평가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  qa.evaluation,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPoseAnalysisTimeSummary(String? poseAnalysis) {
    if (poseAnalysis == null || poseAnalysis.isEmpty) {
      return const SizedBox.shrink();
    }

    // 시간 패턴 찾기 (1.47 sec, 2:30, 0:45 등)
    final RegExp timePatterns = RegExp(
      r'(\d+\.?\d*)\s*sec|(\d+):(\d{2})|(\d+):(\d{1})|(\d+분)\s*(\d+초)|(\d+초)',
      caseSensitive: false,
    );

    final matches = timePatterns.allMatches(poseAnalysis);

    if (matches.isEmpty) {
      // 시간 정보가 없으면 원본 텍스트만 표시
      return Text(
        poseAnalysis,
        style: TextStyle(
          fontSize: 16,
          color: Colors.green.shade800,
          height: 1.5,
        ),
      );
    }

    List<String> timeStrings = [];
    for (final match in matches) {
      if (match.group(1) != null) {
        // X.XX sec 형태
        final seconds = double.tryParse(match.group(1)!) ?? 0;
        if (seconds < 60) {
          timeStrings.add('~${seconds.toStringAsFixed(1)}초');
        } else {
          final minutes = (seconds / 60).floor();
          final remainingSeconds = (seconds % 60).round();
          timeStrings.add('~${minutes}분${remainingSeconds}초');
        }
      } else if (match.group(2) != null && match.group(3) != null) {
        // MM:SS 형태
        timeStrings.add('~${match.group(2)}분${match.group(3)}초');
      }
    }

    if (timeStrings.isEmpty) {
      return Text(
        poseAnalysis,
        style: TextStyle(
          fontSize: 16,
          color: Colors.green.shade800,
          height: 1.5,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '주요 시점',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeStrings.join(', '),
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            poseAnalysis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 카드
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 영상이 없는 경우 안내 메시지
  Widget _buildNoVideoMessage(String message) {
    // 메시지에 따라 다른 아이콘과 색상 사용
    IconData icon = Icons.videocam_off;
    Color iconColor = Colors.grey.shade500;
    Color backgroundColor = Colors.grey.shade100;
    Color borderColor = Colors.grey.shade300;

    if (message.contains('이전 방식') || message.contains('새로운 면접')) {
      icon = Icons.update;
      iconColor = Colors.orange.shade500;
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
    } else if (message.contains('Firebase') || message.contains('삭제')) {
      icon = Icons.cloud_off;
      iconColor = Colors.red.shade500;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
    }

    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
