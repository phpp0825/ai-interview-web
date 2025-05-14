import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth/auth_service.dart';
import '../services/resume/resume_service.dart';
import '../views/resume_view.dart';
import '../views/report_view.dart';
import '../views/http_interview_view.dart';

/// 홈 화면 컨트롤러
///
/// 홈 화면에서 필요한 데이터 관리 및 비즈니스 로직을 처리합니다.
class HomeController extends ChangeNotifier {
  // 의존성
  final AuthService _authService;
  final ResumeService _resumeService = ResumeService();

  // 상태 변수
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;

  // 생성자
  HomeController(this._authService);

  // 로그아웃 메서드
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 이력서 화면으로 이동하는 기능
  void navigateToResumeView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResumeView(),
      ),
    );
  }

  // 면접 화면으로 이동하는 기능
  void navigateToInterviewView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HttpInterviewView()),
    );
  }

  // 리포트 화면으로 이동
  void navigateToReportView(BuildContext context) {
    Navigator.pushNamed(context, '/report-list');
  }

  // 면접 시작 메서드 - 이력서 확인 후 면접 진행
  void showInterviewStartDialog(
      BuildContext context, Color primaryColor) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('이력서 정보 확인 중...'),
              ],
            ),
          );
        },
      );

      // 현재 사용자의 이력서 확인
      final existingResume = await _resumeService.getCurrentUserResume();

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (existingResume != null) {
        // 이력서가 있으면 면접 화면으로 이동
        if (context.mounted) {
          navigateToInterviewView(context);
        }
      } else {
        // 이력서가 없으면 이력서 작성 안내 다이얼로그
        if (context.mounted) {
          _showResumeRequiredDialog(context, primaryColor);
        }
      }
    } catch (e) {
      // 오류 발생 시 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이력서 정보 확인 중 오류가 발생했습니다: $e')),
        );
      }
      _setError('이력서 확인 중 오류: $e');
    }
  }

  // 이력서가 필요하다는 다이얼로그
  void _showResumeRequiredDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('이력서 필요'),
        content: const Text('면접을 진행하기 위해서는 이력서 정보가 필요합니다. 먼저 이력서를 작성해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 취소
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 이력서 작성 페이지로 이동
              navigateToResumeView(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('이력서 작성하기'),
          ),
        ],
      ),
    );
  }

  // 리포트 생성 다이얼로그 표시
  void showCreateReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.blue),
              const SizedBox(width: 10),
              const Text('새 리포트 생성'),
            ],
          ),
          content: const Text(
            '새로운 면접 리포트를 생성하시겠습니까?\n이력서 정보가 필요합니다.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('이력서로 이동'),
              onPressed: () {
                Navigator.of(context).pop();
                navigateToResumeView(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 상태 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
