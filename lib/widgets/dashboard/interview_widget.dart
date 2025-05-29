import 'package:flutter/material.dart';
import 'resume_selection_dialog.dart';

/// 대시보드의 면접 시작 위젯
/// 사용자가 면접을 시작할 수 있는 카드 형태의 위젯입니다.
class InterviewWidget extends StatelessWidget {
  final Color color;

  const InterviewWidget({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '면접 시작',
      description: 'AI 면접관과 실시간 면접을 진행하고 피드백을 받아보세요.',
      imagePath: 'assets/images/interview_image.png',
      color: color,
      onTap: () => _onInterviewCardTap(context),
    );
  }

  /// 면접 카드 탭 처리
  void _onInterviewCardTap(BuildContext context) {
    // 이력서 선택 다이얼로그 표시
    ResumeSelectionDialog.show(context, color: color);
  }

  /// 카드 위젯 생성
  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    // 화면 너비와 높이에 따라 스타일 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 800; // 기준을 800으로 변경
    final isVerySmallScreen = screenWidth < 480; // 매우 작은 화면 추가
    final isShortScreen = screenHeight < 600; // 세로가 짧은 화면
    final isVeryShortScreen = screenHeight < 500; // 매우 짧은 화면

    // 반응형 스타일 설정 - 화면 높이도 고려한 더 세밀한 조정
    final double cardHeight = isVeryShortScreen
        ? 130
        : (isShortScreen
            ? 140
            : (isVerySmallScreen ? 160 : (isSmallScreen ? 180 : 220)));
    final double imageHeight = isVeryShortScreen
        ? 100
        : (isShortScreen
            ? 110
            : (isVerySmallScreen ? 120 : (isSmallScreen ? 140 : 200)));
    final double fontSize = isVeryShortScreen
        ? 14
        : (isShortScreen
            ? 15
            : (isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 22)));
    final double descFontSize = isVeryShortScreen
        ? 10
        : (isShortScreen
            ? 11
            : (isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 14)));
    final int maxLines =
        (isVeryShortScreen || isVerySmallScreen) ? 1 : (isSmallScreen ? 2 : 3);
    final double titleSpace = isVeryShortScreen
        ? 4
        : (isShortScreen
            ? 5
            : (isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)));
    final double buttonSpace = isVeryShortScreen
        ? 6
        : (isShortScreen
            ? 7
            : (isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 20)));
    final double padding = isVeryShortScreen
        ? 6
        : (isShortScreen
            ? 7
            : (isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 20)));
    final double buttonPadding = isVeryShortScreen
        ? 4
        : (isShortScreen
            ? 5
            : (isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12)));

    return Container(
      margin: EdgeInsets.only(
          bottom: isVeryShortScreen
              ? 8
              : (isShortScreen ? 10 : (isVerySmallScreen ? 12 : 20))),
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
                  flex: (isVeryShortScreen || isVerySmallScreen)
                      ? 3
                      : 4, // 작은 화면에서는 이미지 영역 축소
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
                        width: double.infinity,
                        height: imageHeight,
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // 이미지 로드 실패 시 아이콘 표시
                            return Icon(
                              Icons.videocam,
                              size: isVeryShortScreen
                                  ? 30
                                  : (isShortScreen
                                      ? 35
                                      : (isVerySmallScreen
                                          ? 40
                                          : (isSmallScreen ? 50 : 64))),
                              color: color.withOpacity(0.5),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // 오른쪽: 텍스트 부분
                Expanded(
                  flex: (isVeryShortScreen || isVerySmallScreen)
                      ? 7
                      : 6, // 작은 화면에서는 텍스트 영역 확대
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
                        Flexible(
                          child: Text(
                            description,
                            maxLines: maxLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: descFontSize,
                              color: Colors.black54,
                              height: 1.2, // 줄 간격 더 조정
                            ),
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
                            minimumSize: Size(
                                0,
                                isVeryShortScreen
                                    ? 28
                                    : (isShortScreen
                                        ? 30
                                        : (isVerySmallScreen
                                            ? 32
                                            : 36))), // 최소 높이 설정
                          ),
                          child: Text(
                            '시작하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isVeryShortScreen
                                  ? 11
                                  : (isShortScreen
                                      ? 12
                                      : (isVerySmallScreen
                                          ? 12
                                          : (isSmallScreen ? 14 : 15))),
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
