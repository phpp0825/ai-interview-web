import 'package:flutter/material.dart';
import '../../views/resume_view.dart';
import '../../core/di/service_locator.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';

class ResumeWidget extends StatelessWidget {
  final Color color;

  const ResumeWidget({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '이력서 작성',
      description: '당신의 경력, 기술, 학력을 정리하여 효과적인 이력서를 작성하세요.',
      imagePath: 'assets/images/resume_image.png',
      color: color,
      onTap: () {
        _checkExistingResumeAndNavigate(context);
      },
    );
  }

  // 이력서 존재 여부 확인 후 이동
  Future<void> _checkExistingResumeAndNavigate(BuildContext context) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('이력서 정보 확인 중...'),
              ],
            ),
          );
        },
      );

      // 서비스 로케이터를 통해 ResumeService 인스턴스 가져오기
      final resumeService = serviceLocator<IResumeService>();

      // 현재 사용자의 이력서 확인
      final existingResume = await resumeService.getCurrentUserResume();

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (existingResume != null) {
        // 이력서가 이미 있는 경우
        if (context.mounted) {
          _showResumeExistsDialog(context);
        }
      } else {
        // 이력서가 없는 경우 바로 이력서 작성 화면으로 이동
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResumeView()),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 로딩 다이얼로그 닫기
      Navigator.of(context).pop();
      // 오류 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이력서 정보 확인 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 이력서가 이미 존재할 때 표시하는 다이얼로그
  void _showResumeExistsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('이력서 정보'),
        content: const Text('이미 작성된 이력서가 있습니다. 어떻게 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 취소
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 새 이력서 작성 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumeView()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('새 이력서 작성'),
          ),
        ],
      ),
    );
  }

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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            height: imageHeight,
                            errorBuilder: (context, error, stackTrace) {
                              print('🚨 이미지 로드 오류 ($imagePath): $error');
                              return Container(
                                width: double.infinity,
                                height: imageHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      color.withOpacity(0.3),
                                      color.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: isVeryShortScreen
                                          ? 30
                                          : (isShortScreen
                                              ? 35
                                              : (isVerySmallScreen
                                                  ? 40
                                                  : (isSmallScreen ? 50 : 60))),
                                      color: color,
                                    ),
                                    if (!(isVeryShortScreen ||
                                        isVerySmallScreen))
                                      SizedBox(height: isSmallScreen ? 4 : 8),
                                    if (!(isVeryShortScreen ||
                                        isVerySmallScreen))
                                      Text(
                                        '이력서',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: isSmallScreen ? 11 : 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
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
