import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/resume_service.dart';
import '../views/resume_view.dart';
import '../views/interview_view.dart';
import '../views/report_view.dart';

class HomeController extends ChangeNotifier {
  // 서비스 인스턴스
  final FirebaseService _firebaseService;
  final ResumeService _resumeService = ResumeService();

  // 상태 변수
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _firebaseService.currentUser;

  // 생성자
  HomeController(this._firebaseService);

  // 로그아웃 처리
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      await _firebaseService.signOut();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('로그아웃 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
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
      MaterialPageRoute(builder: (context) => const InterviewView()),
    );
  }

  // 리포트 화면으로 이동
  void navigateToReportView(BuildContext context) {
    Navigator.pushNamed(context, '/report-list');
  }

  // 면접 시작 전 다이얼로그 표시
  void showInterviewStartDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('면접 시작하기'),
          content: const Text(
            '면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서를 작성하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToInterviewView(context);
              },
              child: const Text('이력서 없이 진행'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                navigateToResumeView(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 1,
                side: BorderSide(color: primaryColor),
              ),
              child: const Text('이력서 작성하기'),
            ),
          ],
        );
      },
    );
  }

  // 리포트 생성 다이얼로그 표시
  void showCreateReportDialog(BuildContext context) {
    showDialog(
      context: context,
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
