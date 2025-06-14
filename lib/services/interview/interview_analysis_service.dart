import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import 'interview_submission_service.dart';
import '../../repositories/report/firebase_report_repository.dart';

/// 면접 분석 및 피드백 처리를 담당하는 서비스
/// 서버 분석 요청, 텍스트 정리, 피드백 저장 등을 처리합니다
class InterviewAnalysisService {
  final _submissionService = InterviewSubmissionService();
  final _reportRepository = FirebaseReportRepository();

  bool _isAnalyzingVideo = false;
  VoidCallback? _onStateChanged;

  // === Getters ===
  bool get isAnalyzingVideo => _isAnalyzingVideo;

  /// 상태 변경 콜백 설정
  void setStateChangedCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  /// 모든 영상을 서버로 분석 요청
  Future<void> analyzeAllVideos({
    required List<String> videoUrls,
    required List<String> questions,
    String? reportId,
  }) async {
    try {
      print('🤖 면접 분석 시작 - ${videoUrls.length}개 영상 처리...');

      _isAnalyzingVideo = true;
      _notifyStateChanged();

      if (videoUrls.isEmpty) {
        print('⚠️ 업로드된 영상이 없어서 분석을 건너뜁니다.');
        return;
      }

      // 서버 연결 테스트
      print('🔌 서버 연결 상태 확인 중...');
      final isServerAvailable = await _submissionService.testServerConnection();
      if (!isServerAvailable) {
        print('⚠️ 서버에 연결할 수 없어서 분석을 건너뜁니다.');
        return;
      }
      print('✅ 서버 연결 확인됨');

      print('📋 질문 개수: ${questions.length}개');
      print('🎬 영상 개수: ${videoUrls.length}개');

      // 각 영상별로 분석 진행
      for (int i = 0; i < videoUrls.length && i < questions.length; i++) {
        final videoUrl = videoUrls[i];
        final question = questions[i];

        print('📹 영상 ${i + 1} 분석 시작: 질문 "${safeSubstring(question, 30)}..."');

        try {
          await _analyzeVideo(
            videoUrl: videoUrl,
            question: question,
            questionIndex: i,
            reportId: reportId,
          );
        } catch (e) {
          print('❌ 영상 ${i + 1} 처리 중 오류: $e');
        }

        // 다음 영상 처리 전 잠시 대기 (서버 부하 방지)
        if (i < videoUrls.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      print('🎉 모든 영상 분석 완료!');
    } catch (e) {
      print('❌ 영상 분석 중 오류: $e');
    } finally {
      _isAnalyzingVideo = false;
      _notifyStateChanged();
    }
  }

  /// 안전한 문자열 자르기
  String safeSubstring(String text, int maxLength) {
    try {
      final cleanText = cleanUtf8String(text);
      if (cleanText.length <= maxLength) {
        return cleanText;
      }
      return cleanText.substring(0, maxLength);
    } catch (e) {
      return '문자 인코딩 오류';
    }
  }

  /// UTF-8 문자열 정리
  String cleanUtf8String(String input) {
    try {
      String cleaned = input.replaceAll('�', '');
      cleaned =
          cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
      cleaned = cleaned.replaceAll(RegExp(r'[·․‧∙•]'), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
      cleaned = cleaned.replaceAll(
          RegExp(r'[^\w\sㄱ-ㅎㅏ-ㅣ가-힣.,!?():;"\' '-]', unicode: true), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      return cleaned.isEmpty ? '인식할 수 없는 텍스트' : cleaned;
    } catch (e) {
      return '텍스트 정리 오류';
    }
  }

  /// 개별 영상 분석 처리
  Future<void> _analyzeVideo({
    required String videoUrl,
    required String question,
    required int questionIndex,
    String? reportId,
  }) async {
    try {
      // Firebase Storage URL인지 확인하고 직접 전달
      if (videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        print('🔗 Firebase Storage URL을 서버에 직접 전달합니다...');

        final analysisResult =
            await _submissionService.getCompleteAnalysisFromUrl(
          videoUrl: videoUrl,
          questions: [question],
        );

        if (analysisResult.success) {
          print('✅ 영상 ${questionIndex + 1} URL 분석 성공!');

          final extractedAnswer =
              _extractAnswerFromEvaluation(analysisResult.evaluationResult);

          await _saveQuestionFeedback(
            questionIndex: questionIndex,
            question: question,
            videoUrl: videoUrl,
            answer: extractedAnswer,
            poseAnalysis: analysisResult.poseAnalysis,
            evaluationResult: analysisResult.evaluationResult,
            reportId: reportId,
          );

          print('💾 질문 ${questionIndex + 1} 피드백이 저장되었습니다.');
        } else {
          print('❌ 영상 ${questionIndex + 1} URL 분석 실패');
        }
        return;
      }

      // 다른 형식이면 바이트 다운로드 시도
      final videoBytes = await _loadVideoBytes(videoUrl);
      if (videoBytes == null) {
        print('❌ 영상 ${questionIndex + 1} 바이트 로드 실패');
        return;
      }

      print(
          '✅ 영상 ${questionIndex + 1} 바이트 로드 성공: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

      final analysisResult = await _submissionService.getCompleteAnalysis(
        videoData: videoBytes,
        questions: [question],
      );

      if (analysisResult.success) {
        print('✅ 영상 ${questionIndex + 1} 분석 성공!');

        final extractedAnswer =
            _extractAnswerFromEvaluation(analysisResult.evaluationResult);

        await _saveQuestionFeedback(
          questionIndex: questionIndex,
          question: question,
          videoUrl: videoUrl,
          answer: extractedAnswer,
          poseAnalysis: analysisResult.poseAnalysis,
          evaluationResult: analysisResult.evaluationResult,
          reportId: reportId,
        );

        print('💾 질문 ${questionIndex + 1} 피드백이 저장되었습니다.');
      } else {
        print('❌ 영상 ${questionIndex + 1} 분석 실패');
      }
    } catch (e) {
      print('❌ 영상 ${questionIndex + 1} 분석 처리 중 오류: $e');
    }
  }

  /// Firebase Storage 영상을 바이트로 로드
  Future<Uint8List?> _loadVideoBytes(String videoUrl) async {
    try {
      if (videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        return await _downloadVideoFromFirebase(videoUrl);
      }

      print('⚠️ 지원하지 않는 URL 형식입니다: ${safeSubstring(videoUrl, 50)}...');
      return null;
    } catch (e) {
      print('❌ 영상 바이트 로드 중 오류: $e');
      return null;
    }
  }

  /// Firebase에서 영상 다운로드
  Future<Uint8List?> _downloadVideoFromFirebase(String videoUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(videoUrl);
      final videoBytes = await ref.getData();

      if (videoBytes != null) {
        print(
            '✅ Firebase Storage 다운로드 성공: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        return videoBytes;
      }

      return null;
    } catch (e) {
      print('❌ Firebase Storage 다운로드 중 오류: $e');

      // HTTP를 통한 대안 다운로드 시도
      try {
        final response = await http.get(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (httpError) {
        print('❌ HTTP 다운로드도 실패: $httpError');
      }

      return null;
    }
  }

  /// 질문별 피드백을 Firestore에 저장
  Future<void> _saveQuestionFeedback({
    required int questionIndex,
    required String question,
    required String videoUrl,
    String? answer,
    String? poseAnalysis,
    String? evaluationResult,
    String? reportId,
  }) async {
    try {
      if (reportId == null) {
        print('⚠️ 리포트 ID가 없어서 피드백 저장을 건너뜁니다.');
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ 로그인된 사용자가 없어서 피드백 저장을 건너뜁니다.');
        return;
      }

      await _reportRepository.updateQuestionFeedback(
        reportId: reportId,
        userId: currentUser.uid,
        questionIndex: questionIndex,
        question: question,
        videoUrl: videoUrl, // 영상 URL은 이미 저장되어 있음
        answer: answer,
        poseAnalysis: poseAnalysis,
        evaluationResult: evaluationResult,
      );
    } catch (e) {
      print('❌ 질문별 피드백 저장 중 오류: $e');
    }
  }

  /// 상태 변경 알림
  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  /// 평가 결과에서 STT 답변 추출
  String? _extractAnswerFromEvaluation(String? evaluationResult) {
    if (evaluationResult == null || evaluationResult.isEmpty) {
      return null;
    }

    try {
      print(
          '🔍 답변 추출 시도: ${evaluationResult.substring(0, min(300, evaluationResult.length))}...');

      // 1. 먼저 서버 로그에서 STT 결과 직접 추출 시도
      final sttPattern = RegExp(r'STT 완료:\s*(.+?)(?=\n|$)', multiLine: true);
      final sttMatch = sttPattern.firstMatch(evaluationResult);
      if (sttMatch != null) {
        final sttResult = cleanUtf8String(sttMatch.group(1) ?? '');
        if (sttResult.length > 5) {
          print(
              '✅ STT 로그에서 답변 추출 성공: ${sttResult.substring(0, min(50, sttResult.length))}...');
          return sttResult;
        }
      }

      final lines = evaluationResult.split('\n');
      bool foundAnswerSection = false;

      // 2. "사용자 답변:" 또는 유사한 섹션 찾기
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        if (line.contains('사용자 답변:') ||
            line.contains('답변:') ||
            line.contains('사용자의 답변:') ||
            line.contains('인터뷰 답변:') ||
            line.contains('면접자 답변:')) {
          foundAnswerSection = true;
          continue;
        }

        // 답변 섹션을 찾았고, 비어있지 않은 다음 줄이 답변
        if (foundAnswerSection && line.isNotEmpty) {
          final cleanedAnswer = cleanUtf8String(line);
          if (cleanedAnswer.length > 5 &&
              !cleanedAnswer.startsWith('평가') &&
              !cleanedAnswer.startsWith('점수') &&
              !cleanedAnswer.startsWith('총점') &&
              !cleanedAnswer.contains('relevance:') &&
              !cleanedAnswer.startsWith('질문') &&
              !cleanedAnswer.contains('rating') &&
              !cleanedAnswer.contains('comment')) {
            print(
                '✅ 답변 섹션에서 추출 성공: ${cleanedAnswer.substring(0, min(50, cleanedAnswer.length))}...');
            return cleanedAnswer;
          }
        }
      }

      // 3. 한국어 문장 패턴으로 답변 찾기 (안녕하세요로 시작하는 등)
      for (final line in lines) {
        final trimmed = cleanUtf8String(line.trim());
        if (trimmed.length > 15 &&
            (trimmed.startsWith('안녕하세요') ||
                trimmed.startsWith('저는') ||
                trimmed.startsWith('네,') ||
                trimmed.startsWith('감사합니다') ||
                trimmed.contains('지원') ||
                trimmed.contains('개발') ||
                trimmed.contains('회사')) &&
            !trimmed.contains('평가') &&
            !trimmed.contains('점수') &&
            !trimmed.contains('relevance') &&
            !trimmed.contains('rating') &&
            !trimmed.contains('==')) {
          print(
              '✅ 한국어 패턴으로 답변 추출 성공: ${trimmed.substring(0, min(50, trimmed.length))}...');
          return trimmed;
        }
      }

      // 4. 대안: 가장 긴 의미있는 텍스트 줄을 답변으로 간주
      String? longestLine;
      int maxLength = 0;

      for (final line in lines) {
        final trimmed = cleanUtf8String(line.trim());
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('질문:') &&
            !trimmed.startsWith('점수:') &&
            !trimmed.startsWith('총점:') &&
            !trimmed.startsWith('평가:') &&
            !trimmed.startsWith('피드백:') &&
            !trimmed.contains('relevance:') &&
            !trimmed.contains('completeness:') &&
            !trimmed.contains('correctness:') &&
            !trimmed.contains('clarity:') &&
            !trimmed.contains('professionalism:') &&
            !trimmed.contains('rating') &&
            !trimmed.contains('comment') &&
            !trimmed.contains('==') &&
            !trimmed.contains('LLM') &&
            !trimmed.contains('JSON') &&
            trimmed.length > maxLength) {
          maxLength = trimmed.length;
          longestLine = trimmed;
        }
      }

      if (longestLine != null && longestLine.length > 10) {
        print(
            '✅ 가장 긴 줄로 답변 추출 성공: ${longestLine.substring(0, min(50, longestLine.length))}...');
        return longestLine;
      }

      print('⚠️ 답변 추출 실패: 적절한 답변을 찾을 수 없음');
      print('📋 평가 결과 전체 (디버깅용): $evaluationResult');
      return null;
    } catch (e) {
      print('❌ STT 결과 추출 중 오류: $e');
      return null;
    }
  }

  /// 메모리 정리
  void dispose() {
    _onStateChanged = null;
  }
}
