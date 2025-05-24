import 'package:flutter/material.dart';
import 'login_view.dart';

class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 800px 이상이면 데스크톱 모드로 처리
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          'Ainterview',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 높이에 따라 스크롤 여부 결정
          final minRequiredHeight = isDesktop ? 700 : 850;
          final bool needsScroll = constraints.maxHeight < minRequiredHeight;

          return Container(
            width: double.infinity,
            height: double.infinity,
            child: needsScroll
                ? SingleChildScrollView(
                    child: _buildMainContent(context, size, isDesktop),
                  )
                : _buildMainContent(context, size, isDesktop),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, Size size, bool isDesktop) {
    // 반응형 디자인을 위한 크기 설정
    final containerPadding = isDesktop
        ? EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 30)
        : EdgeInsets.symmetric(horizontal: 20, vertical: 20);

    final textWidth = isDesktop ? size.width * 0.35 : size.width * 0.8;
    final imageWidth = isDesktop ? size.width * 0.45 : size.width * 0.9;
    final spaceBetween = isDesktop ? 40.0 : 30.0;

    // 화면 크기에 따른 폰트 크기 조정
    final titleFontSize = isDesktop
        ? size.width > 1200
            ? 80.0
            : 60.0
        : 36.0;

    return Padding(
      padding: containerPadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isDesktop ? 30 : 10),

            // 데스크톱 레이아웃 (가로 배치)
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽: 텍스트 영역
                  Container(
                    width: textWidth,
                    constraints: BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 제목
                        Text(
                          'Ainterview',
                          style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade600,
                              height: 1.1),
                        ),
                        const SizedBox(height: 24),
                        // 설명 텍스트
                        Text(
                          'Get real-time feedback, improve your answers, and build confidence with smart, interactive mock interviews.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // 버튼
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginView()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                          ),
                          child: const Text(
                            'Learn More',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: spaceBetween),

                  // 오른쪽: 이미지 영역
                  Container(
                    width: imageWidth,
                    child: Image.asset(
                      'assets/images/landing_page.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              )
            // 모바일 레이아웃 (세로 배치)
            else
              Column(
                children: [
                  // 상단 이미지
                  Container(
                    width: imageWidth,
                    child: Image.asset(
                      'assets/images/landing_page.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 하단 텍스트 영역
                  Container(
                    width: textWidth,
                    alignment: Alignment.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 제목
                        Text(
                          'Ainterview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade600,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 설명 텍스트
                        Text(
                          'Get real-time feedback, improve your answers, and build confidence with smart, interactive mock interviews.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 버튼
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginView()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Learn More'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            SizedBox(height: isDesktop ? 40 : 20),
          ],
        ),
      ),
    );
  }
}
