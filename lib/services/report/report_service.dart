import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/report_model.dart';
import '../../models/resume_model.dart';
import '../../repositories/report/report_repository_interface.dart';
import 'interfaces/report_service_interface.dart';

/// 리포트 관련 서비스 기능을 제공하는 클래스
///
/// 이 서비스는 리포트 관련 비즈니스 로직을 담당합니다.
/// Repository를 통해 데이터를 관리합니다.
class ReportService implements IReportService {
  final IReportRepository _repository;

  ReportService(this._repository);

  /// 새 리포트 생성
  ///
  /// [resume]를 기반으로 새 리포트를 생성합니다.
  Future<String> createReportFromResume(ResumeModel resume) async {
    try {
      // 리포트 데이터 준비
      final Map<String, dynamic> reportData = {
        'id': FirebaseFirestore.instance.collection('reports').doc().id,
        'title': '${resume.position} 면접 분석',
        'date': DateTime.now().toIso8601String(),
        'field': resume.field,
        'position': resume.position,
        'interviewType': resume.interviewTypes.isNotEmpty
            ? resume.interviewTypes.first
            : '직무면접',
        'resume_id': resume.resume_id,
        'duration': 0,
        'score': 0,
        'videoUrl': '',
        'timestamps': [],
        'speechSpeedData': [],
        'gazeData': [],
        'interviewState': 'pending',
        'experience': resume.experience,
      };

      // Repository를 통해 저장
      final reportId = await _repository.saveReport(reportData);
      return reportId;
    } catch (e) {
      print('리포트 생성 중 오류 발생: $e');
      throw Exception('리포트를 생성하는데 실패했습니다: $e');
    }
  }

  @override
  Future<ReportModel?> createReport({
    required String interviewId,
    required String resumeId,
    required Map<String, dynamic> resumeData,
    String? videoUrl,
    String? audioUrl,
    String? analysis,
    String? feedback,
  }) async {
    try {
      // 면접 타입 결정 (이력서 데이터에서 가져오거나 기본값 사용)
      final String interviewType = resumeData['interviewTypes'] != null &&
              (resumeData['interviewTypes'] as List).isNotEmpty
          ? (resumeData['interviewTypes'] as List).first
          : '직무면접';

      // 보고서 제목 생성
      String title = '${resumeData['position'] ?? '직무'} 면접 분석';
      if (resumeData['experience'] != null &&
          resumeData['experience'].toString().isNotEmpty) {
        title =
            '${resumeData['position'] ?? '직무'} ${resumeData['experience']} 면접 분석';
      }

      // 리포트 데이터 준비
      final Map<String, dynamic> reportData = {
        'id': FirebaseFirestore.instance.collection('reports').doc().id,
        'interview_id': interviewId,
        'resume_id': resumeId,
        'title': title,
        'date': DateTime.now().toIso8601String(),
        'field': resumeData['field'] ?? '',
        'position': resumeData['position'] ?? '',
        'interviewType': interviewType,
        'interviewState': 'processing',
        'score': 0,
        'duration': 0,
        'videoUrl': videoUrl ?? '',
        'audioUrl': audioUrl ?? '',
        'analysis': analysis ?? '',
        'feedback': feedback ?? '',
        'timestamps': [],
        'speechSpeedData': [],
        'gazeData': [],
      };

      // Repository를 통해 저장
      final reportId = await _repository.saveReport(reportData);
      return await getReport(reportId);
    } catch (e) {
      print('면접 리포트 생성 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<ReportModel?> getReport(String reportId) async {
    try {
      return await _repository.getReport(reportId);
    } catch (e) {
      print('리포트 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurrentUserReportList() async {
    try {
      return await _repository.getCurrentUserReportSummaries();
    } catch (e) {
      print('사용자 리포트 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 현재 사용자의 리포트 요약 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getCurrentUserReportSummaries() async {
    try {
      return await _repository.getCurrentUserReportSummaries();
    } catch (e) {
      print('사용자 리포트 요약 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 이력서 ID로 리포트 조회
  ///
  /// 특정 이력서의 리포트를 조회합니다.
  Future<ReportModel?> getReportByResumeId(String resumeId) async {
    try {
      // 이 기능은 현재 인터페이스에서 지원하지 않아 구현이 필요합니다
      // 임시적으로 null 반환
      return null;
    } catch (e) {
      print('이력서 ID로 리포트 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<bool> updateReportStatus(String reportId, String status) {
    return _repository.updateReportStatus(reportId, status);
  }

  /// 리포트 비디오 URL을 업데이트합니다.
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) {
    return _repository.updateReportVideoUrl(reportId, videoUrl);
  }

  @override
  Future<bool> deleteReport(String reportId) {
    return _repository.deleteReport(reportId);
  }

  @override
  Future<bool> updateReportAnalysis(String reportId, String analysis) async {
    try {
      // 간단하게 구현 (실제 앱에서는 별도의 메서드로 구현하는 것이 좋음)
      final reportData = {'analysis': analysis};

      // 리포트 ID와 분석 내용만 포함한 간소화된 데이터로 변경
      final simplifiedData = {'id': reportId, ...reportData};

      // 저장
      await _repository.saveReport(simplifiedData);
      return true;
    } catch (e) {
      print('리포트 분석 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  @override
  Future<bool> updateReportFeedback(String reportId, String feedback) async {
    try {
      // 간단하게 구현 (실제 앱에서는 별도의 메서드로 구현하는 것이 좋음)
      final reportData = {'feedback': feedback};

      // 리포트 ID와 피드백 내용만 포함한 간소화된 데이터로 변경
      final simplifiedData = {'id': reportId, ...reportData};

      // 저장
      await _repository.saveReport(simplifiedData);
      return true;
    } catch (e) {
      print('리포트 피드백 업데이트 중 오류 발생: $e');
      return false;
    }
  }
}
