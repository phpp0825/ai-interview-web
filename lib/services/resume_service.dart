import '../models/resume_model.dart';
import '../services/report_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 이력서 관련 서비스 기능을 제공하는 클래스
///
/// 이 서비스는 이력서 데이터의 저장, 조회, 삭제 기능과
/// 이력서 기반 리포트 생성 기능을 담당합니다.
/// FirestoreService를 통해 데이터를 관리합니다.
class ResumeService {
  // 컬렉션 이름 상수
  static const String _resumesCollection = 'resumes';

  // FirestoreService 인스턴스
  final FirestoreService _firestoreService = FirestoreService();

  // ReportService 인스턴스
  final ReportService _reportService = ReportService();

  /// 이력서를 Firestore에 저장
  ///
  /// [resume] 객체를 현재 로그인된 사용자의 이력서로 저장합니다.
  /// 기존 이력서가 있다면 완전히 새로운 내용으로 덮어씁니다.
  Future<bool> saveResumeToFirestore(ResumeModel resume) async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      // 현재 시간을 문서 ID로 사용하여 새 이력서 생성
      final String resumeId =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // 전체 데이터를 하나의 JSON 객체로 구성
      final Map<String, dynamic> jsonData = {
        'userId': userId,
        'data': resume.toJson(),
        'metadata': {
          'createdAt': FieldValue.serverTimestamp(),
        }
      };

      // Firestore에 새 이력서 저장
      await _firestoreService.setDocument(
        _resumesCollection,
        resumeId,
        jsonData,
      );

      return true;
    } catch (e) {
      print('이력서 저장 중 오류 발생: $e');
      throw Exception('이력서를 저장하는데 실패했습니다: $e');
    }
  }

  /// 리포트 생성 시 이력서를 Firestore에 저장하고 리포트 생성
  ///
  /// [resume] 데이터를 저장하고, 이를 기반으로 새 리포트를 생성합니다.
  Future<String> createReportWithResume(ResumeModel resume) async {
    try {
      // 1. 먼저 이력서 저장
      await saveResumeToFirestore(resume);

      // 2. ReportService를 통해 리포트 생성
      final String reportId = await _reportService.createReport(resume);

      return reportId;
    } catch (e) {
      print('리포트 생성 중 오류 발생: $e');
      throw Exception('리포트를 생성하는데 실패했습니다: $e');
    }
  }

  /// 이력서 데이터 파싱
  ///
  /// 문서 데이터에서 이력서 데이터를 추출합니다.
  /// 새 구조와 이전 구조 모두 지원합니다.
  ResumeModel? _parseResumeData(Map<String, dynamic>? data) {
    if (data == null) return null;

    // 새 구조 (data 필드에 저장된 경우)
    if (data.containsKey('data')) {
      final resumeData = data['data'] as Map<String, dynamic>;
      return ResumeModel.fromJson(resumeData);
    }

    // 기존 구조 (resumeData 필드에 저장된 경우) - 하위 호환성
    else if (data.containsKey('resumeData')) {
      final resumeData = data['resumeData'] as Map<String, dynamic>;
      return ResumeModel.fromJson(resumeData);
    }

    return null;
  }

  /// 이력서 조회
  ///
  /// [userId]에 해당하는 사용자의 가장 최근 이력서를 조회합니다.
  Future<ResumeModel?> getResume(String userId) async {
    try {
      // 사용자의 이력서 목록 중 가장 최신 문서 조회
      final docs = await _firestoreService.queryWithIndexFallback(
        _resumesCollection,
        'userId',
        userId,
        orderField: 'metadata.createdAt',
        descending: true,
      );

      if (docs.isEmpty) return null;

      // 가장 최신 이력서 반환
      final latestDoc = docs.first;
      return _parseResumeData(latestDoc.data() as Map<String, dynamic>?);
    } catch (e) {
      print('이력서 조회 중 오류 발생: $e');
      throw Exception('이력서를 불러오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 이력서 조회
  ///
  /// 현재 로그인된 사용자의 이력서를 조회합니다.
  Future<ResumeModel?> getCurrentUserResume() async {
    final currentUser = _firestoreService.getCurrentUser();
    return getResume(currentUser.uid);
  }

  /// 생성 일시 추출
  ///
  /// 문서 데이터에서 생성 일시를 추출합니다.
  /// 새 구조와 이전 구조 모두 지원합니다.
  dynamic _getCreatedAt(Map<String, dynamic> data) {
    return data.containsKey('metadata')
        ? (data['metadata'] as Map<String, dynamic>)['createdAt']
        : data['createdAt'];
  }

  /// 이력서 데이터 추출
  ///
  /// 문서 데이터에서 이력서 필드 데이터를 추출합니다.
  /// 새 구조와 이전 구조 모두 지원합니다.
  Map<String, dynamic> _extractResumeData(Map<String, dynamic> data) {
    // 새 구조 (data 필드에 저장된 경우)
    if (data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    }
    // 기존 구조 (resumeData 필드에 저장된 경우) - 하위 호환성
    else if (data.containsKey('resumeData')) {
      return data['resumeData'] as Map<String, dynamic>;
    }
    // 그 외에는 데이터 자체를 반환
    return data;
  }

  /// 모든 사용자의 이력서 목록 조회 (관리자 전용)
  ///
  /// 시스템에 등록된 모든 이력서 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getAllResumes() async {
    try {
      // 관리자 권한 확인 (현재 사용자 확인)
      _firestoreService.getCurrentUser();

      // TODO: 여기서 관리자 권한 체크 로직 추가

      // 모든 이력서 문서 조회
      final docs = await _firestoreService.query(
        _resumesCollection,
        (collection) => collection.get(),
      );

      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final resumeData = _extractResumeData(data);
        final createdAt = _getCreatedAt(data);

        return {
          'id': doc.id,
          'data': resumeData,
          'createdAt': createdAt,
        };
      }).toList();
    } catch (e) {
      print('전체 이력서 목록 조회 중 오류 발생: $e');
      throw Exception('이력서 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 이력서 삭제
  ///
  /// [resumeId]에 해당하는 이력서를 삭제합니다.
  /// 본인의 이력서만 삭제 가능합니다.
  Future<bool> deleteResume(String resumeId) async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      // 이력서 문서 조회
      final data = await _firestoreService.getDocument(
        _resumesCollection,
        resumeId,
      );

      if (data == null) {
        throw Exception('존재하지 않는 이력서입니다.');
      }

      // 이력서의 소유자 확인
      final String docUserId = data['userId'] as String;

      // 본인 이력서만 삭제 가능하도록 체크
      if (userId != docUserId) {
        throw Exception('다른 사용자의 이력서는 삭제할 수 없습니다.');
      }

      // Firestore에서 이력서 삭제
      await _firestoreService.deleteDocument(_resumesCollection, resumeId);

      return true;
    } catch (e) {
      print('이력서 삭제 중 오류 발생: $e');
      throw Exception('이력서를 삭제하는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 이력서 목록 조회
  ///
  /// 현재 로그인된 사용자의 모든 이력서를 조회합니다.
  Future<List<Map<String, dynamic>>> getCurrentUserResumeList() async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      // 사용자의 이력서 목록 조회
      final docs = await _firestoreService.queryWithIndexFallback(
        _resumesCollection,
        'userId',
        userId,
        orderField: 'metadata.createdAt',
        descending: true,
      );

      if (docs.isEmpty) {
        return [];
      }

      return _processResumeDocuments(docs);
    } catch (e) {
      print('사용자 이력서 목록 조회 중 오류 발생: $e');
      throw Exception('이력서 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 이력서 문서 목록 처리
  List<Map<String, dynamic>> _processResumeDocuments(
      List<DocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final resumeData = _extractResumeData(data);
      final createdAt = _getCreatedAt(data);

      return {
        'id': doc.id, // 문서 ID 설정
        'field': resumeData['field'] ?? '',
        'position': resumeData['position'] ?? '',
        'experience': resumeData['experience'] ?? '',
        'interviewTypes': resumeData['interviewTypes'] ?? [],
        'createdAt': createdAt,
      };
    }).toList();
  }
}
