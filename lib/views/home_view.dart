import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../controllers/home_controller.dart';
import '../widgets/dashboard/resume_widget.dart';
import '../widgets/dashboard/interview_widget.dart';
import '../widgets/dashboard/report_widget.dart';

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
        // 리포트 생성 버튼
        IconButton(
          icon: const Icon(Icons.assessment),
          tooltip: '새 리포트 생성',
          onPressed: () => controller.showCreateReportDialog(context),
        ),
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
                  // 양쪽에 1/5씩 여백을 주기 위해 너비 계산
                  final availableWidth = constraints.maxWidth;
                  final contentWidth = availableWidth * 3 / 5; // 전체의 3/5만 사용
                  final sideMargin = availableWidth * 1 / 5; // 양쪽 각각 1/5씩 여백

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    child: SingleChildScrollView(
                      physics:
                          const NeverScrollableScrollPhysics(), // 스크롤 기능 비활성화
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 이력서 작성 위젯
                          ResumeWidget(color: primaryColor),
                          // 면접 연습 위젯
                          InterviewWidget(color: primaryColor),
                          // 면접 보고서 위젯
                          ReportWidget(color: primaryColor),
                        ],
                      ),
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
