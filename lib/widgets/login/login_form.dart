import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth/auth_service.dart';
import '../../views/home_view.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 이메일/비밀번호 로그인 처리
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 로그인 처리
        final authService = Provider.of<AuthService>(
          context,
          listen: false,
        );

        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 로그인 성공 처리
        if (authService.currentUser != null) {
          print('이메일 로그인 성공: ${authService.currentUser!.uid}');

          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 게스트 로그인 처리
  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 게스트 로그인
      final authService = Provider.of<AuthService>(
        context,
        listen: false,
      );

      await authService.signInAnonymously();

      // 로그인 성공 처리
      if (authService.currentUser != null) {
        print('게스트 로그인 성공: ${authService.currentUser!.uid}');

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 자동 로그인 확인
  void _checkExistingUser() {
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;

    if (currentUser != null) {
      print('자동 로그인: ${currentUser.uid}');
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  // 구글 로그인 처리
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 구글 로그인
      final authService = Provider.of<AuthService>(
        context,
        listen: false,
      );

      await authService.signInWithGoogle();

      // 로그인 성공 처리
      if (authService.currentUser != null) {
        print('구글 로그인 성공: ${authService.currentUser!.uid}');

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로그인 메시지
          Text(
            'Welcome back! Please sign in to continue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 50),

          // 이메일 입력 필드
          _buildEmailField(),
          const SizedBox(height: 30),

          // 비밀번호 입력 필드
          _buildPasswordField(),

          // 에러 메시지 표시
          if (_errorMessage != null) _buildErrorMessage(),

          const SizedBox(height: 50),

          // 로그인 버튼
          _buildSignInButton(),

          const SizedBox(height: 20),

          // 게스트 로그인 버튼
          _buildGuestButton(),

          const SizedBox(height: 20),

          // 구글 로그인 버튼
          _buildGoogleButton(),
        ],
      ),
    );
  }

  // 이메일 입력 필드 생성
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Enter email or Phone number',
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.blueGrey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[50]!),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[50]!),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력해주세요.';
        }
        return null;
      },
    );
  }

  // 비밀번호 입력 필드 생성
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[500],
        ),
        counterText: 'Forgot password?',
        counterStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.blueGrey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[50]!),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[50]!),
          borderRadius: BorderRadius.circular(15),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요.';
        }
        return null;
      },
    );
  }

  // 에러 메시지 표시 위젯
  Widget _buildErrorMessage() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              color: Colors.red[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // 로그인 버튼 생성
  Widget _buildSignInButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple[100]!,
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.deepPurple[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }

  // 게스트 로그인 버튼 생성
  Widget _buildGuestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInAsGuest,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '처리 중...',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Text(
                '게스트로 계속하기',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  // 구글 로그인 버튼 생성
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.login,
              size: 24,
              color: Colors.deepPurple,
            );
          },
        ),
        label: Text(
          'Google로 로그인',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          foregroundColor: Colors.grey[700],
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
