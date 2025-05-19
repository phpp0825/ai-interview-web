import '../../../models/report_model.dart';

/// 리포트 서비스 인터페이스
///
/// 리포트 관련 기능을 제공하는 서비스의 인터페이스입니다.
abstract class IReportService {
  /// 현재 사용자의 리포트 목록 가져오기
  ///
  /// 현재 로그인한 사용자의 모든 리포트를 가져옵니다.
  Future<List<Map<String, dynamic>>> getCurrentUserReportList();

  /// 리포트 가져오기
  ///
  /// [reportId]에 해당하는 리포트를 가져옵니다.
  Future<ReportModel?> getReport(String reportId);

  /// 리포트 생성하기
  ///
  /// 새로운 리포트를 생성합니다.
  Future<ReportModel?> createReport({
    required String interviewId,
    required String resumeId,
    required Map<String, dynamic> resumeData,
    String? videoUrl,
    String? audioUrl,
    String? analysis,
    String? feedback,
  });

  /// 리포트 삭제하기
  ///
  /// [reportId]에 해당하는 리포트를 삭제합니다.
  Future<bool> deleteReport(String reportId);

  /// 리포트 상태 업데이트
  ///
  /// [reportId]에 해당하는 리포트의 상태를 업데이트합니다.
  Future<bool> updateReportStatus(String reportId, String status);

  /// 리포트 비디오 URL 업데이트
  ///
  /// [reportId]에 해당하는 리포트의 비디오 URL을 업데이트합니다.
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl);

  /// 리포트 분석 결과 업데이트
  ///
  /// [reportId]에 해당하는 리포트의 분석 결과를 업데이트합니다.
  Future<bool> updateReportAnalysis(String reportId, String analysis);

  /// 리포트 피드백 업데이트
  ///
  /// [reportId]에 해당하는 리포트의 피드백을 업데이트합니다.
  Future<bool> updateReportFeedback(String reportId, String feedback);
}
