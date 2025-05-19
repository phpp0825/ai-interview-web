import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import 'report_repository_interface.dart';

/// Firebase 기반 리포트 레포지토리 구현체
class FirebaseReportRepository implements IReportRepository {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 단일 리포트 조회
  @override
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

  /// 현재 사용자의 리포트 목록 조회 (간략 정보)
  @override
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

  /// 리포트 저장
  @override
  Future<String> saveReport(Map<String, dynamic> reportData) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final String userId = currentUser.uid;
      final String reportId = reportData['reportId'] ??
          'report_${DateTime.now().millisecondsSinceEpoch}';

      // userId 추가 (없는 경우)
      if (!reportData.containsKey('userId')) {
        reportData['userId'] = userId;
      }

      // reportId 추가 (없는 경우)
      if (!reportData.containsKey('reportId')) {
        reportData['reportId'] = reportId;
      }

      // 생성 시간 추가 (없는 경우)
      if (!reportData.containsKey('createdAt')) {
        reportData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Firestore에 리포트 저장
      await _firestore.collection('reports').doc(reportId).set(reportData);

      // 사용자 문서에 리포트 ID 추가
      await _firestore.collection('users').doc(userId).update({
        'reports': FieldValue.arrayUnion([reportId]),
      });

      return reportId;
    } catch (e) {
      print('리포트 저장 중 오류 발생: $e');
      throw Exception('리포트를 저장하는데 실패했습니다: $e');
    }
  }

  /// 리포트 상태 업데이트
  @override
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

  /// 리포트 비디오 URL 업데이트
  @override
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'videoUrl': videoUrl,
      });
      return true;
    } catch (e) {
      print('보고서 비디오 URL 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  /// 리포트 삭제
  @override
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

  /// Firestore 문서를 ReportModel로 변환
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
}
