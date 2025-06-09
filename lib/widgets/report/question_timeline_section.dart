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
      print('🔍 영상 존재 여부 체크: ${qa.videoUrl}');

      // Firebase Storage URL 체크
      if (qa.videoUrl != null && qa.videoUrl.isNotEmpty) {
        print('📹 videoUrl이 존재: ${qa.videoUrl}');

        // Firebase Storage URL 패턴들 확인 (더 유연한 체크)
        final isFirebaseStorage =
            qa.videoUrl.startsWith('https://firebasestorage.googleapis.com/') ||
                qa.videoUrl.startsWith('https://storage.googleapis.com/') ||
                qa.videoUrl.contains('firebasestorage') ||
                qa.videoUrl.contains('storage.googleapis.com');

        if (isFirebaseStorage) {
          print('✅ Firebase Storage URL 확인됨');
          return true;
        } else {
          print(
              '⚠️ Firebase Storage URL이 아닙니다: ${qa.videoUrl.substring(0, 100)}...');
          // 다른 유효한 HTTP URL이면 허용
          if (qa.videoUrl.startsWith('http://') ||
              qa.videoUrl.startsWith('https://')) {
            print('✅ 일반 HTTP URL로 허용');
            return true;
          }
        }
      } else {
        print('❌ videoUrl이 비어있습니다');
      }

      return false;
    } catch (e) {
      print('❌ 영상 존재 여부 체크 실패: $e');
      return false;
    }
  }

  /// 영상이 있을 때 메시지 생성
  String _getNoVideoMessage(dynamic qa) {
    try {
      print('🔍 영상 없음 메시지 생성: ${qa.videoUrl}');

      if (qa.videoUrl != null && qa.videoUrl.isNotEmpty) {
        if (qa.videoUrl.startsWith('blob:')) {
          return '이전 방식(blob URL)으로 저장된 영상입니다.\n새로운 면접을 진행해주세요.';
        } else if (qa.videoUrl.startsWith('video_') ||
            qa.videoUrl.contains('localStorage')) {
          return '이전 방식(로컬 저장)으로 저장된 영상입니다.\n새로운 면접을 진행해주세요.';
        } else if (qa.videoUrl.startsWith('http')) {
          // Firebase Storage URL 상세 체크
          if (qa.videoUrl.contains('firebasestorage.googleapis.com') ||
              qa.videoUrl.contains('storage.googleapis.com')) {
            return 'Firebase Storage 영상을 불러올 수 없습니다.\n권한 설정을 확인해주세요.';
          } else {
            return '외부 URL 영상을 불러올 수 없습니다.\n${qa.videoUrl.substring(0, 50)}...';
          }
        } else {
          return '유효하지 않은 영상 경로입니다.\n형식: ${qa.videoUrl.substring(0, 30)}...';
        }
      } else {
        return '이 질문에는 답변 영상이 없습니다.';
      }
    } catch (e) {
      print('❌ 영상 없음 메시지 생성 실패: $e');
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
        // 답변 통계 섹션 제거됨

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
          _buildStructuredPoseAnalysis(qa.poseAnalysis!),
          const SizedBox(height: 16),
        ],

        // 3. AI 평가 및 피드백 - 구조화된 형태로 개선
        if (qa.evaluation.isNotEmpty) ...[
          _buildStructuredEvaluation(qa.evaluation),
        ],
      ],
    );
  }

  /// 구조화된 포즈 분석을 표시하는 위젯
  Widget _buildStructuredPoseAnalysis(String poseAnalysis) {
    // 포즈 분석 텍스트를 파싱하여 시간 정보와 내용 분리
    final poseData = _parsePoseAnalysisText(poseAnalysis);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.accessibility_new,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '포즈 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 시간 정보가 있는 경우 시간 막대들 표시
          if (poseData['timePoints'] != null &&
              poseData['timePoints'].isNotEmpty) ...[
            Column(
              children: poseData['timePoints'].map<Widget>((timePoint) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 시간 아이콘
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 시간 표시
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          timePoint['time'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 시간 설명
                      Expanded(
                        child: Text(
                          timePoint['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // 구조화된 섹션들 표시
          if (poseData['sections'] != null &&
              poseData['sections'].isNotEmpty) ...[
            Column(
              children: poseData['sections'].map<Widget>((section) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: section['color'].shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 섹션 헤더
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: section['color'].shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              section['icon'],
                              color: section['color'].shade600,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 섹션 제목 배지
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: section['color'].shade600,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              section['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 섹션 내용
                      _buildSectionContent(
                          section['content'], section['color']),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            // 일반 포즈 분석 내용 (구조화된 섹션이 없는 경우)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                poseAnalysis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 포즈 분석 텍스트를 파싱하여 구조화된 데이터로 변환
  Map<String, dynamic> _parsePoseAnalysisText(String? poseAnalysis) {
    final result = <String, dynamic>{
      'sections': <Map<String, dynamic>>[],
      'generalInfo': <String>[],
      'timePoints': <Map<String, String>>[],
    };

    // null이나 빈 문자열인 경우 빈 결과 반환
    if (poseAnalysis == null || poseAnalysis.isEmpty) {
      return result;
    }

    try {
      // 섹션 구분 패턴 ([시선 분석], [총 영상 길이] 등)
      final RegExp sectionPattern = RegExp(r'\[([^\]]+)\]');
      final sections = <Map<String, dynamic>>[];

      // 텍스트를 줄 단위로 분리
      final lines = poseAnalysis
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      String? currentSection;
      List<String> currentContent = [];

      for (final line in lines) {
        final sectionMatch = sectionPattern.firstMatch(line);

        if (sectionMatch != null) {
          // 이전 섹션 저장
          if (currentSection != null && currentContent.isNotEmpty) {
            sections.add({
              'title': currentSection,
              'content': currentContent.join('\n'),
              'icon': _getSectionIcon(currentSection),
              'color': _getSectionColor(currentSection),
            });
          }

          // 새 섹션 시작
          currentSection = sectionMatch.group(1);
          currentContent = [];
        } else {
          // 현재 섹션의 내용 추가
          if (currentSection != null) {
            currentContent.add(line);
          } else {
            // 섹션이 없는 일반 정보
            result['generalInfo'].add(line);
          }
        }
      }

      // 마지막 섹션 저장
      if (currentSection != null && currentContent.isNotEmpty) {
        sections.add({
          'title': currentSection,
          'content': currentContent.join('\n'),
          'icon': _getSectionIcon(currentSection),
          'color': _getSectionColor(currentSection),
        });
      }

      result['sections'] = sections;
    } catch (e) {
      print('포즈 분석 텍스트 파싱 중 오류: $e');
      // 파싱 실패 시 원본 텍스트를 일반 정보로 저장
      result['generalInfo'] = [poseAnalysis];
    }

    return result;
  }

  /// 섹션 제목에 따른 아이콘 반환
  IconData _getSectionIcon(String sectionTitle) {
    switch (sectionTitle.toLowerCase()) {
      case '시선 분석':
        return Icons.visibility;
      case '총 영상 길이':
        return Icons.timer;
      case '포즈 분석':
        return Icons.accessibility_new;
      case '자세 분석':
        return Icons.person;
      case '움직임 분석':
        return Icons.directions_walk;
      default:
        return Icons.analytics;
    }
  }

  /// 섹션 제목에 따른 색상 반환
  Color _getSectionColor(String sectionTitle) {
    switch (sectionTitle.toLowerCase()) {
      case '시선 분석':
        return Colors.blue;
      case '총 영상 길이':
        return Colors.purple;
      case '포즈 분석':
        return Colors.green;
      case '자세 분석':
        return Colors.orange;
      case '움직임 분석':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  /// 섹션 내용을 구조화하여 표시
  Widget _buildSectionContent(String? content, Color sectionColor) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    final lines =
        content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // 숫자나 통계가 포함된 라인인지 확인
        final hasStats = RegExp(r'\d+\.?\d*\s*(프레임|초|%|\()').hasMatch(line);

        if (hasStats) {
          // MaterialColor로 캐스팅하여 shade 접근
          final MaterialColor materialColor =
              sectionColor is MaterialColor ? sectionColor : Colors.blue; // 기본값

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: materialColor.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: materialColor.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: materialColor.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: materialColor.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          );
        }
      }).toList(),
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

    // Firebase 관련 문제인지 확인
    bool isFirebaseIssue =
        message.contains('Firebase') || message.contains('권한');

    if (message.contains('이전 방식') || message.contains('새로운 면접')) {
      icon = Icons.update;
      iconColor = Colors.orange.shade500;
      backgroundColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
    } else if (isFirebaseIssue) {
      icon = Icons.cloud_off;
      iconColor = Colors.red.shade500;
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
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

            // Firebase 권한 문제인 경우 추가 안내
            if (isFirebaseIssue) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '해결 방법',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Firebase Console에서 Storage 규칙 확인\n'
                      '2. 브라우저 개발자 도구에서 에러 확인\n'
                      '3. 네트워크 연결 상태 확인',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 구조화된 평가 내용을 표시하는 위젯
  Widget _buildStructuredEvaluation(String evaluationText) {
    final evaluationData = _parseEvaluationText(evaluationText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 평가 항목들을 Grid 형태로 배치
        if (evaluationData['categories'].isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '상세 평가 항목',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 세로로 나열된 가로 막대들
                Column(
                  children: evaluationData['categories']
                      .asMap()
                      .entries
                      .map<Widget>((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: index < evaluationData['categories'].length - 1
                            ? 12
                            : 0,
                      ),
                      child: _buildEvaluationBar(category['name'],
                          category['rating'], category['comment']),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 총점 및 등급 표시
          if (evaluationData['totalScore'] != null ||
              evaluationData['grade'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.purple.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '종합 평가 결과',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
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
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${evaluationData['totalScore']}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '총점',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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
                            Text(
                              '등급',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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

          // 추천 답변 표시
          if (evaluationData['recommendedAnswer'] != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                            color: Colors.grey.shade800,
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
                        color: Colors.grey.shade700,
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
                  evaluationText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 가로 막대 형태의 평가 항목 위젯
  Widget _buildEvaluationBar(
      String categoryName, String rating, String comment) {
    Color accentColor;
    IconData iconData;

    switch (rating.toLowerCase()) {
      case '높음':
      case '매우 높음':
        accentColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        break;
      case '보통':
        accentColor = Colors.orange.shade600;
        iconData = Icons.info_rounded;
        break;
      case '낮음':
      case '매우 낮음':
        accentColor = Colors.red.shade600;
        iconData = Icons.warning_rounded;
        break;
      default:
        accentColor = Colors.grey.shade600;
        iconData = Icons.help_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘과 카테고리명
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              _getCategoryDisplayName(categoryName),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 등급 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 12),

          // 코멘트
          Expanded(
            flex: 3,
            child: Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 평가 항목 카드 위젯
  Widget _buildEvaluationCard(
      String categoryName, String rating, String comment) {
    Color accentColor;
    IconData iconData;

    switch (rating.toLowerCase()) {
      case '높음':
      case '매우 높음':
        accentColor = Colors.green.shade600;
        iconData = Icons.check_circle_rounded;
        break;
      case '보통':
        accentColor = Colors.orange.shade600;
        iconData = Icons.info_rounded;
        break;
      case '낮음':
      case '매우 낮음':
        accentColor = Colors.red.shade600;
        iconData = Icons.warning_rounded;
        break;
      default:
        accentColor = Colors.grey.shade600;
        iconData = Icons.help_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 이름과 아이콘
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    color: accentColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getCategoryDisplayName(categoryName),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 등급 표시
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rating,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 코멘트 (더 간단하게)
            Text(
              comment.length > 30 ? '${comment.substring(0, 27)}...' : comment,
              style: TextStyle(
                fontSize: 9,
                height: 1.3,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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

        // 총점 파싱
        if (line.contains('총점:') || line.contains('점수:')) {
          final scoreMatch = RegExp(r'(\d+)점').firstMatch(line);
          if (scoreMatch != null) {
            result['totalScore'] = scoreMatch.group(1);
          }
        }

        // 등급 파싱
        if (line.contains('등급:')) {
          final gradeMatch =
              RegExp(r'등급:\s*([A-F][+-]?\s*(?:\([^)]+\))?)').firstMatch(line);
          if (gradeMatch != null) {
            result['grade'] = gradeMatch.group(1)?.trim();
          }
        }

        // 추천 답변 파싱
        if (line.contains('추천 답변:')) {
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
}
