import 'package:flutter/material.dart';
import '../widgets/register/register_form.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback onLoginPressed;

  const RegisterView({
    super.key,
    required this.onLoginPressed,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  Widget build(BuildContext context) {
    // 반응형 레이아웃을 위한 화면 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.08 : 16.0;

    // 반응형 크기 조정 - 두 화면에서 동일한 너비 사용
    final double leftWidth = screenWidth > 1000 ? 500 : 450;
    final double rightWidth = screenWidth > 1000 ? 500 : 450;
    final double formMinHeight = 520.0; // 폼 최소 높이 설정
    final double spacing = screenWidth > 1000 ? 100 : 60;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          Image.asset(
            'assets/images/violet-watercolor-texture-background.jpg',
            fit: BoxFit.cover,
          ),

          // 메인 콘텐츠
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: 40,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      // 왼쪽 부분: 제목
                      SizedBox(
                        width: leftWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 25.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGradientTitle(
                                fontSize: screenWidth > 800 ? 45 : 35,
                                screenHeight: screenHeight,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // 오른쪽 부분: 회원가입 폼
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 30),
                          Container(
                            width: rightWidth,
                            constraints: BoxConstraints(
                              minHeight: formMinHeight,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(25.0),
                              child: RegisterForm(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLoginLink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 그라데이션 타이틀 생성
  Widget _buildGradientTitle({required double fontSize, double? screenHeight}) {
    // 화면 높이에 맞게 이미지 크기 조정
    final imageHeight = screenHeight != null
        ? screenHeight * 0.5 // 화면 높이의 50%
        : 600.0; // 기본값

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 그라데이션 효과가 적용된 제목 텍스트
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.deepPurple,
                Colors.deepPurple.shade300,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'Create Your\nAccount',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),
        // 부제목
        Text(
          'Join us today and get started with your new account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.deepPurple[700],
          ),
        ),
        const SizedBox(height: 25),
        // 회원가입 이미지
        Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/register_image.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // 로그인 링크 위젯
  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "계정이 있으신가요?",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onLoginPressed,
            child: Text(
              "로그인하기",
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
