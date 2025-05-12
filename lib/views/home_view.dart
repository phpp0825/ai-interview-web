import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
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
    // 컨트롤러 및 필요한 서비스 프로바이더 설정
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // 컨트롤러 생성
    return ChangeNotifierProvider(
      create: (_) => HomeController(firebaseService),
      child: const HomePageContent(),
    );
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
      final success = await controller.signOut();
      if (success && context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      } else if (context.mounted && controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.error!)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 메인 본문 위젯
  Widget _buildBody(
      BuildContext context, HomeController controller, Color primaryColor) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to the Ainterview !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  // 양쪽에 여백을 주기 위한 계산
                  final availableWidth = constraints.maxWidth;
                  final sideMargin = availableWidth * 0.1; // 양쪽 각각 10%씩 여백

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: Column(
                      // 위젯들이 Expanded 안에서 꽉 차게 배치
                      children: [
                        // 이력서 작성 위젯 - 화면 높이의 1/3
                        Expanded(
                          child: ResumeWidget(color: primaryColor),
                        ),
                        // 면접 연습 위젯 - 화면 높이의 1/3
                        Expanded(
                          child: InterviewWidget(color: primaryColor),
                        ),
                        // 면접 보고서 위젯 - 화면 높이의 1/3
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
  }

  // 상단 네비게이션 메뉴
  Widget _buildNavMenu(
      BuildContext context, HomeController controller, Color primaryColor) {
    return Row(
      children: [
        TextButton(
          onPressed: () => controller.navigateToResumeView(context),
          child: const Text(
            '이력서 작성',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () =>
              controller.showInterviewStartDialog(context, primaryColor),
          child: const Text(
            '면접 실행',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () => controller.navigateToReportView(context),
          child: const Text(
            '면접 보고서',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
