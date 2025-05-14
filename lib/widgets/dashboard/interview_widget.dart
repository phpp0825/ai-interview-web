import 'package:flutter/material.dart';
import '../../views/resume_view.dart';
import '../../views/http_interview_view.dart';
import '../../services/resume/resume_service.dart';

class InterviewWidget extends StatelessWidget {
  final Color color;

  const InterviewWidget({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '면접 연습',
      description: 'AI와 모의 면접을 통해 실제 면접 상황에 대비하세요.',
      imagePath: 'assets/images/interview_image.png',
      color: color,
      onTap: () {
        _checkResumeAndNavigate(context);
      },
    );
  }

  // 이력서 확인 후 면접 화면으로 이동
  Future<void> _checkResumeAndNavigate(BuildContext context) async {
    final resumeService = ResumeService();

    try {
      // 이력서 목록 조회
      final resumeList = await resumeService.getCurrentUserResumeList();

      if (resumeList.isEmpty) {
        // 이력서가 없으면 이력서 작성 화면으로 이동 여부 확인
        _showNoResumeDialog(context);
      } else {
        // 이력서가 있으면 면접 화면으로 이동
        _navigateToInterviewScreen(context);
      }
    } catch (e) {
      // 오류 발생 시 면접 화면으로 이동 (화면에서 이력서 선택 가능)
      _navigateToInterviewScreen(context);
    }
  }

  // 이력서 없음 다이얼로그 표시
  void _showNoResumeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이력서가 필요합니다'),
        content: const Text('면접을 시작하려면 이력서가 필요합니다. 이력서를 작성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 이력서 작성 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumeView()),
              );
            },
            child: const Text('이력서 작성'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 그냥 면접 화면으로 이동
              _navigateToInterviewScreen(context);
            },
            child: const Text('그냥 면접 시작'),
          ),
        ],
      ),
    );
  }

  // 면접 화면으로 이동
  void _navigateToInterviewScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HttpInterviewView()),
    );
  }

  // 카드 위젯 생성
  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    // 화면 너비에 따라 스타일 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // 반응형 스타일 설정
    final double cardHeight = isSmallScreen ? 180 : 220;
    final double imageHeight = isSmallScreen ? 140 : 200;
    final double fontSize = isSmallScreen ? 18 : 22;
    final double descFontSize = isSmallScreen ? 12 : 14;
    final int maxLines = isSmallScreen ? 2 : 3;
    final double titleSpace = isSmallScreen ? 8 : 12;
    final double buttonSpace = isSmallScreen ? 12 : 20;
    final double padding = isSmallScreen ? 12 : 20;
    final double buttonPadding = isSmallScreen ? 8 : 12;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 왼쪽: 이미지 부분
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding / 2),
                      child: Container(
                        width: double.infinity, // 컨테이너 너비를 최대로 설정
                        height: imageHeight,
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),

                // 오른쪽: 텍스트 부분
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 제목
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        SizedBox(height: titleSpace),
                        // 설명
                        Text(
                          description,
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: buttonSpace),
                        // 버튼
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPadding * 2,
                              vertical: buttonPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            '시작하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
