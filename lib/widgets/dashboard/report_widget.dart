import 'package:flutter/material.dart';
import '../../services/resume/resume_service.dart';
import '../../views/resume_view.dart';

class ReportWidget extends StatelessWidget {
  final Color color;

  const ReportWidget({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '면접 보고서',
      description: '과거 면접 결과를 분석하고 개선점을 확인하세요.',
      imagePath: 'assets/images/report_image.png',
      color: color,
      onTap: () {
        _checkResumeAndNavigate(context);
      },
    );
  }

  // 이력서 확인 후 보고서 화면으로 이동
  Future<void> _checkResumeAndNavigate(BuildContext context) async {
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

      // 이력서 서비스 인스턴스 생성
      final resumeService = ResumeService();

      // 현재 사용자의 이력서 확인
      final existingResume = await resumeService.getCurrentUserResume();

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (existingResume != null) {
        // 이력서가 있으면 보고서 화면으로 이동
        if (context.mounted) {
          Navigator.pushNamed(context, '/report-list');
        }
      } else {
        // 이력서가 없으면 이력서 작성 안내 다이얼로그
        if (context.mounted) {
          _showResumeRequiredDialog(context);
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

  // 이력서가 필요하다는 다이얼로그
  void _showResumeRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('이력서 필요'),
        content: const Text('보고서를 보기 위해서는 이력서 정보가 필요합니다. 먼저 이력서를 작성해주세요.'),
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
              // 이력서 작성 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumeView()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('이력서 작성하기'),
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
                        width: double.infinity,
                        height: imageHeight,
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          height: imageHeight,
                          errorBuilder: (context, error, stackTrace) {
                            print('이미지 로드 오류: $error');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: isSmallScreen ? 40 : 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 8),
                                  Text(
                                    '이미지를 불러올 수 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: isSmallScreen ? 10 : 12,
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
