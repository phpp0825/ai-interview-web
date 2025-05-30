import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../models/resume_model.dart';
import '../../services/report/mock_report_data_service.dart';

import 'report_repository_interface.dart';

/// Firebase 기반 리포트 레포지토리 구현체
/// 면접 리포트 생성 및 관리 기능을 제공합니다.
class FirebaseReportRepository implements IReportRepository {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 단일 리포트 조회 (통합 버전)
  /// 기존 reports 컬렉션과 새로운 interview_reports 컬렉션 모두에서 조회
  @override
  Future<ReportModel> getReport(String reportId) async {
    try {
      print('🔍 리포트 조회 시작: $reportId');

      // reports 컬렉션에서 조회
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();

      if (reportDoc.exists && reportDoc.data() != null) {
        print('📊 reports 컬렉션에서 발견');
        return _convertFirestoreToReportModel(reportId, reportDoc.data()!);
      }

      throw Exception('리포트를 찾을 수 없습니다.');
    } catch (e) {
      print('❌ 리포트 조회 중 오류 발생: $e');
      throw Exception('데이터를 가져오는데 실패했습니다: $e');
    }
  }

  /// 현재 사용자의 리포트 목록 조회 (단일 컬렉션)
  /// reports 컬렉션에서만 조회 (ReportModel 형식 통일)
  @override
  Future<List<Map<String, dynamic>>> getCurrentUserReportSummaries() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 로그인된 사용자가 없습니다.');
        return [];
      }

      final String userId = currentUser.uid;

      // reports 컬렉션에서 조회 (ReportModel 형식)
      final QuerySnapshot reportsQuery = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .get();

      if (reportsQuery.docs.isEmpty) {
        print('📭 사용자의 리포트가 없습니다.');
        return [];
      }

      // 결과를 수동으로 날짜순 정렬
      final sortedDocs = List.of(reportsQuery.docs);
      sortedDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;

        final aTimestamp = aData['createdAt'] as Timestamp?;
        final bTimestamp = bData['createdAt'] as Timestamp?;

        if (aTimestamp == null || bTimestamp == null) {
          return 0;
        }

        return bTimestamp.compareTo(aTimestamp); // 내림차순 정렬
      });

      final reports = sortedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'title': data['title'] ?? '면접 분석 보고서',
          'field': data['field'] ?? '',
          'position': data['position'] ?? '',
          'interviewType': data['interviewType'] ?? '직무면접',
          'status': data['status'] ?? 'completed',
          'score': data['score'] ?? 0,
          'duration': data['duration'] ?? 0,
          'createdAt': data['createdAt'],
        };
      }).toList();

      print('✅ ${reports.length}개 리포트 조회 완료 (단일 컬렉션)');
      return reports;
    } catch (e) {
      print('❌ 리포트 목록 조회 중 오류 발생: $e');
      return [];
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
      print('🗑️ 리포트 삭제 시작: $reportId');

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 로그인된 사용자가 없습니다');
        return false;
      }

      // 리포트 문서 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        print('❌ 존재하지 않는 리포트입니다: $reportId');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUser.uid) {
        print('❌ 해당 리포트에 대한 접근 권한이 없습니다');
        return false;
      }

      // 리포트 삭제
      await _firestore.collection('reports').doc(reportId).delete();

      print('✅ 리포트 삭제 완료: $reportId');
      return true;
    } catch (e) {
      print('❌ 리포트 삭제 중 오류 발생: $e');
      return false;
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

    // 새로운 면접 세부 정보 필드들 파싱
    List<QuestionAnswerModel>? questionAnswers;
    if (data['questionAnswers'] != null) {
      questionAnswers = (data['questionAnswers'] as List?)
          ?.map((qa) => QuestionAnswerModel.fromJson(qa))
          .toList();
    }

    List<SkillEvaluationModel>? skillEvaluations;
    if (data['skillEvaluations'] != null) {
      skillEvaluations = (data['skillEvaluations'] as List)
          .map((se) => SkillEvaluationModel.fromJson(se))
          .toList();
    }

    // 비디오 URL 처리: videoUrls 배열이 있으면 첫 번째를 사용, 없으면 videoUrl 필드 사용
    String videoUrl = '';
    if (data['videoUrls'] != null && (data['videoUrls'] as List).isNotEmpty) {
      // videoUrls 배열에서 첫 번째 URL 사용
      videoUrl = (data['videoUrls'] as List).first.toString();
      print('📹 비디오 URL 로드됨: $videoUrl');
      print('📋 총 비디오 개수: ${(data['videoUrls'] as List).length}개');
    } else {
      // 기존 videoUrl 필드 사용 (하위 호환성)
      videoUrl = data['videoUrl'] ?? '';
      print('📹 기존 비디오 URL 사용: $videoUrl');
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
      videoUrl: videoUrl, // 수정된 비디오 URL 처리
      timestamps: timestamps,
      speechSpeedData: speechSpeedData,
      gazeData: gazeData,
      questionAnswers: questionAnswers,
      skillEvaluations: skillEvaluations,
      feedback: data['feedback'],
      grade: data['grade'],
      categoryScores: data['categoryScores'] != null
          ? Map<String, int>.from(data['categoryScores'])
          : null,
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

  /// 면접 완료 후 최종 리포트 생성 및 저장 (ReportModel 직접 생성)
  /// [questions] - 면접 질문 목록
  /// [answers] - 면접 답변 목록
  /// [videoUrls] - 각 질문별 비디오 URL 목록
  /// [resume] - 선택된 이력서 정보
  /// [duration] - 면접 소요 시간 (초)
  /// [userId] - 사용자 ID
  ///
  /// 반환값: 생성된 리포트 ID
  Future<String> generateInterviewReport({
    required List<String> questions,
    required List<String> answers,
    required List<String> videoUrls,
    required ResumeModel resume,
    required int duration,
    required String userId,
  }) async {
    try {
      print('📊 ReportModel 형식으로 면접 리포트 생성 시작...');
      print('🎬 받은 비디오 URL 개수: ${videoUrls.length}');
      for (int i = 0; i < videoUrls.length; i++) {
        print('🎬 비디오 ${i + 1}: ${videoUrls[i]}');
      }

      // 리포트 ID 생성
      final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';

      // 비디오 URL 처리: 첫 번째 URL을 메인 videoUrl로 사용
      String mainVideoUrl = videoUrls.isNotEmpty ? videoUrls.first : '';
      print('📹 메인 비디오 URL: $mainVideoUrl');

      // === 아래부터는 모두 목업 데이터로 고정 ===
      // 목업 기술 평가 생성
      final skillEvaluations =
          MockReportDataService.generateMockSkillEvaluations();
      // 목업 피드백 생성
      final feedback = MockReportDataService.generateMockFeedback();
      // 말하기 속도 데이터 생성 (목업)
      final speechSpeedData =
          MockReportDataService.generateSpeechSpeedData(120); // 항상 2분짜리 목업
      // 시선 처리 데이터 생성 (목업)
      final gazeData = MockReportDataService.generateGazeData();
      // 전체 점수 계산 (목업)
      final totalScore = 85; // 목업 점수
      // 등급 계산
      final grade = MockReportDataService.calculateGrade(totalScore);
      // 카테고리별 점수 생성
      final categoryScores = MockReportDataService.generateCategoryScores();

      // 질문-답변 데이터 생성 (실제 비디오 URL들과 연결)
      List<QuestionAnswerModel> questionAnswers = [];

      // 기본 면접 질문들 (목업)
      final defaultQuestions = [
        '간단한 자기소개와 지원 동기를 말씀해 주세요.',
        '팀 프로젝트에서 협업의 중요성과 본인의 역할에 대해 설명해 주세요.',
        '새로운 기술을 학습하고 적용한 경험이 있다면 공유해 주세요.',
      ];

      // 각 질문에 해당하는 비디오 URL 연결
      for (int i = 0; i < defaultQuestions.length; i++) {
        final questionText = defaultQuestions[i];
        // i번째 비디오 URL이 있으면 사용, 없으면 빈 문자열
        final videoUrl = i < videoUrls.length ? videoUrls[i] : '';

        questionAnswers.add(QuestionAnswerModel(
          question: questionText,
          answer: '답변 내용입니다.', // 목업 답변
          score: 85 + (i * 2), // 질문별로 조금씩 다른 점수
          evaluation: '좋은 답변입니다.', // 목업 피드백 (evaluation으로 수정)
          videoUrl: videoUrl, // 실제 녹화된 비디오 URL 연결
          answerDuration: 60, // 목업 답변 시간 (answerDuration으로 수정)
        ));

        if (videoUrl.isNotEmpty) {
          print('🎬 질문 ${i + 1}: "${questionText}" → 비디오 연결됨');
        } else {
          print('⚠️ 질문 ${i + 1}: "${questionText}" → 비디오 없음');
        }
      }

      print(
          '✅ 총 ${questionAnswers.length}개 질문에 ${videoUrls.length}개 비디오 연결 완료');

      // ReportModel 직접 생성 (질문/답변/스킬/피드백 등도 목업)
      final report = ReportModel(
        id: reportId,
        title: '${resume.position} 면접 리포트',
        date: DateTime.now(),
        field: resume.field,
        position: resume.position,
        interviewType: '직무면접',
        duration: duration, // 실제 면접 시간
        score: totalScore,
        videoUrl: mainVideoUrl, // 첫 번째 비디오 URL 사용
        timestamps: [], // 타임스탬프 제외
        speechSpeedData: speechSpeedData,
        gazeData: gazeData,
        questionAnswers: questionAnswers, // 실제 비디오 URL이 연결된 질문-답변 데이터
        skillEvaluations: skillEvaluations,
        feedback: feedback,
        grade: grade,
        categoryScores: categoryScores,
      );

      // Firestore의 reports 컬렉션에 저장
      await _firestore.collection('reports').doc(reportId).set({
        ...report.toJson(),
        'userId': userId,
        'resumeId': resume.resume_id.isNotEmpty ? resume.resume_id : reportId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'videoUrls': videoUrls, // 모든 비디오 URL 저장 (하위 호환성)
        'mainVideoUrl': mainVideoUrl, // 메인 비디오 URL 별도 저장
      });

      print('🎉 ReportModel 형식 리포트 저장 완료! ID: $reportId');
      print('⏱️ 면접 소요 시간: ${duration ~/ 60}분 ${duration % 60}초');
      print('🎬 저장된 비디오 개수: ${videoUrls.length}개');
      print('📊 총점: $totalScore점 ($grade)');
      print('📹 메인 비디오 URL 저장 완료: $mainVideoUrl');
      print('🎯 각 질문별 비디오 URL 연결 완료');

      return reportId;
    } catch (e) {
      print('❌ ReportModel 형식 리포트 생성 실패: $e');
      throw Exception('리포트 생성 중 오류가 발생했습니다: $e');
    }
  }
}
