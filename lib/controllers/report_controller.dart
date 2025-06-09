import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report/report_service.dart';
import '../services/report/video_player_service.dart';
import '../core/di/service_locator.dart';

/// 간단하고 깔끔한 리포트 컨트롤러
///
/// 이 컨트롤러는 UI 상태 관리만 담당하고, 비즈니스 로직은 서비스로 분리했습니다.
/// 이렇게 하면 코드가 더 깔끔해지고, 테스트하기 쉬워집니다.
class ReportController extends ChangeNotifier {
  // 서비스 의존성
  final ReportService _reportService;
  final VideoPlayerService _videoPlayerService;

  // UI 상태 변수들
  ReportModel? _reportData;
  bool _isLoading = true;
  String? _error;
  bool _isLoadingReports = false;
  List<Map<String, dynamic>> _reportList = [];
  bool _isCreatingReport = false;
  int _selectedQuestionIndex = 0;

  // Getters - UI에서 사용할 상태들
  ReportModel? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingReports => _isLoadingReports;
  List<Map<String, dynamic>> get reportList => _reportList;
  bool get isCreatingReport => _isCreatingReport;
  int get selectedQuestionIndex => _selectedQuestionIndex;

  // 비디오 관련 Getters - VideoPlayerService로부터 가져옴
  bool get isVideoInitialized => _videoPlayerService.isVideoInitialized;
  dynamic get videoPlayerController =>
      _videoPlayerService.videoPlayerController;
  String get currentVideoUrl => _videoPlayerService.currentVideoUrl;

  /// 생성자 - 서비스들을 주입받습니다
  ReportController()
      : _reportService = serviceLocator<ReportService>(),
        _videoPlayerService = serviceLocator<VideoPlayerService>() {
    _initializeController();
  }

  /// 컨트롤러 초기화
  Future<void> _initializeController() async {
    await loadReportList();
  }

  /// 리포트 목록 로드
  Future<void> loadReportList() async {
    try {
      _setLoadingReports(true);
      _clearError();

      print('📋 Controller: 리포트 목록 로드 시작');
      _reportList = await _reportService.getReportList();
      print('📋 Controller: 리포트 목록 로드 완료 (${_reportList.length}개)');

      _setLoadingReports(false);
    } catch (e) {
      print('❌ Controller: 리포트 목록 로드 실패 - $e');
      _setError('리포트 목록을 불러오는데 실패했습니다');
      _setLoadingReports(false);
    }
  }

  /// 리포트 상세 데이터 로드
  Future<void> loadReport(String reportId) async {
    try {
      _setLoading(true);
      _clearError();

      print('📋 Controller: 리포트 로드 시작 - $reportId');

      // 1. 리포트 데이터 로드
      _reportData = await _reportService.getReportDetail(reportId);

      if (_reportData == null) {
        _setError('리포트 데이터를 찾을 수 없습니다');
        _setLoading(false);
        return;
      }

      // 2. 첫 번째 영상이 있는 질문 찾기 및 비디오 초기화
      await _initializeFirstVideo();

      _setLoading(false);
      print('✅ Controller: 리포트 로드 완료');
    } catch (e) {
      print('❌ Controller: 리포트 로드 실패 - $e');
      _setError('리포트를 불러올 수 없습니다: $e');
      _setLoading(false);
    }
  }

  /// 첫 번째 영상이 있는 질문의 비디오를 초기화합니다
  Future<void> _initializeFirstVideo() async {
    if (_reportData?.questionAnswers == null) {
      _setError('면접 데이터가 없습니다');
      return;
    }

    // 영상이 있는 첫 번째 질문 찾기
    final firstVideoIndex =
        _reportService.findFirstQuestionWithVideo(_reportData!.questionAnswers);

    if (firstVideoIndex == -1) {
      _setError('답변 영상이 있는 질문이 없습니다');
      return;
    }

    // 선택된 질문 인덱스 설정
    _selectedQuestionIndex = firstVideoIndex;

    // 비디오 초기화
    final firstQuestion = _reportData!.questionAnswers![firstVideoIndex];
    await _initializeVideo(firstQuestion.videoUrl);
  }

  /// 비디오 플레이어 초기화
  Future<void> _initializeVideo(String videoUrl) async {
    try {
      print('🎬 Controller: 비디오 초기화 시작');

      await _videoPlayerService.initializeVideoPlayer(videoUrl);

      print('✅ Controller: 비디오 초기화 완료');
      notifyListeners();
    } catch (e) {
      print('❌ Controller: 비디오 초기화 실패 - $e');
      _setError('비디오를 로드할 수 없습니다');
    }
  }

  /// 질문 선택 - 다른 질문의 비디오로 전환
  Future<void> selectQuestion(int questionIndex) async {
    try {
      print('🎯 Controller: 질문 ${questionIndex + 1} 선택');

      // 유효성 검사
      if (_reportData?.questionAnswers == null ||
          questionIndex >= _reportData!.questionAnswers!.length) {
        print('❌ Controller: 잘못된 질문 인덱스 - $questionIndex');
        return;
      }

      final selectedQuestion = _reportData!.questionAnswers![questionIndex];

      // 선택된 질문 인덱스 업데이트
      _selectedQuestionIndex = questionIndex;
      notifyListeners();

      // 비디오 URL이 없으면 비디오 해제
      if (selectedQuestion.videoUrl.isEmpty) {
        print('📝 Controller: 질문 ${questionIndex + 1}에는 영상이 없음');
        await _videoPlayerService.disposeVideoPlayer();
        notifyListeners();
        return;
      }

      // 같은 비디오면 무시
      if (!_videoPlayerService.isVideoUrlChanged(selectedQuestion.videoUrl)) {
        print('🔄 Controller: 동일한 비디오 - 변경 없음');
        return;
      }

      // 새 비디오로 전환
      await _initializeVideo(selectedQuestion.videoUrl);

      print('✅ Controller: 질문 ${questionIndex + 1} 비디오 전환 완료');
    } catch (e) {
      print('❌ Controller: 질문 선택 중 오류 - $e');
      _setError('비디오 전환 중 오류가 발생했습니다');
    }
  }

  /// 영상 시간 이동 (Duration 기반)
  Future<void> seekToTime(Duration duration) async {
    await _videoPlayerService.seekToTime(duration);
  }

  /// 영상 시간 이동 (초 단위)
  Future<void> seekToTimeInSeconds(int seconds) async {
    await _videoPlayerService.seekToTimeInSeconds(seconds);
  }

  /// 면접 완료 후 보고서 생성
  Future<String?> createInterviewReport(String interviewId, String resumeId,
      Map<String, dynamic> resumeData) async {
    try {
      _setCreatingReport(true);

      final reportId = await _reportService.createInterviewReport(
          interviewId, resumeId, resumeData);

      // 리포트 목록 새로고침
      await loadReportList();

      _setCreatingReport(false);
      return reportId;
    } catch (e) {
      print('❌ Controller: 면접 보고서 생성 실패 - $e');
      _setError('면접 보고서 생성 중 오류가 발생했습니다');
      _setCreatingReport(false);
      return null;
    }
  }

  /// 보고서 상태 업데이트
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      _setLoading(true);

      final result = await _reportService.updateReportStatus(reportId, status);

      if (result) {
        await loadReportList();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      print('❌ Controller: 보고서 상태 업데이트 실패 - $e');
      _setError('보고서 상태 업데이트 중 오류가 발생했습니다');
      _setLoading(false);
      return false;
    }
  }

  /// 보고서 비디오 URL 업데이트
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) async {
    try {
      final result =
          await _reportService.updateReportVideoUrl(reportId, videoUrl);

      // 현재 로드된 보고서가 업데이트 대상과 같다면 다시 로드
      if (result && _reportData?.id == reportId) {
        await loadReport(reportId);
      }

      return result;
    } catch (e) {
      print('❌ Controller: 보고서 비디오 URL 업데이트 실패 - $e');
      _setError('보고서 비디오 URL 업데이트 중 오류가 발생했습니다');
      return false;
    }
  }

  /// 보고서 삭제
  Future<bool> deleteReport(String reportId) async {
    try {
      print('🗑️ Controller: 리포트 삭제 요청 - $reportId');

      final result = await _reportService.deleteReport(reportId);

      if (result) {
        print('✅ Controller: 삭제 성공 - 목록 새로고침');
        await loadReportList();
      }

      return result;
    } catch (e) {
      print('❌ Controller: 리포트 삭제 실패 - $e');
      return false;
    }
  }

  /// 리포트 목록 새로고침
  Future<void> refreshReportList() async {
    await loadReportList();
  }

  /// 날짜 포맷팅 (서비스로 위임)
  String formatDate(dynamic timestamp) {
    return _reportService.formatDate(timestamp);
  }

  /// 시간 포맷팅 (서비스로 위임)
  String formatDuration(int seconds) {
    return _reportService.formatDuration(seconds);
  }

  // === 상태 관리 헬퍼 메소드들 ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingReports(bool loading) {
    _isLoadingReports = loading;
    notifyListeners();
  }

  void _setCreatingReport(bool creating) {
    _isCreatingReport = creating;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 컨트롤러 리소스 해제
  @override
  void dispose() {
    print('🗑️ Controller: 리소스 해제 시작');
    _videoPlayerService.disposeVideoPlayer();
    super.dispose();
  }
}
