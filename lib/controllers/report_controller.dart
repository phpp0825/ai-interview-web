import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../views/resume_view.dart';

class ReportController extends ChangeNotifier {
  // 의존성
  final ReportService _reportService = ReportService();

  // 상태 변수
  ReportModel? _reportData;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isLoadingReports = false;
  List<Map<String, dynamic>> _reportList = [];

  // Getters
  ReportModel? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  bool get isVideoInitialized => _isVideoInitialized;
  bool get isLoadingReports => _isLoadingReports;
  List<Map<String, dynamic>> get reportList => _reportList;

  // 생성자
  ReportController() {
    loadReportList();
  }

  // 리포트 목록 로드
  Future<void> loadReportList() async {
    try {
      _isLoadingReports = true;
      _error = null;
      notifyListeners();

      _reportList = await _reportService.getCurrentUserReportSummaries();

      _isLoadingReports = false;
      notifyListeners();
    } catch (e) {
      _error = '리포트 목록을 불러오는데 실패했습니다: $e';
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  // 리포트 데이터 로드
  Future<void> loadReport(String reportId) async {
    try {
      _setLoading(true);
      _setError(null);

      // 서비스를 통해 데이터 로드
      final report = await _reportService.getReport(reportId);
      _reportData = report;

      // 비디오 플레이어 초기화
      await _initializeVideoPlayer();

      _setLoading(false);
    } catch (e) {
      _setError('리포트를 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
  }

  // 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer() async {
    if (_reportData?.videoUrl == null) return;

    try {
      _videoPlayerController =
          VideoPlayerController.network(_reportData!.videoUrl);
      await _videoPlayerController!.initialize();
      _isVideoInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('비디오를 불러오는데 실패했습니다: $e');
    }
  }

  // 특정 시간으로 이동
  void seekToTime(int seconds) {
    if (_videoPlayerController == null) return;
    _videoPlayerController!.seekTo(Duration(seconds: seconds));
  }

  // 시간 포맷팅 유틸리티 함수
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 날짜 포맷팅 유틸리티 함수
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return '날짜 정보 없음';

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        // Firestore 타임스탬프 변환
        date = (timestamp as Timestamp).toDate();
      }

      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 정보 오류';
    }
  }

  // 리포트 삭제
  Future<bool> deleteReport(String reportId) async {
    try {
      _setLoading(true);
      final result = await _reportService.deleteReport(reportId);
      if (result) {
        // 삭제 성공 시 목록에서도 제거
        _reportList.removeWhere((report) => report['id'] == reportId);
      }
      _setLoading(false);
      notifyListeners();
      return result;
    } catch (e) {
      _setError('리포트 삭제 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
    }
  }

  // 리포트 목록 새로고침
  Future<void> refreshReportList() async {
    await loadReportList();
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
              Icon(Icons.assessment, color: Colors.blue),
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

  // 이력서 화면으로 이동
  void navigateToResumeView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResumeView(),
      ),
    ).then((_) {
      // 이력서 작성 후 돌아왔을 때 목록 새로고침
      refreshReportList();
    });
  }

  // 로딩 상태 변경
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
