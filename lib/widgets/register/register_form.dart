import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth/auth_service.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 포커스 노드 관리
  final Map<String, FocusNode> _focusNodes = {
    'name': FocusNode(),
    'email': FocusNode(),
    'password': FocusNode(),
    'confirmPassword': FocusNode(),
  };

  @override
  void dispose() {
    // 컨트롤러 해제
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // 포커스 노드 해제
    _focusNodes.forEach((_, node) => node.dispose());

    super.dispose();
  }

  // 회원가입 처리
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);

        // Firebase 인증으로 회원가입
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          name: _nameController.text.trim(),
        );

        // 회원가입 성공 후 홈 화면으로 이동
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원가입 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 다음 입력 필드로 포커스 이동
  void _fieldFocusChange(String current, String next) {
    _focusNodes[current]?.unfocus();
    FocusScope.of(context).requestFocus(_focusNodes[next]);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 영어 안내 메시지
          Text(
            'Create a new account to get started',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 50),

          // 이름 입력 필드
          _buildInputField(
            controller: _nameController,
            focusNode: _focusNodes['name']!,
            label: '이름',
            hint: '이름 입력',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _fieldFocusChange('name', 'email'),
            validator: (value) =>
                (value?.isEmpty ?? true) ? '이름을 입력해주세요.' : null,
          ),
          const SizedBox(height: 30),

          // 이메일 입력 필드
          _buildInputField(
            controller: _emailController,
            focusNode: _focusNodes['email']!,
            label: '이메일',
            hint: '이메일 주소 입력',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _fieldFocusChange('email', 'password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return '이메일을 입력해주세요.';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!)) {
                return '유효한 이메일 주소를 입력해주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),

          // 비밀번호 입력 필드
          _buildPasswordField(
            controller: _passwordController,
            focusNode: _focusNodes['password']!,
            label: '비밀번호',
            hint: '비밀번호 입력 (6자 이상)',
            isVisible: _isPasswordVisible,
            onVisibilityChanged: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            onFieldSubmitted: (_) =>
                _fieldFocusChange('password', 'confirmPassword'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return '비밀번호를 입력해주세요.';
              }
              if ((value?.length ?? 0) < 6) {
                return '비밀번호는 6자 이상이어야 합니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),

          // 비밀번호 확인 입력 필드
          _buildPasswordField(
            controller: _confirmPasswordController,
            focusNode: _focusNodes['confirmPassword']!,
            label: '비밀번호 확인',
            hint: '비밀번호 다시 입력',
            isVisible: _isConfirmPasswordVisible,
            onVisibilityChanged: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return '비밀번호 확인을 입력해주세요.';
              }
              if (value != _passwordController.text) {
                return '비밀번호가 일치하지 않습니다.';
              }
              return null;
            },
          ),

          // 에러 메시지
          if (_errorMessage != null) _buildErrorMessage(),

          const SizedBox(height: 50),

          // 회원가입 버튼
          _buildSignUpButton(),
        ],
      ),
    );
  }

  // 일반 입력 필드 생성
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[500],
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.deepPurple,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
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
          borderSide: const BorderSide(color: Colors.deepPurple),
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
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }

  // 비밀번호 입력 필드 생성
  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isVisible,
    required Function() onVisibilityChanged,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[500],
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.deepPurple,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey[600],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: onVisibilityChanged,
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
          borderSide: const BorderSide(color: Colors.deepPurple),
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
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }

  // 에러 메시지 위젯
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

  // 회원가입 버튼
  Widget _buildSignUpButton() {
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
                  '회원가입',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }
}
