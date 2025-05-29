import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/report/interfaces/report_service_interface.dart';
import '../core/di/service_locator.dart';

/// 간단한 리포트 컨트롤러
/// 리포트 목록과 기본 데이터만 관리합니다.
class ReportController extends ChangeNotifier {
  // 의존성
  final IReportService _reportService;

  // 상태 변수
  ReportModel? _reportData;
  bool _isLoading = true;
  String? _error;
  bool _isLoadingReports = false;
  List<Map<String, dynamic>> _reportList = [];
  bool _isCreatingReport = false;

  // Getters
  ReportModel? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingReports => _isLoadingReports;
  List<Map<String, dynamic>> get reportList => _reportList;
  bool get isCreatingReport => _isCreatingReport;

  // 비디오 관련 getter들 (목업)
  bool get isVideoInitialized => false;
  dynamic get videoPlayerController => null;
  dynamic seekToTime(int time) {
    print('비디오를 $time초로 이동합니다');
  }

  dynamic formatDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}";
  }

  /// 생성자
  ReportController() : _reportService = serviceLocator<IReportService>() {
    loadReportList();
  }

  // 리포트 목록 로드
  Future<void> loadReportList() async {
    try {
      _isLoadingReports = true;
      _error = null;
      notifyListeners();

      _reportList = await _reportService.getCurrentUserReportList();

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

      _setLoading(false);
    } catch (e) {
      _setError('리포트를 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
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

  /// 면접 완료 후 보고서 생성
  ///
  /// 면접이 완료된 후 면접 데이터를 기반으로 보고서를 생성합니다.
  /// [interviewId]는 완료된 면접의 고유 식별자입니다.
  /// [resumeId]는 면접에 사용된 이력서의 고유 식별자입니다.
  /// [resumeData]는 면접에 사용된 이력서 데이터입니다.
  Future<String?> createInterviewReport(String interviewId, String resumeId,
      Map<String, dynamic> resumeData) async {
    try {
      _isCreatingReport = true;
      notifyListeners();

      // 서비스에 위임
      final report = await _reportService.createReport(
        interviewId: interviewId,
        resumeId: resumeId,
        resumeData: resumeData,
      );

      // 리포트 목록을 새로고침
      await loadReportList();

      _isCreatingReport = false;
      notifyListeners();
      return report?.id;
    } catch (e) {
      _setError('면접 보고서 생성 중 오류가 발생했습니다: $e');
      _isCreatingReport = false;
      notifyListeners();
      return null;
    }
  }

  /// 보고서 상태 업데이트
  ///
  /// [reportId] 보고서의 상태를 [status]로 업데이트합니다.
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      _setLoading(true);
      final result = await _reportService.updateReportStatus(reportId, status);

      // 상태 업데이트가 성공하면 목록 새로고침
      if (result) {
        await loadReportList();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('보고서 상태 업데이트 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 보고서 비디오 URL 업데이트
  ///
  /// [reportId] 보고서의 비디오 URL을 [videoUrl]로 업데이트합니다.
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) async {
    try {
      final result =
          await _reportService.updateReportVideoUrl(reportId, videoUrl);

      // 현재 로드된 보고서가 업데이트 대상과 같다면 비디오 플레이어 갱신
      if (result && _reportData != null && _reportData!.id == reportId) {
        // 보고서 데이터 새로 로드
        await loadReport(reportId);
      }

      return result;
    } catch (e) {
      _setError('보고서 비디오 URL 업데이트 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 보고서 삭제
  ///
  /// [reportId] 보고서를 삭제합니다.
  Future<bool> deleteReport(String reportId) async {
    try {
      _setLoading(true);
      final result = await _reportService.deleteReport(reportId);

      // 삭제가 성공하면 목록 새로고침
      if (result) {
        await loadReportList();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('보고서 삭제 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
    }
  }

  // 리포트 목록 새로고침
  Future<void> refreshReportList() async {
    await loadReportList();
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 메시지 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // 컨트롤러 리소스 해제
  @override
  void dispose() {
    super.dispose();
  }
}
