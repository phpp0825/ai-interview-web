import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Firestore 데이터베이스 작업을 처리하는 서비스
///
/// 이 서비스는 Firestore 데이터베이스 연결과 기본 CRUD 작업을 담당합니다.
/// 다른 서비스들이 이 클래스를 통해 Firestore에 접근합니다.
class FirestoreService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 싱글톤 패턴 구현
  static final FirestoreService _instance = FirestoreService._internal();

  // 내부 생성자
  FirestoreService._internal();

  // 팩토리 생성자
  factory FirestoreService() {
    return _instance;
  }

  /// 현재 로그인된 사용자 가져오기 (없으면 예외 발생)
  User getCurrentUser() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }
    return currentUser;
  }

  /// 문서 생성/업데이트
  ///
  /// [collection] 컬렉션에 [docId] 문서를 [data]로 생성하거나 업데이트합니다.
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      print('Firestore 문서 생성/업데이트 중 오류 발생: $e');
      throw Exception('Firestore 문서 작업에 실패했습니다: $e');
    }
  }

  /// 문서 조회
  ///
  /// [collection] 컬렉션에서 [docId] 문서를 조회합니다.
  Future<Map<String, dynamic>?> getDocument(
      String collection, String docId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(collection).doc(docId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Firestore 문서 조회 중 오류 발생: $e');
      throw Exception('Firestore 문서 조회에 실패했습니다: $e');
    }
  }

  /// 문서 삭제
  ///
  /// [collection] 컬렉션에서 [docId] 문서를 삭제합니다.
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      print('Firestore 문서 삭제 중 오류 발생: $e');
      throw Exception('Firestore 문서 삭제에 실패했습니다: $e');
    }
  }

  /// 쿼리 실행
  ///
  /// [collection] 컬렉션에서 [queryBuilder] 함수로 만든 쿼리를 실행합니다.
  Future<List<DocumentSnapshot>> query(
      String collection, Function(CollectionReference) queryBuilder) async {
    try {
      final querySnapshot =
          await queryBuilder(_firestore.collection(collection));
      return querySnapshot.docs;
    } catch (e) {
      print('Firestore 쿼리 실행 중 오류 발생: $e');
      throw Exception('Firestore 쿼리 실행에 실패했습니다: $e');
    }
  }

  /// 인덱스 오류에 대응한 쿼리 실행
  ///
  /// [collection] 컬렉션에서 [field]가 [value]와 같은 문서 중
  /// [orderField]로 정렬된 결과를 반환합니다.
  /// 인덱스가 없는 경우 클라이언트에서 정렬합니다.
  Future<List<DocumentSnapshot>> queryWithIndexFallback(
      String collection, String field, dynamic value,
      {String? orderField, bool descending = false}) async {
    try {
      List<DocumentSnapshot> results = [];

      // 1. 기본 쿼리 (where 조건만 사용)
      final QuerySnapshot baseQuery = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();

      results = baseQuery.docs;

      // 2. 정렬이 필요한 경우, 클라이언트 측에서 정렬 수행
      if (orderField != null && results.isNotEmpty) {
        results.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          // 중첩 필드 처리 (예: "metadata.createdAt")
          dynamic aValue = _getNestedField(aData, orderField);
          dynamic bValue = _getNestedField(bData, orderField);

          // null 처리
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return descending ? -1 : 1;
          if (bValue == null) return descending ? 1 : -1;

          // 비교
          try {
            int result = 0;
            if (aValue is Comparable && bValue is Comparable) {
              result = aValue.compareTo(bValue);
            } else {
              // Timestamp 비교 등 특수 케이스
              if (aValue is Timestamp && bValue is Timestamp) {
                result = aValue.compareTo(bValue);
              } else {
                // 문자열로 변환하여 비교 (안전한 대체 방법)
                result = aValue.toString().compareTo(bValue.toString());
              }
            }
            return descending ? -result : result;
          } catch (e) {
            print('정렬 중 오류 발생: $e');
            return 0; // 오류 시 순서 유지
          }
        });
      }

      return results;
    } catch (e) {
      print('Firestore 쿼리 실행 중 오류 발생: $e');
      throw Exception('Firestore 쿼리 실행에 실패했습니다: $e');
    }
  }

  /// 중첩 필드 값 가져오기
  ///
  /// "metadata.createdAt"과 같은 중첩 필드 경로에서 값을 가져옵니다.
  dynamic _getNestedField(Map<String, dynamic> data, String fieldPath) {
    final fieldParts = fieldPath.split('.');
    dynamic value = data;

    for (final part in fieldParts) {
      if (value is! Map<String, dynamic>) return null;
      value = value[part];
      if (value == null) return null;
    }

    return value;
  }
}
