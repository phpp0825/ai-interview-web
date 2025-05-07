import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume_model.dart';
import '../services/report_service.dart';

/// 이력서 관련 서비스 기능을 제공하는 클래스
///
/// 이 서비스는 이력서 데이터의 저장, 조회, 삭제 기능과
/// 이력서 기반 리포트 생성 기능을 담당합니다.
/// Firestore와의 통신을 통해 데이터를 관리합니다.
class ResumeService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ReportService 인스턴스
  final ReportService _reportService = ReportService();

  /// 이력서를 Firestore에 저장
  ///
  /// [resume] 객체를 현재 로그인된 사용자의 이력서로 저장합니다.
  Future<bool> saveResumeToFirestore(ResumeModel resume) async {
    try {
      // 현재 로그인한 사용자 확인
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;

      // Firestore에 이력서 저장
      await _firestore.collection('resumes').doc(userId).set({
        'userId': userId,
        'resumeData': resume.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 사용자 문서에도 이력서 정보 참조 추가
      await _firestore.collection('users').doc(userId).set({
        'hasResume': true,
        'lastResumeUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Firestore에 이력서가 성공적으로 저장되었습니다. 사용자 ID: $userId');
      return true;
    } catch (e) {
      print('Firestore에 이력서 저장 중 오류 발생: $e');
      throw Exception('이력서를 Firestore에 저장하는데 실패했습니다: $e');
    }
  }

  /// 리포트 생성 시 이력서를 Firestore에 저장하고 리포트 생성
  ///
  /// [resume] 데이터를 저장하고, 이를 기반으로 새 리포트를 생성합니다.
  Future<String> createReportWithResume(ResumeModel resume) async {
    try {
      // 현재 로그인한 사용자 확인
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;

      // 1. 먼저 이력서 저장
      await saveResumeToFirestore(resume);

      // 2. ReportService를 통해 리포트 생성
      final String reportId = await _reportService.createReport(resume);

      // 3. 사용자 문서에 생성된 리포트 ID 추가
      await _firestore.collection('users').doc(userId).update({
        'reports': FieldValue.arrayUnion([reportId]),
        'lastReportCreated': FieldValue.serverTimestamp(),
      });

      print('리포트가 성공적으로 생성되었습니다. 리포트 ID: $reportId');
      return reportId;
    } catch (e) {
      print('리포트 생성 중 오류 발생: $e');
      throw Exception('리포트를 생성하는데 실패했습니다: $e');
    }
  }

  /// 이력서 조회
  ///
  /// [userId]에 해당하는 사용자의 이력서를 조회합니다.
  Future<ResumeModel?> getResume(String userId) async {
    try {
      // Firestore에서 조회
      final DocumentSnapshot doc =
          await _firestore.collection('resumes').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('resumeData')) {
          final resumeData = data['resumeData'] as Map<String, dynamic>;
          return ResumeModel.fromMap(resumeData);
        }
      }

      // 없는 경우 null 반환
      return null;
    } catch (e) {
      print('이력서 조회 중 오류 발생: $e');
      throw Exception('이력서를 불러오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 이력서 조회
  ///
  /// 현재 로그인된 사용자의 이력서를 조회합니다.
  Future<ResumeModel?> getCurrentUserResume() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    return getResume(currentUser.uid);
  }

  /// 모든 사용자의 이력서 목록 조회 (관리자 전용)
  ///
  /// 시스템에 등록된 모든 이력서 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getAllResumes() async {
    try {
      // 관리자 권한 확인
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 여기서 관리자 권한 체크 로직 추가

      final QuerySnapshot resumes =
          await _firestore.collection('resumes').get();

      return resumes.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userId': doc.id,
          'resumeData': data['resumeData'],
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList();
    } catch (e) {
      print('전체 이력서 목록 조회 중 오류 발생: $e');
      throw Exception('이력서 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 이력서 삭제
  ///
  /// [userId]에 해당하는 사용자의 이력서를 삭제합니다.
  /// 본인의 이력서만 삭제 가능합니다.
  Future<bool> deleteResume(String userId) async {
    try {
      // 현재 로그인한 사용자 확인
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 본인 이력서만 삭제 가능하도록 체크
      if (currentUser.uid != userId) {
        throw Exception('다른 사용자의 이력서는 삭제할 수 없습니다.');
      }

      // Firestore에서 이력서 삭제
      await _firestore.collection('resumes').doc(userId).delete();

      // 사용자 문서 업데이트
      await _firestore.collection('users').doc(userId).update({
        'hasResume': false,
      });

      return true;
    } catch (e) {
      print('이력서 삭제 중 오류 발생: $e');
      throw Exception('이력서를 삭제하는데 실패했습니다: $e');
    }
  }
}
