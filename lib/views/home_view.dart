import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/dashboard/resume_widget.dart';
import '../widgets/dashboard/interview_widget.dart';
import '../widgets/dashboard/report_widget.dart';

// 스크롤바를 숨기는 커스텀 스크롤 동작
class NoScrollbarBehavior extends ScrollBehavior {
  // 스크롤바 제거
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  // 오버스크롤 효과 제거
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  // 스크롤 물리학 설정
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 앱에서 전역으로 제공하는 HomeController 사용
    return const HomePageContent();
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 참조
    final controller = Provider.of<HomeController>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            Theme.of(context).colorScheme.copyWith(background: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, controller, primaryColor),
        body: _buildBody(context, controller, primaryColor),
      ),
    );
  }

  // 앱바 빌드
  AppBar _buildAppBar(
      BuildContext context, HomeController controller, Color primaryColor) {
    return AppBar(
      title: const Text('홈'),
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      foregroundColor: Colors.white,
      actions: [
        _buildNavMenu(context, controller, primaryColor),
        // 로그아웃 버튼
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context, controller),
        ),
      ],
    );
  }

  // 로그아웃 처리
  void _handleLogout(BuildContext context, HomeController controller) async {
    try {
      await controller.signOut();

      // 로그아웃 성공 시 로그인 화면으로 이동
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 메인 본문 위젯
  Widget _buildBody(
      BuildContext context, HomeController controller, Color primaryColor) {
    // 화면 크기 확인
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // 기본 UI (큰 화면용)
    Widget content = Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to the Ainterview!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final sideMargin = availableWidth * 0.1;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: Column(
                      children: [
                        Expanded(
                          child: ResumeWidget(color: primaryColor),
                        ),
                        Expanded(
                          child: InterviewWidget(color: primaryColor),
                        ),
                        Expanded(
                          child: ReportWidget(color: primaryColor),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );

    // 작은 화면일 경우 스크롤 가능한 UI로 대체
    if (isSmallScreen) {
      content = Container(
        color: Colors.white,
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to the Ainterview!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ResumeWidget(color: primaryColor),
                          const SizedBox(height: 16),
                          InterviewWidget(color: primaryColor),
                          const SizedBox(height: 16),
                          ReportWidget(color: primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return content;
  }

  // 상단 네비게이션 메뉴
  Widget _buildNavMenu(
      BuildContext context, HomeController controller, Color primaryColor) {
    // 메뉴 항목을 제거하고 빈 공간 반환
    return Container();
  }
}
