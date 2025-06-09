import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../models/resume_model.dart';
import '../../services/common/firebase_storage_service.dart';

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

  /// 리포트 삭제 (영상 파일 포함)
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

      // === Firebase Storage 영상 파일들 삭제 ===
      await _deleteReportFiles(data, currentUser.uid);

      // === Firestore 리포트 문서 삭제 ===
      await _firestore.collection('reports').doc(reportId).delete();

      print('✅ 리포트 및 관련 파일 삭제 완료: $reportId');
      return true;
    } catch (e) {
      print('❌ 리포트 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 리포트와 관련된 Firebase Storage 파일들 삭제
  Future<void> _deleteReportFiles(
      Map<String, dynamic> data, String userId) async {
    try {
      print('📂 리포트 관련 Firebase Storage 파일 삭제 시작...');

      final storageService = FirebaseStorageService();
      int deletedCount = 0;

      // === 1. videoUrls 배열에서 파일들 삭제 ===
      if (data['videoUrls'] != null && data['videoUrls'] is List) {
        final videoUrls = data['videoUrls'] as List;
        print('🎬 삭제할 영상 파일 개수: ${videoUrls.length}개');

        for (final videoUrl in videoUrls) {
          if (videoUrl != null && videoUrl.toString().isNotEmpty) {
            final success =
                await _deleteFileFromUrl(videoUrl.toString(), storageService);
            if (success) deletedCount++;
          }
        }
      }

      // === 2. mainVideoUrl 단일 파일 삭제 ===
      if (data['mainVideoUrl'] != null &&
          data['mainVideoUrl'].toString().isNotEmpty) {
        final success = await _deleteFileFromUrl(
            data['mainVideoUrl'].toString(), storageService);
        if (success) deletedCount++;
      }

      // === 3. questionAnswers 내부의 videoUrl들 삭제 ===
      if (data['questionAnswers'] != null && data['questionAnswers'] is List) {
        final questionAnswers = data['questionAnswers'] as List;

        for (final qa in questionAnswers) {
          if (qa != null && qa is Map && qa['videoUrl'] != null) {
            final videoUrl = qa['videoUrl'].toString();
            if (videoUrl.isNotEmpty) {
              final success =
                  await _deleteFileFromUrl(videoUrl, storageService);
              if (success) deletedCount++;
            }
          }
        }
      }

      // === 4. 메인 videoUrl 필드 삭제 ===
      if (data['videoUrl'] != null && data['videoUrl'].toString().isNotEmpty) {
        final success = await _deleteFileFromUrl(
            data['videoUrl'].toString(), storageService);
        if (success) deletedCount++;
      }

      // === 5. 면접 폴더 전체 정리 (Firebase Storage) ===
      final reportId = data['id'] ?? data['reportId'] ?? 'unknown';
      if (reportId != 'unknown') {
        print('🧹 Firebase 면접 폴더 전체 정리 시도: $userId/$reportId');
        await storageService.cleanupInterviewFolder(userId, reportId);
      }

      print('✅ 총 ${deletedCount}개의 파일이 삭제되었습니다.');
    } catch (e) {
      print('⚠️ 파일 삭제 중 일부 오류 발생 (계속 진행): $e');
      // 파일 삭제 실패해도 리포트 삭제는 계속 진행
    }
  }

  /// Firebase Storage URL에서 파일 삭제
  Future<bool> _deleteFileFromUrl(
      String url, FirebaseStorageService storageService) async {
    try {
      if (!url.contains('firebasestorage.googleapis.com') &&
          !url.contains('storage.googleapis.com')) {
        print(
            '⚠️ Firebase Storage URL이 아닙니다: ${url.length > 50 ? url.substring(0, 50) + '...' : url}');
        return false;
      }

      // Firebase Storage URL에서 파일 경로 추출
      final ref = FirebaseStorage.instance.refFromURL(url);
      final filePath = ref.fullPath;

      print('🗑️ 파일 삭제 중: $filePath');
      final success = await storageService.deleteFile(filePath);

      if (success) {
        print('✅ 파일 삭제 성공: $filePath');
      } else {
        print('❌ 파일 삭제 실패: $filePath');
      }

      return success;
    } catch (e) {
      print('❌ 파일 삭제 중 오류: $e');
      return false;
    }
  }

  /// Firestore 문서를 ReportModel로 변환
  ReportModel _convertFirestoreToReportModel(
      String id, Map<String, dynamic> data) {
    // 질문-답변 데이터 변환
    List<QuestionAnswerModel>? questionAnswers;
    if (data['questionAnswers'] != null) {
      questionAnswers = (data['questionAnswers'] as List?)
          ?.map((qa) => QuestionAnswerModel.fromJson(qa))
          .toList();
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
      questionAnswers: questionAnswers,
    );
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
      print('📊 면접 리포트 생성 시작...');
      print('🎬 받은 비디오 URL 개수: ${videoUrls.length}');
      for (int i = 0; i < videoUrls.length; i++) {
        print('🎬 비디오 ${i + 1}: ${videoUrls[i]}');
      }

      // 리포트 ID 생성
      final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';

      // 메인 비디오 URL 설정
      String mainVideoUrl = videoUrls.isNotEmpty ? videoUrls.first : '';
      print('📹 메인 비디오 URL: $mainVideoUrl');

      // === 기본 데이터 (서버 응답이 없을 때 임시 사용) ===
      final totalScore = 0; // 서버 분석 후 업데이트됨
      final grade = "분석중";

      // 질문-답변 데이터는 서버 분석 후 추가됨 (초기에는 빈 배열)
      List<QuestionAnswerModel> questionAnswers = [];

      print('✅ 기본 리포트 데이터 준비 완료 (서버 분석 대기)');

      // ReportModel 생성 (정리된 구조)
      final report = ReportModel(
        id: reportId,
        title: '${resume.position} 면접 리포트',
        date: DateTime.now(),
        field: resume.field,
        position: resume.position,
        interviewType: '직무면접',
        duration: duration, // 실제 면접 시간
        score: totalScore, // 서버 분석 후 업데이트됨
        questionAnswers: questionAnswers, // 서버 분석 후 추가됨
      );

      // Firestore의 reports 컬렉션에 저장 (Firebase Storage 방식)
      await _firestore.collection('reports').doc(reportId).set({
        ...report.toJson(),
        'userId': userId,
        'resumeId': resume.resume_id.isNotEmpty ? resume.resume_id : reportId,
        'status': 'completed', // 완료 상태로 저장
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'videoCount': videoUrls.length, // 영상 개수 저장
        'hasFirebaseVideos': videoUrls.isNotEmpty, // Firebase Storage 영상 여부
        'hasServerFeedback': false, // 아직 서버 피드백 없음
        'storageType': 'firebase', // Firebase Storage 사용 명시
      });

      print('🎉 기본 리포트 저장 완료! ID: $reportId');
      print('⏱️ 면접 소요 시간: ${duration ~/ 60}분 ${duration % 60}초');
      print('🎬 저장된 비디오 개수: ${videoUrls.length}개');
      print('📹 메인 비디오 URL 저장 완료: $mainVideoUrl');
      print('🔄 서버 AI 분석 대기 중...');

      return reportId;
    } catch (e) {
      print('❌ 리포트 생성 실패: $e');
      throw Exception('리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// === 서버 피드백을 Firestore에 저장 (새로 추가) ===
  /// 면접 완료 후 서버에서 받은 포즈 분석과 평가 결과를 저장합니다
  Future<void> updateInterviewFeedback({
    required String reportId,
    required String userId,
    String? poseAnalysis,
    String? evaluationResult,
  }) async {
    try {
      print('💾 서버 피드백 저장 시작...');
      print('  - 리포트 ID: $reportId');
      print('  - 사용자 ID: $userId');
      print('  - 포즈 분석 길이: ${poseAnalysis?.length ?? 0}자');
      print('  - 평가 결과 길이: ${evaluationResult?.length ?? 0}자');

      // 기존 리포트 문서 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        throw Exception('존재하지 않는 리포트입니다: $reportId');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('해당 리포트에 대한 접근 권한이 없습니다');
      }

      // 서버 피드백 데이터 준비
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        'serverFeedbackUpdatedAt': FieldValue.serverTimestamp(),
      };

      // 포즈 분석 결과가 있으면 추가
      if (poseAnalysis != null && poseAnalysis.isNotEmpty) {
        updateData['poseAnalysis'] = poseAnalysis;
        updateData['hasPoseAnalysis'] = true;
        print('✅ 포즈 분석 추가됨');
      }

      // 평가 결과가 있으면 추가하고 파싱하여 리포트 업데이트
      if (evaluationResult != null && evaluationResult.isNotEmpty) {
        updateData['evaluationResult'] = evaluationResult;
        updateData['hasEvaluationResult'] = true;

        // 평가 결과에서 피드백과 점수 추출 시도
        updateData['feedback'] = evaluationResult; // 전체 평가 결과를 피드백으로 사용

        // 평가 결과에서 점수 추출 (다양한 패턴 지원)
        print(
            '🔍 전체 피드백 점수 추출 시도: ${evaluationResult.substring(0, min(200, evaluationResult.length))}...');

        final scorePatterns = [
          RegExp(r'총점:\s*(\d+)\s*점'), // "총점: 85점"
          RegExp(r'점수:\s*(\d+)\s*점'), // "점수: 85점"
          RegExp(r'(\d+)\s*점'), // "85점"
          RegExp(r'총점:\s*(\d+)'), // "총점: 85"
          RegExp(r'점수:\s*(\d+)'), // "점수: 85"
          RegExp(r'Score:\s*(\d+)'), // "Score: 85" (영어)
        ];

        int score = 0;
        for (int i = 0; i < scorePatterns.length; i++) {
          final pattern = scorePatterns[i];
          final match = pattern.firstMatch(evaluationResult);
          if (match != null) {
            score = int.tryParse(match.group(1) ?? '0') ?? 0;
            print('✅ 전체 피드백 점수 추출 성공 (패턴 ${i + 1}): $score점');
            break;
          }
        }

        if (score > 0) {
          updateData['score'] = score;

          // 점수에 따른 등급 계산 (더 엄격한 기준)
          String grade = "F";
          if (score >= 95)
            grade = "A+";
          else if (score >= 90)
            grade = "A";
          else if (score >= 85)
            grade = "A-";
          else if (score >= 80)
            grade = "B+";
          else if (score >= 75)
            grade = "B";
          else if (score >= 70)
            grade = "B-";
          else if (score >= 65)
            grade = "C+";
          else if (score >= 60) grade = "C";

          updateData['grade'] = grade;
          print('📊 점수 추출됨: $score점 ($grade)');
        } else {
          print('⚠️ 전체 피드백 점수 추출 실패: 패턴이 매칭되지 않음');
        }

        // 기존 questionAnswers 보존 (videoUrls 배열은 더 이상 사용하지 않음)
        final existingQuestionAnswers = data['questionAnswers'] as List?;
        if (existingQuestionAnswers != null &&
            existingQuestionAnswers.isNotEmpty) {
          print(
              '✅ 기존 questionAnswers 데이터 보존됨 (${existingQuestionAnswers.length}개)');
        }

        print('✅ 평가 결과 추가됨');
      }

      // 상태 업데이트 (완료 상태 유지)
      updateData['status'] = 'completed';
      updateData['hasServerFeedback'] = true;

      // Firestore 문서 업데이트
      await _firestore.collection('reports').doc(reportId).update(updateData);

      print('🎉 서버 피드백 저장 완료!');
    } catch (e) {
      print('❌ 서버 피드백 저장 실패: $e');
      throw Exception('서버 피드백 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// === 질문별 실시간 피드백을 Firestore에 저장 ===
  /// 각 질문 답변 후 받은 실시간 피드백을 저장합니다
  Future<void> updateQuestionFeedback({
    required String reportId,
    required String userId,
    required int questionIndex,
    required String question,
    required String videoUrl,
    String? answer,
    String? poseAnalysis,
    String? evaluationResult,
  }) async {
    try {
      print('💾 질문별 피드백 저장 시작...');
      print('  - 리포트 ID: $reportId');
      print('  - 질문 번호: ${questionIndex + 1}');
      print(
          '  - 질문: ${question.length > 50 ? question.substring(0, 50) + '...' : question}');
      print('  - Firebase 영상 URL: ${videoUrl.isNotEmpty ? videoUrl : "영상 없음"}');

      // 기존 리포트 문서 조회
      final doc = await _firestore.collection('reports').doc(reportId).get();
      if (!doc.exists) {
        throw Exception('존재하지 않는 리포트입니다: $reportId');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        throw Exception('해당 리포트에 대한 접근 권한이 없습니다');
      }

      // 기존 questionAnswers 배열 가져오기 (questionFeedbacks 제거, questionAnswers만 사용)
      List<Map<String, dynamic>> questionAnswers =
          List<Map<String, dynamic>>.from(data['questionAnswers'] ?? []);

      // 평가 결과에서 점수 추출 (다양한 패턴 지원)
      int score = 0;
      if (evaluationResult != null && evaluationResult.isNotEmpty) {
        print(
            '🔍 점수 추출 시도: ${evaluationResult.substring(0, min(200, evaluationResult.length))}...');

        final scorePatterns = [
          RegExp(r'총점:\s*(\d+)\s*점'), // "총점: 85점"
          RegExp(r'점수:\s*(\d+)\s*점'), // "점수: 85점"
          RegExp(r'(\d+)\s*점'), // "85점"
          RegExp(r'총점:\s*(\d+)'), // "총점: 85"
          RegExp(r'점수:\s*(\d+)'), // "점수: 85"
          RegExp(r'Score:\s*(\d+)'), // "Score: 85" (영어)
        ];

        for (int i = 0; i < scorePatterns.length; i++) {
          final pattern = scorePatterns[i];
          final match = pattern.firstMatch(evaluationResult);
          if (match != null) {
            score = int.tryParse(match.group(1) ?? '0') ?? 0;
            print('✅ 점수 추출 성공 (패턴 ${i + 1}): $score점');
            break;
          }
        }

        if (score == 0) {
          print('⚠️ 점수 추출 실패: 패턴이 매칭되지 않음');
        }
      }

      // questionAnswers 형식으로 바로 저장 (Firebase Storage URL 포함)
      final questionAnswer = {
        'question': question,
        'answer': answer ?? '음성 인식 결과를 가져오지 못했습니다.',
        'videoUrl': videoUrl, // Firebase Storage 다운로드 URL
        'score': score,
        'evaluation': evaluationResult ?? '',
        'answerDuration': 60, // 기본값
        'poseAnalysis': poseAnalysis,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 기존 답변이 있는지 확인 (questionIndex 대신 question으로 찾기)
      final existingIndex =
          questionAnswers.indexWhere((qa) => qa['question'] == question);

      if (existingIndex >= 0) {
        // 기존 답변 업데이트
        questionAnswers[existingIndex] = questionAnswer;
        print('✅ 기존 답변 업데이트됨');
      } else {
        // 새 답변 추가
        questionAnswers.add(questionAnswer);
        print('✅ 새 답변 추가됨');
      }

      // Firestore 문서 업데이트 (questionFeedbacks 제거, questionAnswers만 사용)
      await _firestore.collection('reports').doc(reportId).update({
        'questionAnswers': questionAnswers,
        'hasQuestionAnswers': true,
        'lastQuestionFeedbackAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('🎉 질문 ${questionIndex + 1} 피드백 저장 완료!');
    } catch (e) {
      print('❌ 질문별 피드백 저장 실패: $e');
      throw Exception('질문별 피드백 저장 중 오류가 발생했습니다: $e');
    }
  }
}
