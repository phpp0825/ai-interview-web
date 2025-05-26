/*
// 전체 인터뷰 서비스 주석처리 - 목업 모드
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../../data/models/question.dart';
import '../../data/models/interview_analysis.dart';
import '../common/audio_service.dart';
import '../api/server_api_service.dart';

class InterviewService {
  // 실제 인터뷰 서비스 구현
}
*/

import 'dart:typed_data';
import 'dart:convert';
import '../common/audio_service.dart';
import '../api/server_api_service.dart';

/// 목업 인터뷰 서비스
/// 실제 서버 통신 없이 앱의 흐름을 테스트하기 위한 간단한 목업 클래스입니다
class InterviewService {
  final ServerApiService _serverApiService;
  final AudioService _audioService;

  InterviewService({
    required ServerApiService serverApiService,
    required AudioService audioService,
  })  : _serverApiService = serverApiService,
        _audioService = audioService;

  /// 목업 이력서 업로드
  Future<Map<String, dynamic>?> uploadResume(
      Uint8List pdfBytes, String fileName) async {
    print('목업: 이력서 업로드 - $fileName');
    await Future.delayed(Duration(seconds: 1));
    return {
      'message': '이력서가 성공적으로 업로드되었습니다',
      'file_name': fileName,
      'file_size': pdfBytes.length,
    };
  }

  /// 목업 질문 가져오기
  Future<List<Map<String, dynamic>>?> getQuestions() async {
    print('목업: 질문 생성');
    await Future.delayed(Duration(seconds: 2));

    return [
      {
        'id': 1,
        'content': '간단한 자기소개와 백엔드 개발 경험에 대해 말씀해주세요.',
        'category': 'general',
        'difficulty': 'easy',
      },
      {
        'id': 2,
        'content': '주로 사용하는 백엔드 기술 스택은 무엇이며, 왜 선택했나요?',
        'category': 'technical',
        'difficulty': 'medium',
      },
      {
        'id': 3,
        'content': 'RESTful API와 GraphQL의 차이점과 각각의 장단점을 설명해주세요.',
        'category': 'technical',
        'difficulty': 'medium',
      },
      {
        'id': 4,
        'content': '데이터베이스 설계 시 정규화와 비정규화를 언제 적용하시나요?',
        'category': 'database',
        'difficulty': 'hard',
      },
      {
        'id': 5,
        'content': '대용량 트래픽 처리를 위한 성능 최적화 경험이 있다면 말씀해주세요.',
        'category': 'performance',
        'difficulty': 'hard',
      },
      {
        'id': 6,
        'content': '마이크로서비스 아키텍처의 장단점과 도입 시 고려사항은 무엇인가요?',
        'category': 'architecture',
        'difficulty': 'hard',
      },
      {
        'id': 7,
        'content': '서버 보안을 위해 어떤 방법들을 사용하시나요?',
        'category': 'security',
        'difficulty': 'medium',
      },
      {
        'id': 8,
        'content': '가장 어려웠던 백엔드 문제를 어떻게 해결하셨나요?',
        'category': 'problem_solving',
        'difficulty': 'medium',
      },
    ];
  }

  /// 목업 인터뷰 데이터 업로드
  Future<String?> uploadInterviewData({
    required List<Map<String, dynamic>> questions,
    required List<String> answers,
    required List<Uint8List> audioFiles,
    String outputFile = 'interview_analysis.json',
  }) async {
    print('목업: 인터뷰 데이터 업로드');
    await Future.delayed(Duration(seconds: 3));

    final analysis = {
      'overallScore': 85.0,
      'scores': {
        'communication': 88.0,
        'technical': 82.0,
        'problem_solving': 87.0,
        'confidence': 90.0,
      },
      'feedback': [
        '전반적으로 자신감 있는 답변이었습니다.',
        '기술적 깊이를 더 보여주시면 좋겠습니다.',
        '구체적인 경험 사례가 더 필요합니다.',
      ],
      'recommendations': [
        'Flutter 위젯 생명주기에 대해 더 학습하세요.',
        '실제 프로젝트 경험을 구체적으로 설명하세요.',
        '문제 해결 과정을 단계별로 설명하세요.',
      ],
      'detailedAnalysis': {
        for (int i = 0; i < questions.length; i++)
          questions[i]['content'].toString(): {
            'score': 80.0 + (i % 3) * 5.0,
            'feedback': '답변이 명확하고 논리적입니다.',
            'areas_for_improvement': ['더 구체적인 예시 필요'],
          }
      },
    };

    // 결과를 JSON으로 저장 (목업)
    print('목업: 분석 결과 저장 완료 - $outputFile');

    return jsonEncode(analysis);
  }

  /// 목업 서버 연결 상태 확인
  Future<bool> checkServerConnection() async {
    print('목업: 서버 연결 상태 확인');
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }

  /// 목업 개별 답변 분석
  Future<Map<String, dynamic>?> analyzeAnswer({
    required String question,
    required String answer,
    required Uint8List audioData,
  }) async {
    print('목업: 개별 답변 분석 - ${question.substring(0, 20)}...');
    await Future.delayed(Duration(seconds: 1));

    return {
      'score': 82.5,
      'transcription_confidence': 0.95,
      'speech_metrics': {
        'clarity': 0.88,
        'pace': 0.92,
        'volume': 0.85,
      },
      'content_analysis': {
        'relevance': 0.90,
        'depth': 0.78,
        'structure': 0.85,
      },
      'feedback': '답변이 명확하고 구조적입니다.',
      'suggestions': ['더 구체적인 예시를 포함하세요.'],
    };
  }

  /// 목업 리소스 해제
  void dispose() {
    print('목업: 인터뷰 서비스 리소스 해제');
  }
}
