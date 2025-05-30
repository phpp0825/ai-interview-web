import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';

/// 목업 리포트 데이터 생성 서비스
/// 실제 AI 분석 대신 샘플 데이터를 생성하여 앱의 흐름을 테스트할 수 있게 해줍니다.
/// 초보 개발자를 위한 학습용 목업 서비스입니다.
class MockReportDataService {
  /// 백엔드 개발자를 위한 목업 질문-답변 데이터 생성
  /// [questions] - 면접 질문 목록
  /// [videoUrls] - 각 질문별 비디오 URL 목록
  ///
  /// 반환값: QuestionAnswerModel 리스트 (실제 비디오가 있는 질문들만)
  static List<QuestionAnswerModel> generateMockQuestionAnswers(
    List<String> questions,
    List<String> videoUrls,
  ) {
    // 백엔드 개발자용 실제 면접 질문들
    final List<String> defaultQuestions = [
      '자기소개를 해주시고, 본인의 주요 경험을 간단히 말씀해 주세요.',
      '주로 사용하는 백엔드 기술 스택은 무엇이며, 그 기술을 선택한 이유는 무엇인가요?',
      'REST API와 GraphQL의 차이점을 설명하고, 어떤 상황에서 각각을 사용하는지 말씀해 주세요.',
      '데이터베이스 정규화와 비정규화에 대해 설명하고, 실무에서 어떻게 활용했는지 말씀해 주세요.',
      '대용량 트래픽을 처리하기 위해 어떤 최적화 기법을 사용해 보셨나요?',
      '마이크로서비스 아키텍처의 장단점에 대해 말씀해 주시고, 언제 사용하는 것이 좋다고 생각하시나요?',
      '웹 애플리케이션의 보안을 위해 어떤 방법들을 적용해 보셨나요?',
      '개발 중 가장 어려웠던 기술적 문제는 무엇이었고, 어떻게 해결하셨나요?',
    ];

    // 백엔드 개발자용 목업 답변들
    final List<String> mockAnswers = [
      '안녕하세요. 3년간 Spring Boot와 Node.js를 활용한 백엔드 개발 경험이 있습니다. 주로 RESTful API 설계와 마이크로서비스 아키텍처 구축을 담당했고, 대용량 사용자를 위한 서비스 최적화 작업을 해왔습니다.',
      '주로 Java Spring Boot, Node.js, Python Django를 사용합니다. Spring Boot는 엔터프라이즈급 애플리케이션에 적합하고 안정성이 뛰어나며, Node.js는 실시간 서비스와 API 게이트웨이에 효율적이기 때문입니다.',
      'REST API는 HTTP 프로토콜 기반의 단순한 구조로 캐싱이 용이하고 확장성이 좋습니다. GraphQL은 클라이언트가 필요한 데이터만 요청할 수 있어 네트워크 효율성이 높습니다. 복잡한 데이터 관계가 있는 경우 GraphQL을, 단순한 CRUD는 REST를 선택합니다.',
      '정규화는 데이터 무결성을 보장하고 중복을 제거하여 저장 공간을 절약합니다. 비정규화는 조회 성능 향상을 위해 사용하며, 대용량 데이터 분석이나 복잡한 조인이 자주 발생하는 테이블에 적용했습니다.',
      '여러 최적화 기법을 적용했습니다. Redis를 활용한 캐싱 전략, 데이터베이스 인덱싱 최적화, 비동기 처리를 통한 응답 시간 단축, 로드 밸런싱을 통한 서버 분산 처리를 구현했습니다. 특히 Redis 세션 캐싱으로 응답 시간을 50% 단축시켰습니다.',
      '마이크로서비스는 독립적인 배포와 확장이 가능하고 기술 스택을 다양화할 수 있습니다. 하지만 서비스 간 통신 복잡성과 데이터 일관성 관리가 어렵습니다. 팀 규모가 크고 시스템이 복잡할 때 사용하는 것이 좋다고 생각합니다.',
      'JWT 토큰 기반 인증, SQL Injection 방지를 위한 Prepared Statement, CORS 설정, HTTPS 적용, 입력값 검증 및 sanitization을 구현했습니다. 또한 정기적인 의존성 보안 감사와 로그 모니터링도 실시했습니다.',
      '대용량 파일 업로드 처리 중 메모리 부족과 타임아웃 문제가 발생했습니다. 스트리밍 방식으로 변경하고 청크 단위 처리를 구현하여 메모리 사용량을 최적화했으며, 비동기 처리로 업로드 시간을 단축시켰습니다.',
    ];

    // 현실적인 답변 시간 (30초~90초)
    final List<int> answerDurations = [55, 48, 72, 65, 84, 76, 58, 88];

    final List<QuestionAnswerModel> questionAnswers = [];

    // 실제 질문이 있으면 사용하고, 없으면 기본 질문 사용
    final List<String> finalQuestions =
        questions.isNotEmpty ? questions : defaultQuestions;

    // 비디오 URL이 없으면 빈 리스트 반환
    if (videoUrls.isEmpty) {
      print('📭 녹화된 영상이 없어서 질문-답변 데이터를 생성하지 않습니다.');
      return [];
    }

    print('🎬 실제 녹화된 영상 기반으로 질문-답변 데이터 생성 - 영상 개수: ${videoUrls.length}개');

    // 실제 비디오 URL 개수만큼만 질문-답변 모델 생성
    for (int i = 0; i < videoUrls.length && i < finalQuestions.length; i++) {
      final videoUrl = videoUrls[i];

      // 비어있는 URL은 스킵
      if (videoUrl.isEmpty) {
        print('⚠️ 질문 ${i + 1}: 비어있는 비디오 URL, 스킵');
        continue;
      }

      print(
          '🎬 질문 ${i + 1}: 실제 Firebase Storage 비디오 사용 - ${videoUrl.substring(0, videoUrl.length > 50 ? 50 : videoUrl.length)}...');

      final answer = i < mockAnswers.length ? mockAnswers[i] : '답변 데이터가 없습니다.';
      final duration = i < answerDurations.length ? answerDurations[i] : 60;

      // 점수를 더 현실적으로 분배 (70~95점)
      final baseScore = 78;
      final variation = [2, -3, 8, 1, 6, -2, 0, 12];
      final score = baseScore + (i < variation.length ? variation[i] : 0);

      questionAnswers.add(QuestionAnswerModel(
        question: finalQuestions[i],
        answer: answer,
        videoUrl: videoUrl,
        score: score.clamp(70, 95),
        evaluation: getEvaluationForScore(score),
        answerDuration: duration,
      ));
    }

    print('✅ 총 ${questionAnswers.length}개 질문 카드 생성 완료 (실제 녹화된 영상만)');

    return questionAnswers;
  }

  /// 목업 기술 평가 데이터 생성
  /// 백엔드 개발자의 주요 기술 스택을 평가합니다.
  static List<SkillEvaluationModel> generateMockSkillEvaluations() {
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

  /// 말하기 속도 차트 데이터 생성
  /// [duration] - 면접 진행 시간 (초)
  ///
  /// 반환값: FlSpot 리스트 (시간별 말하기 속도 데이터)
  static List<FlSpot> generateSpeechSpeedData(int duration) {
    final List<FlSpot> data = [];

    // 10초 간격으로 데이터 포인트 생성
    for (int i = 0; i <= duration; i += 10) {
      // 100~140 WPM(Words Per Minute) 범위의 자연스러운 속도 변화
      double speed = 120 + (i % 40) - 20; // 기본 120WPM에서 ±20 변동

      data.add(FlSpot(
        i.toDouble(), // x축: 시간 (초)
        speed, // y축: 말하기 속도 (WPM)
      ));
    }

    return data;
  }

  /// 시선 처리 분석 데이터 생성
  /// 면접 중 지원자의 시선 패턴을 시뮬레이션합니다.
  ///
  /// 반환값: ScatterSpot 리스트 (시선 위치 데이터)
  static List<ScatterSpot> generateGazeData() {
    final List<ScatterSpot> data = [];

    // 시선이 주로 중앙에 집중되도록 더 현실적인 데이터 생성
    final List<double> xPositions = [
      -1.0,
      -0.5,
      0.0,
      0.5,
      1.0
    ]; // 왼쪽, 왼쪽-중앙, 중앙, 오른쪽-중앙, 오른쪽

    final List<double> yPositions = [
      -1.0,
      -0.5,
      0.0,
      0.5,
      1.0
    ]; // 아래, 아래-중앙, 중앙, 위-중앙, 위

    // 면접 중 시선 패턴을 시뮬레이션 (총 20개 포인트)
    for (int i = 0; i < 20; i++) {
      double x, y;

      if (i < 14) {
        // 중앙 영역에 더 많은 데이터 포인트 생성 (70% 확률)
        // 이는 실제 면접에서 지원자가 면접관을 바라보는 패턴을 반영
        x = (i % 2 == 0 ? -0.3 : 0.3) + (i * 0.05 - 0.35);
        y = (i % 3 == 0 ? -0.2 : 0.2) + (i * 0.03 - 0.3);
      } else {
        // 외곽 영역 (30% 확률)
        // 생각하거나 긴장할 때 시선이 잠깐 벗어나는 패턴
        x = xPositions[i % xPositions.length];
        y = yPositions[(i + 1) % yPositions.length];
      }

      // 값의 범위를 차트 범위 내로 제한 (-1.0 ~ 1.0)
      x = x.clamp(-1.0, 1.0);
      y = y.clamp(-1.0, 1.0);

      data.add(ScatterSpot(
        x, // x축: 수평 시선 위치
        y, // y축: 수직 시선 위치
        color: getGazeColor(x, y), // 시선 위치에 따른 색상
        radius: 3.0 + (i % 3), // 3.0~5.0 범위의 점 크기
      ));
    }

    return data;
  }

  /// 시선 위치에 따른 색상 결정
  /// 중앙에 가까울수록 좋은 평가, 멀어질수록 개선이 필요한 평가
  ///
  /// [x] - 수평 시선 위치 (-1.0 ~ 1.0)
  /// [y] - 수직 시선 위치 (-1.0 ~ 1.0)
  ///
  /// 반환값: 시선 평가에 따른 색상
  static Color getGazeColor(double x, double y) {
    // 중심(0,0)으로부터의 거리 계산
    double distance = (x * x + y * y).clamp(0.0, 2.0);

    if (distance < 0.5) {
      return Colors.green; // 중앙 - 좋은 시선 접촉
    } else if (distance < 1.0) {
      return Colors.blue; // 중간 영역 - 보통 시선
    } else {
      return Colors.orange; // 외곽 - 개선 필요한 시선
    }
  }

  /// 질문-답변에서 타임스탬프 생성
  /// 비디오 플레이어에서 특정 질문으로 바로 이동할 수 있게 해주는 데이터
  ///
  /// [questionAnswers] - 질문-답변 모델 리스트
  ///
  /// 반환값: TimeStampModel 리스트
  static List<TimeStampModel> generateTimestampsFromQuestions(
      List<QuestionAnswerModel> questionAnswers) {
    final List<TimeStampModel> timestamps = [];
    int currentTime = 0;

    // 최대 8개 질문까지만 타임스탬프 생성
    for (int i = 0; i < questionAnswers.length && i < 8; i++) {
      final qa = questionAnswers[i];

      timestamps.add(TimeStampModel(
        time: currentTime,
        label: '질문 ${i + 1}',
        description: qa.question.length > 50
            ? '${qa.question.substring(0, 50)}...'
            : qa.question,
      ));

      // 다음 질문 시작 시간 계산
      currentTime += qa.answerDuration as int;
    }

    return timestamps;
  }

  /// 점수에 따른 등급 계산
  /// A+부터 F까지의 등급을 반환합니다.
  ///
  /// [score] - 면접 점수 (0~100)
  ///
  /// 반환값: 등급 문자열
  static String calculateGrade(int score) {
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
  /// 각 답변에 대한 개별 피드백을 제공합니다.
  ///
  /// [score] - 해당 답변의 점수
  ///
  /// 반환값: 평가 코멘트 문자열
  static String getEvaluationForScore(int score) {
    if (score >= 90) {
      return '아주 좋은 답변입니다. 기술적 이해도가 높고 실무 경험이 풍부합니다.';
    } else if (score >= 80) {
      return '좋은 답변입니다. 전반적으로 잘 이해하고 있으나 조금 더 구체적인 설명이 있으면 더 좋겠습니다.';
    } else if (score >= 70) {
      return '무난한 답변입니다. 기본적인 지식은 갖추고 있으나 더 깊이 있는 설명이 필요합니다.';
    } else {
      return '개선이 필요한 답변입니다. 더 깊이 있는 학습과 실무 경험이 필요합니다.';
    }
  }

  /// 종합적인 면접 피드백 생성
  /// 전체 면접에 대한 상세한 피드백을 제공합니다.
  ///
  /// 반환값: 마크다운 형식의 피드백 문자열
  static String generateMockFeedback() {
    return '''
📋 **면접 종합 평가**

**🎯 강점:**
• 백엔드 개발에 대한 전반적인 기술 지식이 우수합니다
• 실무 경험을 바탕으로 한 구체적인 사례 제시가 좋았습니다
• 새로운 기술에 대한 학습 의지가 높아 보입니다
• 문제 해결 접근 방식이 체계적이고 논리적입니다

**📈 개선 필요 사항:**
• 대용량 트래픽 처리 경험을 더 구체적으로 설명할 필요가 있습니다
• 보안 관련 지식을 더 깊이 있게 학습하시기 바랍니다
• 클라우드 서비스 활용 경험을 쌓으시면 좋겠습니다
• 팀 협업과 커뮤니케이션 경험을 더 많이 언급하세요

**💡 추천 학습 방향:**
• AWS/GCP 등 클라우드 플랫폼 학습
• Redis, Elasticsearch 등 고급 기술 스택 경험
• 모니터링 및 로깅 시스템 구축 경험
• DevOps 및 CI/CD 파이프라인 구축
• 대규모 서비스 아키텍처 설계 경험

**📊 최종 평가:** 
전반적으로 백엔드 개발자로서 필요한 기본기를 잘 갖추고 있으며, 
지속적인 학습을 통해 시니어 개발자로 성장할 수 있는 잠재력을 보여주었습니다.

**🚀 앞으로의 성장 방향:**
기술적 깊이를 더하고, 다양한 프로젝트 경험을 쌓으면서 
리더십과 아키텍처 설계 능력을 기르시기 바랍니다.
    ''';
  }

  /// 카테고리별 점수 생성
  /// 면접 평가의 세부 항목별 점수를 제공합니다.
  ///
  /// 반환값: 카테고리명과 점수의 맵
  static Map<String, int> generateCategoryScores() {
    return {
      '기술적 지식': 85,
      '문제 해결 능력': 80,
      '커뮤니케이션': 78,
      '경험 및 사례': 84,
      '학습 의지': 88,
      '논리적 사고': 82,
      '창의성': 76,
      '팀워크': 79,
    };
  }
}
