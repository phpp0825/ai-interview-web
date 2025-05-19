import '../../models/resume_model.dart';
import '../../repositories/resume/resume_repository_interface.dart';
import 'interfaces/resume_service_interface.dart';

/// 이력서 관련 서비스 기능을 제공하는 클래스
///
/// 이 서비스는 이력서 관련 비즈니스 로직을 담당합니다.
/// Repository를 통해 데이터를 관리합니다.
class ResumeService implements IResumeService {
  final IResumeRepository _repository;

  ResumeService(this._repository);

  /// 이력서를 Firestore에 저장
  ///
  /// [resume] 객체를 현재 로그인된 사용자의 이력서로 저장합니다.
  Future<bool> saveResumeToFirestore(ResumeModel resume) async {
    try {
      // 타임스탬프가 없는 경우 생성
      if (resume.resume_id.isEmpty) {
        resume.resume_id = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // 레포지토리를 통해 저장
      await _repository.saveResume(resume);
      return true;
    } catch (e) {
      print('이력서 저장 중 오류 발생: $e');
      return false;
    }
  }

  /// 리포트 생성을 위한 이력서 Firestore 저장
  ///
  /// [resume] 데이터를 저장하고 ID를 반환합니다.
  Future<String> saveForReport(ResumeModel resume) async {
    try {
      // 이력서 저장
      await saveResumeToFirestore(resume);

      // 저장된 이력서의 ID 반환
      return resume.resume_id;
    } catch (e) {
      print('리포트용 이력서 저장 중 오류 발생: $e');
      throw Exception('리포트용 이력서를 저장하는데 실패했습니다: $e');
    }
  }

  @override
  Future<ResumeModel?> getResume(String resumeId) async {
    try {
      // Repository에서 구현된 메서드만 사용하여 이력서 조회
      return await _repository.getResume(resumeId);
    } catch (e) {
      print('이력서 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<ResumeModel?> getCurrentUserResume() async {
    try {
      return await _repository.getCurrentUserResume();
    } catch (e) {
      print('현재 사용자 이력서 조회 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteResume(String resumeId) async {
    try {
      return await _repository.deleteResume(resumeId);
    } catch (e) {
      print('이력서 삭제 중 오류 발생: $e');
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurrentUserResumeList() async {
    try {
      return await _repository.getCurrentUserResumeList();
    } catch (e) {
      print('사용자 이력서 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  @override
  Future<ResumeModel?> createResume(Map<String, dynamic> resumeData) async {
    try {
      // 교육 정보 객체 생성
      final education = Education(
        school: resumeData['school'] ?? '',
        major: resumeData['major'] ?? '',
        degree: resumeData['degree'] ?? '학사',
        startDate: resumeData['educationStartDate'] ?? '',
        endDate: resumeData['educationEndDate'] ?? '',
        gpa: resumeData['gpa'] ?? '',
        totalGpa: resumeData['totalGpa'] ?? '4.5',
      );

      // 자기 소개 객체 생성
      final selfIntroduction = SelfIntroduction(
        motivation: resumeData['motivation'],
        strength: resumeData['strength'],
      );

      // 자격증 목록 생성
      List<Certificate> certificates = [];
      if (resumeData['certificates'] != null &&
          resumeData['certificates'] is List) {
        certificates = (resumeData['certificates'] as List)
            .map((cert) => Certificate.fromJson(cert))
            .toList();
      }

      // ResumeModel 객체 생성
      final resume = ResumeModel(
        resume_id: '',
        field: resumeData['field'] ?? '웹 개발',
        position: resumeData['position'] ?? '백엔드 개발자',
        experience: resumeData['experience'] ?? '신입',
        interviewTypes: resumeData['interviewTypes'] != null
            ? List<String>.from(resumeData['interviewTypes'])
            : ['직무면접'],
        certificates: certificates,
        education: education,
        selfIntroduction: selfIntroduction,
      );

      // Firestore에 저장
      await saveResumeToFirestore(resume);

      return resume;
    } catch (e) {
      print('이력서 생성 중 오류 발생: $e');
      return null;
    }
  }

  @override
  Future<bool> updateResume(
      String resumeId, Map<String, dynamic> resumeData) async {
    try {
      // 기존 이력서 가져오기
      final existingResume = await getResume(resumeId);
      if (existingResume == null) return false;

      // 교육 정보 객체 생성 (기존 데이터가 있으면 유지)
      final education = Education(
        school: resumeData['school'] ?? existingResume.education.school,
        major: resumeData['major'] ?? existingResume.education.major,
        degree: resumeData['degree'] ?? existingResume.education.degree,
        startDate: resumeData['educationStartDate'] ??
            existingResume.education.startDate,
        endDate:
            resumeData['educationEndDate'] ?? existingResume.education.endDate,
        gpa: resumeData['gpa'] ?? existingResume.education.gpa,
        totalGpa: resumeData['totalGpa'] ?? existingResume.education.totalGpa,
      );

      // 자기 소개 객체 생성 (기존 데이터가 있으면 유지)
      final selfIntroduction = SelfIntroduction(
        motivation: resumeData['motivation'] ??
            existingResume.selfIntroduction.motivation,
        strength:
            resumeData['strength'] ?? existingResume.selfIntroduction.strength,
      );

      // 자격증 목록 갱신
      List<Certificate> certificates = existingResume.certificates;
      if (resumeData['certificates'] != null &&
          resumeData['certificates'] is List) {
        certificates = (resumeData['certificates'] as List)
            .map((cert) => Certificate.fromJson(cert))
            .toList();
      }

      // 이력서 객체 업데이트
      final updatedResume = ResumeModel(
        resume_id: resumeId,
        field: resumeData['field'] ?? existingResume.field,
        position: resumeData['position'] ?? existingResume.position,
        experience: resumeData['experience'] ?? existingResume.experience,
        interviewTypes: resumeData['interviewTypes'] != null
            ? List<String>.from(resumeData['interviewTypes'])
            : existingResume.interviewTypes,
        certificates: certificates,
        education: education,
        selfIntroduction: selfIntroduction,
      );

      // Firestore에 저장
      return await saveResumeToFirestore(updatedResume);
    } catch (e) {
      print('이력서 업데이트 중 오류 발생: $e');
      return false;
    }
  }
}
