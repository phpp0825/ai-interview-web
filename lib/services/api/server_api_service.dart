import 'dart:typed_data';
import 'dart:convert';

/// 목업 서버 API 서비스
/// 실제 서버 없이 앱의 흐름을 테스트하기 위한 간단한 목업 클래스입니다
class ServerApiService {
  final String _baseUrl;

  ServerApiService({String baseUrl = 'http://localhost:8000'})
      : _baseUrl = baseUrl;

  /// 목업 이력서 파싱
  Future<Map<String, dynamic>?> parseResume(
      Uint8List pdfBytes, String fileName) async {
    print('목업: 이력서 파싱 - $fileName');
    await Future.delayed(Duration(seconds: 1));
    return {
      'name': '홍길동',
      'position': 'Flutter 개발자',
      'experience': '3년',
      'skills': ['Flutter', 'Dart', 'Firebase', 'REST API'],
    };
  }

  /// 목업 질문 생성
  Future<List<String>?> generateQuestions(
      Uint8List pdfBytes, String fileName) async {
    print('목업: 질문 생성 - $fileName');
    await Future.delayed(Duration(seconds: 2));
    return [
      '자기소개를 해주세요.',
      'Flutter를 선택한 이유는 무엇인가요?',
      'State Management에 대해 설명해주세요.',
      '가장 기억에 남는 프로젝트는 무엇인가요?',
      '어려운 문제를 해결한 경험이 있나요?',
    ];
  }

  /// 목업 서버 연결 확인 (항상 성공)
  Future<bool> checkServerConnection() async {
    print('목업: 서버 연결 확인');
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  /// 목업 비디오 녹화 시작
  Future<bool> startVideoRecording() async {
    print('목업: 비디오 녹화 시작');
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }

  /// 목업 비디오 녹화 중지
  Future<String?> stopVideoRecording() async {
    print('목업: 비디오 녹화 중지');
    await Future.delayed(Duration(milliseconds: 500));
    return 'recording_stopped';
  }

  /// 목업 면접 평가
  Future<String?> evaluateInterview({
    required List<String> questions,
    required List<String> answers,
    required List<Uint8List> audioFiles,
    String outputFile = 'interview_evaluation.txt',
  }) async {
    print('목업: 면접 평가');
    await Future.delayed(Duration(seconds: 3));
    return '''
목업 면접 평가 결과

전체 점수: 85/100

1. 자기소개: 90점
2. 기술적 역량: 80점
3. 의사소통 능력: 85점
4. 열정도: 90점

개선사항:
- 구체적인 경험 사례를 더 많이 포함하세요.
- 기술적 깊이를 더 보여주세요.
    ''';
  }

  /// 기타 모든 서버 메서드들도 목업으로 구현
  Future<List<Map<String, dynamic>>?> transcribeAudio(
      Uint8List audioBytes, String fileName) async {
    print('목업: 오디오 전사');
    await Future.delayed(Duration(seconds: 1));
    return [
      {'word': '안녕하세요', 'start': 0.0, 'end': 1.0},
      {'word': '홍길동입니다', 'start': 1.1, 'end': 2.0},
    ];
  }

  Future<Map<String, double>?> analyzeAudioMetrics(
      Uint8List audioBytes, String fileName) async {
    print('목업: 오디오 메트릭 분석');
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'duration_sec': 30.5,
      'silence_sec': 2.3,
    };
  }

  Future<Map<String, dynamic>?> recordAndTranscribeAudio({
    String outputFile = 'response.wav',
  }) async {
    print('목업: 오디오 녹음 및 전사');
    await Future.delayed(Duration(seconds: 2));
    return {
      'text': '안녕하세요. 저는 Flutter 개발자 홍길동입니다.',
      'confidence': 0.95,
      'duration': 3.2,
    };
  }
}
