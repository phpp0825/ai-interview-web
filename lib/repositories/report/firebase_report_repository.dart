import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/report_model.dart';
import '../../models/resume_model.dart';

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

    // 새로운 면접 세부 정보 필드들 파싱
    List<QuestionAnswerModel>? questionAnswers;
    if (data['questionAnswers'] != null) {
      questionAnswers = (data['questionAnswers'] as List)
          .map((qa) => QuestionAnswerModel.fromJson(qa))
          .toList();
    }

    List<SkillEvaluationModel>? skillEvaluations;
    if (data['skillEvaluations'] != null) {
      skillEvaluations = (data['skillEvaluations'] as List)
          .map((se) => SkillEvaluationModel.fromJson(se))
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
      videoUrl: data['videoUrl'] ?? '',
      timestamps: timestamps,
      speechSpeedData: speechSpeedData,
      gazeData: gazeData,
      // 새로운 면접 세부 정보 필드들
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
  /// [videoUrls] - 각 질문별 비디오 URL 목록
  /// [resume] - 선택된 이력서 정보
  /// [duration] - 면접 소요 시간 (초)
  /// [userId] - 사용자 ID
  ///
  /// 반환값: 생성된 리포트 ID
  Future<String> generateInterviewReport({
    required List<String> questions,
    required List<String> videoUrls,
    required ResumeModel resume,
    required int duration,
    required String userId,
  }) async {
    try {
      print('📊 ReportModel 형식으로 면접 리포트 생성 시작...');

      // 리포트 ID 생성
      final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';

      // 목업 질문-답변 데이터 생성 (ReportModel용)
      final questionAnswers =
          _generateMockQuestionAnswersForReport(questions, videoUrls);

      // 목업 기술 평가 생성 (ReportModel용)
      final skillEvaluations = _generateMockSkillEvaluationsForReport();

      // 목업 피드백 생성
      final feedback = _generateMockFeedback();

      // 타임스탬프 생성 (질문-답변 기반)
      final timestamps = _generateTimestampsFromQuestions(questionAnswers);

      // 말하기 속도 데이터 생성 (목업)
      final speechSpeedData = _generateSpeechSpeedData(duration);

      // 시선 처리 데이터 생성 (목업)
      final gazeData = _generateGazeData();

      // 전체 점수 계산
      final totalScore = questionAnswers.isNotEmpty
          ? (questionAnswers.map((qa) => qa.score).reduce((a, b) => a + b) /
                  questionAnswers.length)
              .round()
          : 82;

      // 등급 계산
      final grade = _calculateGrade(totalScore);

      // 카테고리별 점수 생성
      final categoryScores = {
        '기술적 지식': 85,
        '문제 해결 능력': 80,
        '커뮤니케이션': 78,
        '경험 및 사례': 84,
        '학습 의지': 88,
      };

      // ReportModel 직접 생성
      final report = ReportModel(
        id: reportId,
        title: '${resume.position} 면접 리포트',
        date: DateTime.now(),
        field: resume.field,
        position: resume.position,
        interviewType: '직무면접',
        duration: duration,
        score: totalScore,
        videoUrl: videoUrls.isNotEmpty ? videoUrls.first : '',
        timestamps: timestamps,
        speechSpeedData: speechSpeedData,
        gazeData: gazeData,
        // 새로 추가된 면접 세부 정보
        questionAnswers: questionAnswers,
        skillEvaluations: skillEvaluations,
        feedback: feedback,
        grade: grade,
        categoryScores: categoryScores,
      );

      // Firestore의 reports 컬렉션에 저장 (단일 컬렉션 사용!)
      await _firestore.collection('reports').doc(reportId).set({
        ...report.toJson(),
        'userId': userId,
        'resumeId': resume.resume_id.isNotEmpty ? resume.resume_id : reportId,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('🎉 ReportModel 형식 리포트 저장 완료! ID: $reportId');
      print('⏱️ 면접 소요 시간: ${duration ~/ 60}분 ${duration % 60}초');
      print('🎬 비디오 개수: ${videoUrls.length}개');
      print('📊 총점: $totalScore점 ($grade)');

      return reportId;
    } catch (e) {
      print('❌ ReportModel 형식 리포트 생성 실패: $e');
      throw Exception('리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 목업 질문-답변 데이터 생성 (ReportModel용)
  List<QuestionAnswerModel> _generateMockQuestionAnswersForReport(
    List<String> questions,
    List<String> videoUrls,
  ) {
    // 백엔드 개발자용 목업 답변들
    final List<String> mockAnswers = [
      '안녕하세요. 3년간 Spring Boot와 Node.js를 활용한 백엔드 개발 경험이 있습니다. 주로 RESTful API 설계와 마이크로서비스 아키텍처 구축을 담당했습니다.',
      '주로 Java Spring Boot, Node.js, Python Django를 사용합니다. Spring Boot는 엔터프라이즈급 애플리케이션에 적합하고, Node.js는 실시간 서비스에 효율적이기 때문입니다.',
      'REST API는 HTTP 프로토콜을 활용한 단순한 구조로 캐싱이 용이하고, GraphQL은 클라이언트가 필요한 데이터만 요청할 수 있어 효율적입니다. 프로젝트 요구사항에 따라 선택합니다.',
      '정규화는 데이터 무결성을 보장하고 중복을 제거합니다. 비정규화는 조회 성능 향상을 위해 사용하며, 대용량 데이터나 복잡한 조인이 필요한 경우 적용합니다.',
      '캐싱 전략(Redis), 데이터베이스 인덱싱, 비동기 처리, 로드 밸런싱을 통해 성능을 최적화했습니다. 특히 Redis를 활용한 세션 관리로 응답 시간을 50% 단축시켰습니다.',
      '마이크로서비스는 독립적인 배포와 확장이 가능하지만, 서비스 간 통신 복잡성과 데이터 일관성 관리가 어렵습니다. 팀 규모와 시스템 복잡도를 고려해야 합니다.',
      'JWT 토큰 인증, SQL Injection 방지, CORS 설정, HTTPS 적용, 입력값 검증을 통해 보안을 강화합니다. 정기적인 보안 감사도 실시합니다.',
      '대용량 파일 업로드 처리 중 메모리 부족 문제가 발생했습니다. 스트리밍 방식으로 변경하고 청크 단위 처리를 구현하여 해결했습니다.',
    ];

    final List<QuestionAnswerModel> questionAnswers = [];

    for (int i = 0; i < questions.length; i++) {
      final videoUrl = i < videoUrls.length ? videoUrls[i] : '';
      final answer = i < mockAnswers.length ? mockAnswers[i] : '답변 데이터가 없습니다.';

      questionAnswers.add(QuestionAnswerModel(
        question: questions[i],
        answer: answer,
        videoUrl: videoUrl,
        score: 75 + (i * 3) % 20, // 75~94점 범위
        evaluation: _getEvaluationForScore(75 + (i * 3) % 20),
        answerDuration: 45 + (i * 5) % 25, // 45~69초 범위
      ));
    }

    return questionAnswers;
  }

  /// 목업 기술 평가 생성 (ReportModel용)
  List<SkillEvaluationModel> _generateMockSkillEvaluationsForReport() {
    return [
      SkillEvaluationModel(
        skillName: 'Java/Spring Boot',
        score: 85,
        level: '상급',
        comment: '프레임워크에 대한 깊이 있는 이해와 실무 적용 경험이 우수합니다.',
      ),
      SkillEvaluationModel(
        skillName: 'REST API 설계',
        score: 82,
        level: '상급',
        comment: 'API 설계 원칙을 잘 이해하고 있으며 실제 구현 경험이 풍부합니다.',
      ),
      SkillEvaluationModel(
        skillName: '데이터베이스',
        score: 78,
        level: '중급',
        comment: '기본적인 DB 지식은 갖추고 있으나 성능 최적화 부분에서 더 학습이 필요합니다.',
      ),
      SkillEvaluationModel(
        skillName: '시스템 아키텍처',
        score: 80,
        level: '중급',
        comment: '마이크로서비스에 대한 이해가 있으며 실제 적용 경험도 보유하고 있습니다.',
      ),
      SkillEvaluationModel(
        skillName: '보안',
        score: 75,
        level: '중급',
        comment: '기본적인 보안 지식은 있으나 고급 보안 기법에 대한 추가 학습이 권장됩니다.',
      ),
    ];
  }

  /// 질문-답변에서 타임스탬프 생성
  List<TimeStampModel> _generateTimestampsFromQuestions(
      List<QuestionAnswerModel> questionAnswers) {
    final List<TimeStampModel> timestamps = [];
    int currentTime = 0;

    for (int i = 0; i < questionAnswers.length && i < 8; i++) {
      final qa = questionAnswers[i];

      timestamps.add(TimeStampModel(
        time: currentTime,
        label: '질문 ${i + 1}',
        description: qa.question.length > 50
            ? '${qa.question.substring(0, 50)}...'
            : qa.question,
      ));

      currentTime += qa.answerDuration as int;
    }

    return timestamps;
  }

  /// 말하기 속도 데이터 생성
  List<FlSpot> _generateSpeechSpeedData(int duration) {
    final List<FlSpot> data = [];
    for (int i = 0; i <= duration; i += 10) {
      data.add(FlSpot(
        i.toDouble(),
        (120 + (i % 40) - 20).toDouble(), // 100~140 범위의 WPM
      ));
    }
    return data;
  }

  /// 시선 처리 데이터 생성
  List<ScatterSpot> _generateGazeData() {
    final List<ScatterSpot> data = [];
    for (int i = 0; i < 15; i++) {
      data.add(ScatterSpot(
        (i * 0.1 + 0.2).toDouble(), // 0.2~0.8 범위
        (0.3 + (i % 5) * 0.1).toDouble(), // 0.3~0.7 범위
        color: i < 5 ? Colors.green : (i < 10 ? Colors.blue : Colors.red),
        radius: 4.0,
      ));
    }
    return data;
  }

  /// 점수에 따른 등급 계산
  String _calculateGrade(int score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'B+';
    if (score >= 80) return 'B';
    if (score >= 75) return 'C+';
    if (score >= 70) return 'C';
    if (score >= 65) return 'D+';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// 점수에 따른 평가 코멘트 생성
  String _getEvaluationForScore(int score) {
    if (score >= 90) {
      return '좋은 답변입니다. 기술적 이해도가 높고 실무 경험이 풍부합니다.';
    } else if (score >= 70) {
      return '무난한 답변입니다. 기본적인 지식은 갖추고 있으나 더 구체적인 설명이 필요합니다.';
    } else {
      return '개선이 필요한 답변입니다. 더 깊이 있는 학습과 경험이 필요합니다.';
    }
  }

  /// 목업 피드백 생성
  String _generateMockFeedback() {
    return '''
📋 **면접 종합 평가**

**🎯 강점:**
• 백엔드 개발에 대한 전반적인 기술 지식이 우수합니다
• 실무 경험을 바탕으로 한 구체적인 사례 제시가 좋았습니다
• 새로운 기술에 대한 학습 의지가 높아 보입니다
• 문제 해결 접근 방식이 체계적입니다

**📈 개선 필요 사항:**
• 대용량 트래픽 처리 경험을 더 구체적으로 설명할 필요가 있습니다
• 보안 관련 지식을 더 깊이 있게 학습하시기 바랍니다
• 클라우드 서비스 활용 경험을 쌓으시면 좋겠습니다

**💡 추천 학습 방향:**
• AWS/GCP 등 클라우드 플랫폼 학습
• Redis, Elasticsearch 등 고급 기술 스택 경험
• 모니터링 및 로깅 시스템 구축 경험
• DevOps 및 CI/CD 파이프라인 구축

**📊 최종 평가:** 
전반적으로 백엔드 개발자로서 필요한 기본기를 잘 갖추고 있으며, 
지속적인 학습을 통해 시니어 개발자로 성장할 수 있는 잠재력을 보여주었습니다.
    ''';
  }
}
