import 'package:flutter/material.dart';
import '../../views/report_list_view.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';
import '../../core/di/service_locator.dart';
import '../../views/resume_view.dart';
import '../../services/report/interfaces/report_service_interface.dart';

/// 면접 보고서 위젯
///
/// 이 위젯은 홈 화면에 표시되며, 면접 보고서 목록으로 이동하는 카드입니다.
class ReportWidget extends StatefulWidget {
  final Color color;

  const ReportWidget({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '면접 보고서',
      description: '완료된 면접 분석 결과를 확인하고 피드백을 받아보세요.',
      imagePath: 'assets/images/report_image.png',
      color: widget.color,
      onTap: _isLoading ? null : () => _handleTap(context),
      isLoading: _isLoading,
    );
  }

  /// 탭 이벤트 처리
  void _handleTap(BuildContext context) {
    // 보고서 확인 및 화면 전환 로직
    _checkReportAndNavigate(context);
  }

  /// 보고서 목록 확인 및 화면 전환
  Future<void> _checkReportAndNavigate(BuildContext context) async {
    try {
      // 로딩 상태 시작
      setState(() {
        _isLoading = true;
      });

      // 필요한 서비스 가져오기
      final reportService = serviceLocator<IReportService>();
      final resumeService = serviceLocator<IResumeService>();

      // 1. 먼저 이력서가 있는지 확인
      final existingResume = await resumeService.getCurrentUserResume();

      // 2. 보고서 목록 가져오기
      final reportList = await reportService.getCurrentUserReportList();

      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) return;

      // 이력서가 없는 경우
      if (existingResume == null) {
        _showNoResumeDialog(context);
        return;
      }

      // 보고서가 없는 경우
      if (reportList.isEmpty) {
        _showNoReportDialog(context);
        return;
      }

      // 보고서가 있는 경우 보고서 목록 화면으로 이동
      if (mounted) {
        // 페이지 전환 애니메이션 개선
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ReportListView(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      // 오류 발생 시 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('보고서 정보 확인 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 이력서 필요 다이얼로그 표시
  void _showNoResumeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('이력서 필요'),
        content: const Text('면접 보고서를 확인하려면 이력서가 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const ResumeView(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('이력서 작성하기'),
          ),
        ],
      ),
    );
  }

  /// 보고서 없음 다이얼로그 표시
  void _showNoReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('보고서 없음'),
        content: const Text('아직 생성된 면접 보고서가 없습니다. 면접을 완료하면 보고서가 자동으로 생성됩니다.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
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
    required VoidCallback? onTap,
    required bool isLoading,
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
                        child: !isLoading
                            ? Image.asset(
                                imagePath,
                                fit: BoxFit.contain,
                                height: imageHeight,
                                errorBuilder: (context, error, stackTrace) {
                                  print('이미지 로드 오류: $error');
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assessment_rounded,
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
                              )
                            : const CircularProgressIndicator(),
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
                          onPressed: isLoading ? null : onTap,
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
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
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
