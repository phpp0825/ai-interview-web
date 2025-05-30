import 'package:flutter/material.dart';
import '../../views/report_list_view.dart';
import '../../core/di/service_locator.dart';
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

      // 보고서 목록 가져오기
      final reportList = await reportService.getCurrentUserReportList();

      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) return;

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
                        child: !isLoading
                            ? Image.asset(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          size: isVerySmallScreen
                                              ? 30
                                              : (isSmallScreen ? 50 : 60),
                                          color: color,
                                        ),
                                        if (!isVerySmallScreen)
                                          SizedBox(
                                              height: isSmallScreen ? 4 : 8),
                                        if (!isVerySmallScreen)
                                          Text(
                                            '리포트',
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
                              )
                            : const CircularProgressIndicator(),
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
                          child: isLoading
                              ? SizedBox(
                                  width: isVeryShortScreen
                                      ? 14
                                      : (isShortScreen
                                          ? 16
                                          : (isVerySmallScreen ? 16 : 20)),
                                  height: isVeryShortScreen
                                      ? 14
                                      : (isShortScreen
                                          ? 16
                                          : (isVerySmallScreen ? 16 : 20)),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  '살펴보기',
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
