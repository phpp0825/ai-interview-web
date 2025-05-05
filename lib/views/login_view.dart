import 'package:flutter/material.dart';
import '../widgets/login/login_form.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _showLoginForm = true;

  void _toggleForm() {
    setState(() {
      _showLoginForm = !_showLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoginForm) {
      return RegisterView(
        onLoginPressed: _toggleForm,
      );
    }

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

                      // 오른쪽 부분: 로그인 폼
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
                              child: LoginForm(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildRegisterLink(),
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
            'Sign In to\nAinterview',
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
          'Sign in to enjoy all our features and services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.deepPurple[700],
          ),
        ),
        const SizedBox(height: 25),
        // 환영 이미지
        Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/welcome_image.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // 회원가입 링크 위젯
  Widget _buildRegisterLink() {
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
            "계정이 없으신가요?",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleForm,
            child: Text(
              "지금 가입하기",
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
