import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';

/// 홈 컨트롤러
///
/// 홈 화면의 상태 및 동작을 관리합니다.
class HomeController extends ChangeNotifier {
  // 탭 관련 상태
  int _currentIndex = 0;
  final List<String> _tabTitles = ['홈', '리포트', '프로필'];

  // 인증 서비스
  final AuthService _authService;

  int get currentIndex => _currentIndex;
  List<String> get tabTitles => _tabTitles;

  // 생성자에서 AuthService 주입
  HomeController(this._authService);

  // 현재 탭 인덱스 설정
  void setCurrentIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // 로그아웃 처리
  Future<void> signOut() async {
      await _authService.signOut();
  }

  // 이력서 화면으로 이동
  void navigateToResumeView(BuildContext context) {
    Navigator.pushNamed(context, '/resume');
  }

  // 리포트 화면으로 이동
  void navigateToReportView(BuildContext context) {
    Navigator.pushNamed(context, '/report-list');
  }

  // 인터뷰 시작 다이얼로그 표시
  void showInterviewStartDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('면접 시작'),
        content: const Text('면접을 시작하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: primaryColor,
            ),
            child: const Text('시작'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/livestream');
            },
          ),
        ],
      ),
    );
  }
}
