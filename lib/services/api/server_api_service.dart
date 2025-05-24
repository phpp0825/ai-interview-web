import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 서버 API와 통신하는 서비스
/// Python FastAPI 서버의 엔드포인트를 호출합니다
class ServerApiService {
  final String _baseUrl;

  ServerApiService({String baseUrl = 'http://localhost:8000'})
      : _baseUrl = baseUrl;

  /// 이력서 PDF를 파싱하여 JSON으로 반환
  /// POST /parse_resume
  Future<Map<String, dynamic>?> parseResume(
      Uint8List pdfBytes, String fileName) async {
    try {
      print('ServerApiService: 이력서 파싱 시작 - $fileName');

      final uri = Uri.parse('$_baseUrl/parse_resume');
      final request = http.MultipartRequest('POST', uri);

      // PDF 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        print('ServerApiService: 이력서 파싱 성공');
        return jsonResponse;
      } else {
        print(
            'ServerApiService: 이력서 파싱 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 이력서 파싱 중 오류 발생 - $e');
      return null;
    }
  }

  /// 이력서 PDF로부터 면접 질문 생성
  /// POST /generate_questions
  Future<List<String>?> generateQuestions(
      Uint8List pdfBytes, String fileName) async {
    try {
      print('ServerApiService: 질문 생성 시작 - $fileName');

      final uri = Uri.parse('$_baseUrl/generate_questions');
      final request = http.MultipartRequest('POST', uri);

      // PDF 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        final questions = (jsonResponse['questions'] as List<dynamic>)
            .map((q) => q.toString())
            .toList();
        print('ServerApiService: 질문 생성 성공 - ${questions.length}개 질문');
        return questions;
      } else {
        print(
            'ServerApiService: 질문 생성 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 질문 생성 중 오류 발생 - $e');
      return null;
    }
  }

  /// 오디오 파일 전사 (STT)
  /// POST /transcribe
  Future<List<Map<String, dynamic>>?> transcribeAudio(
      Uint8List audioBytes, String fileName) async {
    try {
      print('ServerApiService: 오디오 전사 시작 - $fileName');

      final uri = Uri.parse('$_baseUrl/transcribe');
      final request = http.MultipartRequest('POST', uri);

      // 오디오 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        final wordTimestamps = jsonResponse['word_timestamps'] as List<dynamic>;
        print('ServerApiService: 오디오 전사 성공');
        return wordTimestamps.cast<Map<String, dynamic>>();
      } else {
        print(
            'ServerApiService: 오디오 전사 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 오디오 전사 중 오류 발생 - $e');
      return null;
    }
  }

  /// 오디오 메트릭 분석 (총 재생시간, 무음 구간)
  /// POST /audio_metrics
  Future<Map<String, double>?> analyzeAudioMetrics(
      Uint8List audioBytes, String fileName) async {
    try {
      print('ServerApiService: 오디오 메트릭 분석 시작 - $fileName');

      final uri = Uri.parse('$_baseUrl/audio_metrics');
      final request = http.MultipartRequest('POST', uri);

      // 오디오 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        final metrics = {
          'duration_sec': (jsonResponse['duration_sec'] as num).toDouble(),
          'silence_sec': (jsonResponse['silence_sec'] as num).toDouble(),
        };
        print('ServerApiService: 오디오 메트릭 분석 성공');
        return metrics;
      } else {
        print(
            'ServerApiService: 오디오 메트릭 분석 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 오디오 메트릭 분석 중 오류 발생 - $e');
      return null;
    }
  }

  /// 면접 평가 수행
  /// POST /evaluate
  Future<String?> evaluateInterview({
    required List<String> questions,
    required List<String> answers,
    required List<Uint8List> audioFiles,
    String outputFile = 'interview_evaluation.txt',
  }) async {
    try {
      print('ServerApiService: 면접 평가 시작');

      final uri = Uri.parse('$_baseUrl/evaluate');
      final request = http.MultipartRequest('POST', uri);

      // 질문과 답변 추가
      for (int i = 0; i < questions.length; i++) {
        request.fields['questions'] = questions[i];
      }
      for (int i = 0; i < answers.length; i++) {
        request.fields['answers'] = answers[i];
      }
      request.fields['output_file'] = outputFile;

      // 오디오 파일들 추가
      for (int i = 0; i < audioFiles.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'audio_files',
            audioFiles[i],
            filename: 'audio_$i.wav',
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('ServerApiService: 면접 평가 성공');
        return responseBody;
      } else {
        print(
            'ServerApiService: 면접 평가 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 면접 평가 중 오류 발생 - $e');
      return null;
    }
  }

  /// 비디오 녹화 시작
  /// POST /video/start
  Future<bool> startVideoRecording() async {
    try {
      print('ServerApiService: 비디오 녹화 시작 요청');

      final uri = Uri.parse('$_baseUrl/video/start');
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        print('ServerApiService: 비디오 녹화 시작 성공');
        return true;
      } else {
        print(
            'ServerApiService: 비디오 녹화 시작 실패 - ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ServerApiService: 비디오 녹화 시작 중 오류 발생 - $e');
      return false;
    }
  }

  /// 비디오 녹화 종료
  /// POST /video/stop
  Future<String?> stopVideoRecording() async {
    try {
      print('ServerApiService: 비디오 녹화 종료 요청');

      final uri = Uri.parse('$_baseUrl/video/stop');
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final status = jsonResponse['status'] as String;
        print('ServerApiService: 비디오 녹화 종료 성공 - $status');
        return status;
      } else {
        print(
            'ServerApiService: 비디오 녹화 종료 실패 - ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 비디오 녹화 종료 중 오류 발생 - $e');
      return null;
    }
  }

  /// 오디오 녹음 및 전사
  /// POST /audio/record_and_transcribe
  Future<Map<String, dynamic>?> recordAndTranscribeAudio({
    String outputFile = 'response.wav',
  }) async {
    try {
      print('ServerApiService: 오디오 녹음 및 전사 요청');

      final uri = Uri.parse('$_baseUrl/audio/record_and_transcribe');
      final request = http.MultipartRequest('POST', uri);
      request.fields['output_file'] = outputFile;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
        print('ServerApiService: 오디오 녹음 및 전사 성공');
        return jsonResponse;
      } else {
        print(
            'ServerApiService: 오디오 녹음 및 전사 실패 - ${response.statusCode}: $responseBody');
        return null;
      }
    } catch (e) {
      print('ServerApiService: 오디오 녹음 및 전사 중 오류 발생 - $e');
      return null;
    }
  }

  /// 서버 연결 상태 확인
  Future<bool> checkServerConnection() async {
    try {
      print('ServerApiService: 서버 연결 상태 확인');

      final uri = Uri.parse('$_baseUrl/');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      final isConnected = response.statusCode == 200;
      print('ServerApiService: 서버 연결 상태 - ${isConnected ? "연결됨" : "연결 안됨"}');
      return isConnected;
    } catch (e) {
      print('ServerApiService: 서버 연결 확인 중 오류 발생 - $e');
      return false;
    }
  }
}
