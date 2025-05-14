import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../models/resume_model.dart';

/// 리포트 관련 서비스 기능을 제공하는 클래스
///
/// 이 서비스는 리포트 데이터의 조회, 생성, 수정, 삭제 기능을 담당합니다.
/// Firestore와의 통신을 통해 데이터를 관리합니다.
class ReportService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 단일 리포트 조회
  ///
  /// [reportId]에 해당하는 리포트를 Firestore에서 조회합니다.
  Future<ReportModel> getReport(String reportId) async {
    try {
      // Firestore에서 데이터 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Firestore에서 리포트 데이터 변환
        return _convertFirestoreToReportModel(doc.id, data);
      }

      throw Exception('리포트를 찾을 수 없습니다.');
    } catch (e) {
      print('리포트 조회 중 오류 발생: $e');
      throw Exception('데이터를 가져오는데 실패했습니다: $e');
    }
  }

  /// Firestore 문서를 ReportModel로 변환
  ///
  /// [id]와 [data]를 사용하여 ReportModel 객체를 생성합니다.
  ReportModel _convertFirestoreToReportModel(
      String id, Map<String, dynamic> data) {
    // 타임스탬프 데이터 변환
    List<TimeStampModel> timestamps = [];
    if (data['timestamps'] != null) {
      timestamps = (data['timestamps'] as List).map((ts) {
        return TimeStampModel(
          time: ts['time'] ?? 0,
          label: ts['label'] ?? '',
          description: ts['description'] ?? '',
        );
      }).toList();
    }

    // 말하기 속도 데이터 변환
    List<FlSpot> speechSpeedData = [];
    if (data['speechSpeedData'] != null) {
      speechSpeedData = (data['speechSpeedData'] as List).map((point) {
        return FlSpot(
          point['x']?.toDouble() ?? 0.0,
          point['y']?.toDouble() ?? 0.0,
        );
      }).toList();
    }

    // 시선 처리 데이터 변환
    List<ScatterSpot> gazeData = [];
    if (data['gazeData'] != null) {
      gazeData = (data['gazeData'] as List).map((point) {
        return ScatterSpot(
          point['x']?.toDouble() ?? 0.0,
          point['y']?.toDouble() ?? 0.0,
          color: _getColorFromString(point['color'] ?? 'blue'),
          radius: point['radius']?.toDouble() ?? 4.0,
        );
      }).toList();
    }

    return ReportModel(
      id: id,
      title: data['title'] ?? '면접 분석 보고서',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      field: data['resumeData']?['field'] ?? data['field'] ?? '직무 분야',
      position: data['resumeData']?['position'] ?? data['position'] ?? '직무 포지션',
      interviewType: data['interviewType'] ?? '직무면접',
      duration: data['duration'] ?? 30,
      score: data['score'] ?? 0,
      videoUrl: data['videoUrl'] ?? '',
      timestamps: timestamps,
      speechSpeedData: speechSpeedData,
      gazeData: gazeData,
    );
  }

  /// 색상 문자열을 Colors 객체로 변환
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  /// 현재 사용자의 모든 리포트 조회
  Future<List<ReportModel>> getCurrentUserReports() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;

      // Firestore에서 사용자의 리포트 목록 조회
      final QuerySnapshot reports = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (reports.docs.isNotEmpty) {
        return reports.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _convertFirestoreToReportModel(doc.id, data);
        }).toList();
      }

      // 리포트가 없는 경우 빈 배열 반환
      return [];
    } catch (e) {
      print('리포트 목록 조회 중 오류 발생: $e');
      throw Exception('리포트 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 이력서 데이터를 기반으로 리포트 생성
  ///
  /// [resume] 데이터를 사용하여 새로운 리포트를 생성합니다.
  Future<String> createReport(ResumeModel resume) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;
      final String reportId = DateTime.now().millisecondsSinceEpoch.toString();

      // 이력서의 경험/직무 정보를 활용하여 인터뷰 타입 결정
      final List<String> interviewTypes = resume.interviewTypes;
      final String interviewType =
          interviewTypes.isNotEmpty ? interviewTypes.first : '직무면접';

      // 리포트 제목 생성
      String title = '${resume.position} ';
      if (resume.experience.isNotEmpty) {
        title += '${resume.experience} ';
      }
      title += '면접 분석';

      // Firestore에 리포트 정보 저장
      await _firestore.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'userId': userId,
        'title': title,
        'resumeData': resume.toMap(),
        'field': resume.field,
        'position': resume.position,
        'interviewType': interviewType,
        'status': 'pending', // 상태: pending, processing, completed, failed
        'score': 0, // 초기 점수 0
        'duration': 0, // 초기 시간 0
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('리포트가 성공적으로 생성되었습니다. 리포트 ID: $reportId');
      return reportId;
    } catch (e) {
      print('리포트 생성 중 오류 발생: $e');
      throw Exception('리포트를 생성하는데 실패했습니다: $e');
    }
  }

  /// 리포트 상태 업데이트
  ///
  /// [reportId]에 해당하는 리포트의 상태를 [status]로 업데이트합니다.
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 리포트 문서 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        throw Exception('존재하지 않는 리포트입니다.');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        throw Exception('해당 리포트에 대한 접근 권한이 없습니다.');
      }

      // 상태 업데이트
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
      });

      return true;
    } catch (e) {
      print('리포트 상태 업데이트 중 오류 발생: $e');
      throw Exception('리포트 상태를 업데이트하는데 실패했습니다: $e');
    }
  }

  /// 리포트 삭제
  ///
  /// [reportId]에 해당하는 리포트를 삭제합니다.
  Future<bool> deleteReport(String reportId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 리포트 문서 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        throw Exception('존재하지 않는 리포트입니다.');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        throw Exception('해당 리포트에 대한 접근 권한이 없습니다.');
      }

      // 리포트 삭제
      await _firestore.collection('reports').doc(reportId).delete();

      // 사용자 문서에서 리포트 ID 제거
      await _firestore.collection('users').doc(currentUser.uid).update({
        'reports': FieldValue.arrayRemove([reportId]),
      });

      return true;
    } catch (e) {
      print('리포트 삭제 중 오류 발생: $e');
      throw Exception('리포트를 삭제하는데 실패했습니다: $e');
    }
  }

  /// 모든 리포트 목록 조회 (관리자용)
  Future<List<ReportModel>> getAllReports() async {
    try {
      // 관리자 권한 확인 로직 필요
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firestore에서 모든 리포트 조회
      final QuerySnapshot reports = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      if (reports.docs.isNotEmpty) {
        return reports.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _convertFirestoreToReportModel(doc.id, data);
        }).toList();
      }

      return [];
    } catch (e) {
      print('전체 리포트 목록 조회 중 오류 발생: $e');
      throw Exception('리포트 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 리포트 목록 조회 (간략 정보)
  ///
  /// 현재 로그인된 사용자의 모든 리포트 목록을 간략하게 조회합니다.
  Future<List<Map<String, dynamic>>> getCurrentUserReportSummaries() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;

      // Firestore에서 사용자의 리포트 목록 조회
      final QuerySnapshot reports = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (reports.docs.isEmpty) {
        return [];
      }

      return reports.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final resumeData = data.containsKey('resumeData')
            ? data['resumeData'] as Map<String, dynamic>
            : {'field': data['field'], 'position': data['position']};

        return {
          'id': doc.id,
          'title': data['title'] ?? '면접 분석 보고서',
          'field': resumeData['field'] ?? data['field'] ?? '',
          'position': resumeData['position'] ?? data['position'] ?? '',
          'interviewType': data['interviewType'] ?? '직무면접',
          'status': data['status'] ?? 'completed',
          'score': data['score'] ?? 0,
          'duration': data['duration'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('리포트 목록 조회 중 오류 발생: $e');
      throw Exception('리포트 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 리포트 내용 업데이트
  ///
  /// [reportId] 리포트의 내용을 [content]로 업데이트합니다.
  Future<bool> updateReportContent(String reportId, String content) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'content': content,
        'status': 'completed',
      });
      return true;
    } catch (e) {
      print('리포트 내용 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  /// 리포트 점수 업데이트
  ///
  /// [reportId] 리포트의 점수를 [score]로 업데이트합니다.
  Future<bool> updateReportScore(String reportId, double score) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'score': score,
      });
      return true;
    } catch (e) {
      print('리포트 점수 업데이트 중 오류 발생: $e');
      return false;
    }
  }
}
