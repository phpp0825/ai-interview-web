import '../../../models/resume_model.dart';

/// 이력서 서비스 인터페이스
///
/// 이력서 관련 기능을 제공하는 서비스의 인터페이스입니다.
abstract class IResumeService {
  /// 현재 사용자의 이력서 목록 가져오기
  ///
  /// 현재 로그인한 사용자의 모든 이력서를 가져옵니다.
  Future<List<Map<String, dynamic>>> getCurrentUserResumeList();

  /// 현재 사용자의 대표 이력서 가져오기
  ///
  /// 현재 로그인한 사용자의 대표 이력서를 가져옵니다.
  /// 대표 이력서가 없는 경우 가장 최근에 생성된 이력서를 반환합니다.
  Future<ResumeModel?> getCurrentUserResume();

  /// 이력서 가져오기
  ///
  /// [resumeId]에 해당하는 이력서를 가져옵니다.
  Future<ResumeModel?> getResume(String resumeId);

  /// 이력서 생성하기
  ///
  /// 새로운.이력서를 생성합니다.
  Future<ResumeModel?> createResume(Map<String, dynamic> resumeData);

  /// 이력서 업데이트하기
  ///
  /// [resumeId]에 해당하는 이력서를 업데이트합니다.
  Future<bool> updateResume(String resumeId, Map<String, dynamic> resumeData);

  /// 이력서 삭제하기
  ///
  /// [resumeId]에 해당하는 이력서를 삭제합니다.
  Future<bool> deleteResume(String resumeId);

  /// 이력서를 Firestore에 저장
  ///
  /// [resume] 객체를 현재 로그인된 사용자의 이력서로 저장합니다.
  Future<bool> saveResumeToFirestore(ResumeModel resume);
}
