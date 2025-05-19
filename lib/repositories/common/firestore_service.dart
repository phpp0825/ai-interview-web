import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 데이터베이스 접근을 위한 서비스
///
/// 이 서비스는 Firestore 데이터베이스와의 기본적인 CRUD 작업을 담당합니다.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자 정보 가져오기
  ///
  /// 로그인된 사용자가 없으면 예외를 발생시킵니다.
  User getCurrentUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }
    return user;
  }

  /// 문서 조회
  ///
  /// [collection] 컬렉션에서 [documentId]에 해당하는 문서를 조회합니다.
  Future<Map<String, dynamic>?> getDocument(
      String collection, String documentId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(collection).doc(documentId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('문서 조회 중 오류 발생: $e');
      throw Exception('문서를 조회하는데 실패했습니다: $e');
    }
  }

  /// 문서 저장
  ///
  /// [collection] 컬렉션의 [documentId] 문서에 [data]를 저장합니다.
  Future<void> setDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data);
    } catch (e) {
      print('문서 저장 중 오류 발생: $e');
      throw Exception('문서를 저장하는데 실패했습니다: $e');
    }
  }

  /// 문서 업데이트
  ///
  /// [collection] 컬렉션의 [documentId] 문서를 [data]로 업데이트합니다.
  Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('문서 업데이트 중 오류 발생: $e');
      throw Exception('문서를 업데이트하는데 실패했습니다: $e');
    }
  }

  /// 문서 삭제
  ///
  /// [collection] 컬렉션에서 [documentId]에 해당하는 문서를 삭제합니다.
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('문서 삭제 중 오류 발생: $e');
      throw Exception('문서를 삭제하는데 실패했습니다: $e');
    }
  }

  /// 컬렉션 쿼리
  ///
  /// [collection] 컬렉션에 대해 [queryBuilder] 함수를 사용해 쿼리를 실행합니다.
  Future<List<DocumentSnapshot>> query(
    String collection,
    Future<QuerySnapshot> Function(CollectionReference) queryBuilder,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await queryBuilder(_firestore.collection(collection));
      return snapshot.docs;
    } catch (e) {
      print('컬렉션 쿼리 중 오류 발생: $e');
      throw Exception('컬렉션 쿼리를 실행하는데 실패했습니다: $e');
    }
  }

  /// 인덱스를 사용한 쿼리 (인덱스가 없으면 fallback 사용)
  ///
  /// [collection] 컬렉션에서 [field] 필드가 [value]인 문서를 조회합니다.
  /// 인덱스가 없으면 클라이언트 측 필터링으로 fallback합니다.
  Future<List<DocumentSnapshot>> queryWithIndexFallback(
    String collection,
    String field,
    dynamic value, {
    String? orderField,
    bool descending = false,
  }) async {
    try {
      // 인덱스를 사용한 쿼리 시도
      final Query query =
          _firestore.collection(collection).where(field, isEqualTo: value);

      // 정렬 필드가 제공된 경우 정렬 적용
      final Query sortedQuery = orderField != null
          ? query.orderBy(orderField, descending: descending)
          : query;

      final QuerySnapshot snapshot = await sortedQuery.get();
      return snapshot.docs;
    } catch (e) {
      print('인덱스 쿼리 실패, 클라이언트 필터링으로 fallback: $e');

      try {
        // 전체 컬렉션 가져와서 클라이언트에서 필터링
        final QuerySnapshot snapshot =
            await _firestore.collection(collection).get();
        final List<DocumentSnapshot> filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data[field] == value;
        }).toList();

        // 정렬 필드가 제공된 경우 클라이언트에서 정렬
        if (orderField != null) {
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aValue = _getNestedField(aData, orderField);
            final bValue = _getNestedField(bData, orderField);

            if (aValue == null || bValue == null) {
              return 0;
            }

            int result = 0;
            if (aValue is Comparable && bValue is Comparable) {
              result = aValue.compareTo(bValue as Comparable);
            }

            return descending ? -result : result;
          });
        }

        return filteredDocs;
      } catch (fallbackError) {
        print('클라이언트 필터링 fallback도 실패: $fallbackError');
        throw Exception('쿼리를 실행하는데 실패했습니다: $fallbackError');
      }
    }
  }

  /// 중첩된 필드 값 가져오기
  ///
  /// 'metadata.createdAt'와 같은 중첩 필드 경로에서 값을 추출합니다.
  dynamic _getNestedField(Map<String, dynamic> data, String fieldPath) {
    final keys = fieldPath.split('.');
    dynamic value = data;

    for (final key in keys) {
      if (value is Map<String, dynamic>) {
        value = value[key];
      } else {
        return null;
      }
    }

    return value;
  }
}
