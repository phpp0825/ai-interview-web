import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/resume_model.dart';

/// 이력서 레포지토리 인터페이스
///
/// 이력서 데이터 액세스를 위한 인터페이스입니다.
abstract class IResumeRepository {
  /// 이력서를 Firestore에 저장합니다.
  Future<String> saveResume(ResumeModel resume);

  /// 이력서를 조회합니다.
  Future<ResumeModel?> getResume(String resumeId);

  /// 현재 사용자의 이력서를 조회합니다.
  Future<ResumeModel?> getCurrentUserResume();

  /// 현재 사용자의 이력서 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getCurrentUserResumeList();

  /// 이력서를 삭제합니다.
  Future<bool> deleteResume(String resumeId);

  /// 현재 로그인한 사용자 정보를 반환합니다.
  dynamic getCurrentUser();

  /// Firestore 컬렉션에 대해 쿼리를 실행합니다.
  Future<List<DocumentSnapshot>> query(
      Future<QuerySnapshot> Function(CollectionReference) queryBuilder);

  /// 인덱스가 있을 때와 없을 때 모두 사용 가능한 쿼리를 실행합니다.
  Future<List<DocumentSnapshot>> queryWithIndexFallback(
      String field, dynamic value,
      {String? orderField, bool descending = false});

  /// 문서를 가져옵니다.
  Future<Map<String, dynamic>?> getDocument(String documentId);

  /// 문서를 삭제합니다.
  Future<void> deleteDocument(String documentId);
}
