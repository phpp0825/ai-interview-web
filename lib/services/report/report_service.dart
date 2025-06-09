import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../repositories/report/report_repository_interface.dart';
import '../../core/di/service_locator.dart';

/// 리포트 관련 비즈니스 로직을 담당하는 서비스
///
/// 이 서비스는 리포트 데이터의 CRUD 작업과 관련된 모든 로직을 처리합니다.
/// 컨트롤러에서 UI 상태 관리와 비즈니스 로직을 분리하여
/// 코드의 재사용성과 유지보수성을 높입니다.
class ReportService {
  final IReportRepository _reportRepository;

  ReportService() : _reportRepository = serviceLocator<IReportRepository>();

  /// 사용자의 모든 리포트 목록을 가져옵니다
  ///
  /// 반환값: 리포트 요약 정보 리스트
  /// 예외 발생 시 상위 레이어에서 처리하도록 throw 합니다
  Future<List<Map<String, dynamic>>> getReportList() async {
    try {
      print('📋 ReportService: 리포트 목록 조회 시작');
      final reportList =
          await _reportRepository.getCurrentUserReportSummaries();
      print('📋 ReportService: 리포트 목록 조회 완료 (${reportList.length}개)');
      return reportList;
    } catch (e) {
      print('❌ ReportService: 리포트 목록 조회 실패 - $e');
      throw Exception('리포트 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 특정 리포트의 상세 데이터를 가져옵니다
  ///
  /// [reportId]: 조회할 리포트 ID
  /// 반환값: 리포트 상세 데이터 또는 null
  Future<ReportModel?> getReportDetail(String reportId) async {
    try {
      print('📋 ReportService: 리포트 상세 조회 시작 - $reportId');
      final report = await _reportRepository.getReport(reportId);

      if (report != null) {
        print('📋 ReportService: 리포트 상세 조회 완료');
        print('   - 제목: ${report.title}');
        print('   - 점수: ${report.score}');
        print('   - 질문-답변 개수: ${report.questionAnswers?.length ?? 0}');
      } else {
        print('⚠️ ReportService: 리포트를 찾을 수 없음 - $reportId');
      }

      return report;
    } catch (e) {
      print('❌ ReportService: 리포트 상세 조회 실패 - $e');
      throw Exception('리포트를 불러올 수 없습니다: $e');
    }
  }

  /// 면접 완료 후 새 리포트를 생성합니다
  ///
  /// [interviewId]: 면접 ID
  /// [resumeId]: 이력서 ID
  /// [resumeData]: 이력서 데이터
  /// 반환값: 생성된 리포트 ID 또는 null
  Future<String?> createInterviewReport(String interviewId, String resumeId,
      Map<String, dynamic> resumeData) async {
    try {
      print('📋 ReportService: 면접 리포트 생성 시작');
      print('   - 면접 ID: $interviewId');
      print('   - 이력서 ID: $resumeId');

      // Repository가 createReport 메소드를 제공한다면 사용
      // 현재는 해당 메소드가 없으므로 placeholder
      // final report = await _reportRepository.createReport(
      //   interviewId: interviewId,
      //   resumeId: resumeId,
      //   resumeData: resumeData,
      // );

      print('📋 ReportService: 면접 리포트 생성 완료');
      return null; // report?.id;
    } catch (e) {
      print('❌ ReportService: 면접 리포트 생성 실패 - $e');
      throw Exception('면접 보고서 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 리포트 상태를 업데이트합니다
  ///
  /// [reportId]: 리포트 ID
  /// [status]: 새로운 상태값
  /// 반환값: 성공 여부
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      print('📋 ReportService: 리포트 상태 업데이트 시작');
      print('   - 리포트 ID: $reportId');
      print('   - 새 상태: $status');

      final result =
          await _reportRepository.updateReportStatus(reportId, status);

      if (result) {
        print('✅ ReportService: 리포트 상태 업데이트 성공');
      } else {
        print('❌ ReportService: 리포트 상태 업데이트 실패');
      }

      return result;
    } catch (e) {
      print('❌ ReportService: 리포트 상태 업데이트 중 예외 - $e');
      throw Exception('보고서 상태 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  /// 리포트의 비디오 URL을 업데이트합니다
  ///
  /// [reportId]: 리포트 ID
  /// [videoUrl]: 새로운 비디오 URL
  /// 반환값: 성공 여부
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) async {
    try {
      print('📋 ReportService: 리포트 비디오 URL 업데이트 시작');
      print('   - 리포트 ID: $reportId');
      print('   - 비디오 URL 길이: ${videoUrl.length}');

      final result =
          await _reportRepository.updateReportVideoUrl(reportId, videoUrl);

      if (result) {
        print('✅ ReportService: 리포트 비디오 URL 업데이트 성공');
      } else {
        print('❌ ReportService: 리포트 비디오 URL 업데이트 실패');
      }

      return result;
    } catch (e) {
      print('❌ ReportService: 리포트 비디오 URL 업데이트 중 예외 - $e');
      throw Exception('보고서 비디오 URL 업데이트 중 오류가 발생했습니다: $e');
    }
  }

  /// 리포트를 삭제합니다
  ///
  /// [reportId]: 삭제할 리포트 ID
  /// 반환값: 성공 여부
  Future<bool> deleteReport(String reportId) async {
    try {
      print('🗑️ ReportService: 리포트 삭제 시작 - $reportId');

      final result = await _reportRepository.deleteReport(reportId);

      if (result) {
        print('✅ ReportService: 리포트 삭제 성공');
      } else {
        print('❌ ReportService: 리포트 삭제 실패');
      }

      return result;
    } catch (e) {
      print('❌ ReportService: 리포트 삭제 중 예외 - $e');
      throw Exception('리포트 삭제 중 오류가 발생했습니다: $e');
    }
  }

  /// 날짜 포맷팅 유틸리티 함수
  ///
  /// [timestamp]: Firestore timestamp 또는 DateTime
  /// 반환값: 포맷된 날짜 문자열 (yyyy.MM.dd)
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
      print('❌ ReportService: 날짜 포맷팅 실패 - $e');
      return '날짜 정보 오류';
    }
  }

  /// 시간을 HH:MM:SS 형식으로 포맷팅합니다
  ///
  /// [seconds]: 초 단위 시간
  /// 반환값: 포맷된 시간 문자열
  String formatDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}";
  }

  /// 영상이 있는 첫 번째 질문의 인덱스를 찾습니다
  ///
  /// [questionAnswers]: 질문-답변 리스트
  /// 반환값: 영상이 있는 첫 번째 질문의 인덱스, 없으면 -1
  int findFirstQuestionWithVideo(List<QuestionAnswerModel>? questionAnswers) {
    if (questionAnswers == null || questionAnswers.isEmpty) {
      return -1;
    }

    for (int i = 0; i < questionAnswers.length; i++) {
      if (questionAnswers[i].videoUrl.isNotEmpty) {
        print('📹 ReportService: 영상이 있는 첫 번째 질문 찾음 - ${i + 1}번');
        return i;
      }
    }

    print('⚠️ ReportService: 영상이 있는 질문을 찾을 수 없음');
    return -1;
  }
}
