import '../../models/report_model.dart';

/// 리포트 레포지토리 인터페이스
///
/// 리포트 데이터 액세스를 위한 인터페이스입니다.
abstract class IReportRepository {
  /// 현재 사용자의 리포트 요약 목록을 가져옵니다.
  Future<List<Map<String, dynamic>>> getCurrentUserReportSummaries();

  /// 특정 리포트 정보를 가져옵니다.
  Future<ReportModel> getReport(String reportId);

  /// 리포트를 저장합니다.
  Future<String> saveReport(Map<String, dynamic> reportData);

  /// 리포트 상태를 업데이트합니다.
  Future<bool> updateReportStatus(String reportId, String status);

  /// 리포트 비디오 URL을 업데이트합니다.
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl);

  /// 리포트를 삭제합니다.
  Future<bool> deleteReport(String reportId);
}
