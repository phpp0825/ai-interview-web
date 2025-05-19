import '../../models/resume_model.dart';
import '../../services/common/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'resume_repository_interface.dart';

/// Firebase 기반 이력서 레포지토리 구현체
class FirebaseResumeRepository implements IResumeRepository {
  // 컬렉션 이름 상수
  static const String _resumesCollection = 'resumes';

  // FirestoreService 인스턴스
  final FirestoreService _firestoreService = FirestoreService();

  /// 이력서를 Firestore에 저장
  @override
  Future<String> saveResume(ResumeModel resume) async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      // 타임스탬프만 resumeId로 사용
      final String resumeId = resume.resume_id.isNotEmpty
          ? resume.resume_id
          : DateTime.now().millisecondsSinceEpoch.toString();

      // 이력서 모델에 resume_id 설정
      resume.resume_id = resumeId;

      // 전체 데이터를 하나의 JSON 객체로 구성
      final Map<String, dynamic> jsonData = {
        'userId': userId,
        'data': resume.toJson(), // 여기에 resume_id가 포함됨
        'metadata': {
          'createdAt': FieldValue.serverTimestamp(),
        }
      };

      // Firestore에 새 이력서 저장 (문서 ID는 userId_timestamp 형식으로)
      final docId = '${userId}_$resumeId';
      await _firestoreService.setDocument(
        _resumesCollection,
        docId,
        jsonData,
      );

      return resumeId;
    } catch (e) {
      print('이력서 저장 중 오류 발생: $e');
      throw Exception('이력서를 저장하는데 실패했습니다: $e');
    }
  }

  /// 이력서 조회
  @override
  Future<ResumeModel?> getResume(String resumeId) async {
    try {
      // 타임스탬프 형식인지 확인
      final isTimestamp = int.tryParse(resumeId) != null;

      if (isTimestamp) {
        // 문서 ID 패턴으로 조회
        final pattern = '*_$resumeId';
        final docs = await _firestoreService.query(
          _resumesCollection,
          (collection) => collection
              .orderBy(FieldPath.documentId)
              .startAt([pattern.replaceAll('*', '')]).endAt(
                  [pattern.replaceAll('*', '') + '\uf8ff']).get(),
        );

        if (docs.isNotEmpty) {
          final doc = docs.first;
          final data = doc.data() as Map<String, dynamic>;
          return _parseResumeData(data, docId: doc.id);
        }
      }

      // 직접 문서 ID로 조회
      final currentUser = _firestoreService.getCurrentUser();
      final docId = '${currentUser.uid}_$resumeId';
      final data =
          await _firestoreService.getDocument(_resumesCollection, docId);

      if (data != null) {
        return _parseResumeData(data, docId: docId);
      }

      return null;
    } catch (e) {
      print('이력서 조회 중 오류 발생: $e');
      throw Exception('이력서를 불러오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 이력서 조회
  @override
  Future<ResumeModel?> getCurrentUserResume() async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      print('FirebaseResumeRepository: 현재 사용자 이력서 조회 시작 (userId: $userId)');

      // 인덱스 문제를 우회하기 위해 간단한 쿼리로 변경
      // 1. 먼저 userId로만 필터링
      final docs = await _firestoreService.query(
        _resumesCollection,
        (collection) => collection
            .where('userId', isEqualTo: userId)
            .limit(10) // 최근 10개만 가져옴
            .get(),
      );

      print('FirebaseResumeRepository: 이력서 쿼리 결과 ${docs.length}개 항목');

      if (docs.isEmpty) {
        print('FirebaseResumeRepository: 사용자 이력서가 없음');
        return null;
      }

      // 2. 클라이언트 측에서 정렬 - 가장 최근 이력서 찾기
      DocumentSnapshot latestDoc = docs.first;
      DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0); // 1970년 시작

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final metadata = data['metadata'] as Map<String, dynamic>?;

        if (metadata != null && metadata['createdAt'] != null) {
          DateTime createdAt;

          // Timestamp 또는 DateTime 처리
          if (metadata['createdAt'] is Timestamp) {
            createdAt = (metadata['createdAt'] as Timestamp).toDate();
          } else {
            // ISO 8601 문자열인 경우
            try {
              createdAt = DateTime.parse(metadata['createdAt'].toString());
            } catch (_) {
              // 파싱할 수 없는 경우 현재 시간 사용
              createdAt = DateTime.now();
            }
          }

          if (createdAt.isAfter(latestTime)) {
            latestTime = createdAt;
            latestDoc = doc;
          }
        }
      }

      // 3. 최신 문서 반환
      final data = latestDoc.data() as Map<String, dynamic>;
      print('FirebaseResumeRepository: 최신 이력서 발견, ID: ${latestDoc.id}');
      return _parseResumeData(data, docId: latestDoc.id);
    } catch (e) {
      print('현재 사용자 이력서 조회 중 오류 발생: $e');
      throw Exception('현재 사용자의 이력서를 불러오는데 실패했습니다: $e');
    }
  }

  /// 이력서 삭제
  @override
  Future<bool> deleteResume(String resumeId) async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;
      final docId = '${userId}_$resumeId';

      await _firestoreService.deleteDocument(_resumesCollection, docId);
      return true;
    } catch (e) {
      print('이력서 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 현재 사용자의 이력서 목록 조회
  @override
  Future<List<Map<String, dynamic>>> getCurrentUserResumeList() async {
    try {
      final currentUser = _firestoreService.getCurrentUser();
      final String userId = currentUser.uid;

      print('FirebaseResumeRepository: 현재 사용자 이력서 목록 조회 시작 (userId: $userId)');

      // 인덱스 문제를 우회하기 위해 간단한 쿼리로 변경
      final docs = await _firestoreService.query(
        _resumesCollection,
        (collection) => collection
            .where('userId', isEqualTo: userId)
            .limit(50) // 최대 50개
            .get(),
      );

      print('FirebaseResumeRepository: 이력서 목록 쿼리 결과 ${docs.length}개 항목');

      // 결과를 메모리에서 정렬
      final result = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final resumeData = _extractResumeData(data);
        final createdAt = _getCreatedAt(data);

        return {
          'id': _extractResumeId(data, doc.id),
          'docId': doc.id,
          'field': resumeData['field'] ?? '',
          'position': resumeData['position'] ?? '',
          'experience': resumeData['experience'] ?? '',
          'interviewTypes': resumeData['interviewTypes'] ?? [],
          'createdAt': createdAt,
        };
      }).toList();

      // 생성일 기준 내림차순 정렬 (최신순)
      result.sort((a, b) {
        final aTime = a['createdAt'] != null
            ? (a['createdAt'] is DateTime
                ? a['createdAt']
                : (a['createdAt'] is Timestamp
                    ? (a['createdAt'] as Timestamp).toDate()
                    : DateTime.now()))
            : DateTime.now();

        final bTime = b['createdAt'] != null
            ? (b['createdAt'] is DateTime
                ? b['createdAt']
                : (b['createdAt'] is Timestamp
                    ? (b['createdAt'] as Timestamp).toDate()
                    : DateTime.now()))
            : DateTime.now();

        return bTime.compareTo(aTime); // 내림차순
      });

      print('FirebaseResumeRepository: 이력서 목록 정렬 완료, ${result.length}개 항목');
      return result;
    } catch (e) {
      print('사용자 이력서 목록 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 이력서 데이터 파싱
  ResumeModel? _parseResumeData(Map<String, dynamic>? data, {String? docId}) {
    if (data == null) return null;

    try {
      // 새 구조 (data 필드에 저장된 경우)
      Map<String, dynamic> resumeData;
      if (data.containsKey('data')) {
        resumeData = data['data'] as Map<String, dynamic>;
      }
      // 기존 구조 (resumeData 필드에 저장된 경우) - 하위 호환성
      else if (data.containsKey('resumeData')) {
        resumeData = data['resumeData'] as Map<String, dynamic>;
      } else {
        return null;
      }

      // resumeId 처리
      final resumeId = _extractResumeId(data, docId);

      if (resumeId.isNotEmpty &&
          (!resumeData.containsKey('resume_id') ||
              resumeData['resume_id'].isEmpty)) {
        resumeData['resume_id'] = resumeId;
      }

      return ResumeModel.fromJson(resumeData);
    } catch (e) {
      print('이력서 데이터 파싱 오류: $e');
    }

    return null;
  }

  /// 생성 일시 추출
  dynamic _getCreatedAt(Map<String, dynamic> data) {
    return data.containsKey('metadata')
        ? (data['metadata'] as Map<String, dynamic>)['createdAt']
        : data['createdAt'];
  }

  /// 이력서 데이터 추출
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

  /// resumeId 추출
  String _extractResumeId(Map<String, dynamic> data, String? docId) {
    // 1. data 내의 resume_id 확인
    final resumeData = _extractResumeData(data);
    if (resumeData.containsKey('resume_id') &&
        resumeData['resume_id'].isNotEmpty) {
      return resumeData['resume_id'];
    }

    // 2. 상위 레벨의 resumeId 확인 (구 버전 호환성)
    if (data.containsKey('resumeId') && data['resumeId'].isNotEmpty) {
      return data['resumeId'];
    }

    // 3. docId에서 추출 (userId_timestamp 형식)
    if (docId != null && docId.contains('_')) {
      return docId.split('_').last;
    }

    return '';
  }

  /// 현재 로그인한 사용자 정보를 반환합니다.
  @override
  User getCurrentUser() {
    return _firestoreService.getCurrentUser();
  }

  /// Firestore 컬렉션에 대해 쿼리를 실행합니다.
  @override
  Future<List<DocumentSnapshot>> query(
      Future<QuerySnapshot> Function(CollectionReference) queryBuilder) {
    return _firestoreService.query(_resumesCollection, queryBuilder);
  }

  /// 인덱스가 있을 때와 없을 때 모두 사용 가능한 쿼리를 실행합니다.
  @override
  Future<List<DocumentSnapshot>> queryWithIndexFallback(
      String field, dynamic value,
      {String? orderField, bool descending = false}) {
    return _firestoreService.queryWithIndexFallback(
      _resumesCollection,
      field,
      value,
      orderField: orderField,
      descending: descending,
    );
  }

  /// 문서를 가져옵니다.
  @override
  Future<Map<String, dynamic>?> getDocument(String documentId) {
    return _firestoreService.getDocument(_resumesCollection, documentId);
  }

  /// 문서를 삭제합니다.
  @override
  Future<void> deleteDocument(String documentId) {
    return _firestoreService.deleteDocument(_resumesCollection, documentId);
  }
}
