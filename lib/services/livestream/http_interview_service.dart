import 'dart:convert';
import 'http_streaming_service.dart';
import 'http_media_service.dart';

/// HTTP 기반 인터뷰 서비스
/// 이력서 관리, 질문 관리, 인터뷰 상태 관리 기능을 담당합니다.
class HttpInterviewService {
  // 서비스 인스턴스
  final HttpStreamingService _httpService;
  final HttpMediaService _mediaService;

  // 인터뷰 상태
  bool _isInterviewStarted = false;
  String? _resumeId;
  List<String> _questions = [];
  int _currentQuestionIndex = -1;

  // 콜백 함수
  final Function(String) onError;
  final Function()? onStateChanged;
  final Function(List<String>)? onQuestionsLoaded;

  // 상태 getter
  bool get isInterviewStarted => _isInterviewStarted;
  String? get resumeId => _resumeId;
  List<String> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get hasMoreQuestions => _currentQuestionIndex < _questions.length - 1;

  HttpInterviewService({
    required HttpStreamingService httpService,
    required HttpMediaService mediaService, 
    required this.onError,
    this.onStateChanged,
    this.onQuestionsLoaded,
  }) : _httpService = httpService, 
       _mediaService = mediaService {
    // 연결 상태 변경 감지
    _httpService.connectionStatus.listen(_handleConnectionStatusChanged);
  }

  /// 연결 상태 변경 처리
  void _handleConnectionStatusChanged(ConnectionStatus status) {
    if (status != ConnectionStatus.connected && _isInterviewStarted) {
      // 연결이 끊어지면 인터뷰 중단
      stopInterview();
    }
  }

  /// 인터뷰 시작 - 비디오와 오디오 스트리밍 모두 시작
  Future<bool> startInterview() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 인터뷰를 시작할 수 없습니다');
      return false;
    }

    if (_isInterviewStarted) {
      print('이미 인터뷰가 진행 중입니다');
      return true;
    }

    try {
      // 비디오와 오디오 스트리밍 시작
      final videoStarted = await _mediaService.startVideoStreaming();
      final audioStarted = await _mediaService.startAudioStreaming();

      if (videoStarted && audioStarted) {
        _isInterviewStarted = true;
        print('인터뷰 시작됨');
        onStateChanged?.call();
        return true;
      } else {
        // 하나라도 실패하면 모두 중지
        _mediaService.stopVideoStreaming();
        _mediaService.stopAudioStreaming();
        return false;
      }
    } catch (e) {
      onError('인터뷰 시작 중 오류 발생: $e');
      return false;
    }
  }

  /// 인터뷰 종료 - 비디오와 오디오 스트리밍 모두 중지
  void stopInterview() {
    if (!_isInterviewStarted) {
      return;
    }

    _mediaService.stopVideoStreaming();
    _mediaService.stopAudioStreaming();

    _isInterviewStarted = false;
    print('인터뷰 종료');
    onStateChanged?.call();
  }

  /// 이력서 업로드
  Future<bool> uploadResumeData(Map<String, dynamic> resumeData) async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 이력서를 전송할 수 없습니다');
      return false;
    }

    try {
      final response = await _httpService.post('resume', resumeData);

      if (response?.statusCode == 200) {
        // 이력서 ID와 질문 리스트 추출
        final jsonResponse = jsonDecode(response!.body);
        _resumeId = jsonResponse['resume_id'];
        if (jsonResponse.containsKey('questions')) {
          _questions = List<String>.from(jsonResponse['questions']);
          _currentQuestionIndex = -1;

          // 질문 로드 콜백 호출
          onQuestionsLoaded?.call(_questions);
        }

        print('이력서 업로드 성공. ID: $_resumeId');
        onStateChanged?.call();
        return true;
      } else {
        onError('이력서 업로드 실패: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('이력서 전송 오류: $e');
      onError('이력서 전송 실패: $e');
      return false;
    }
  }

  /// 질문 목록 가져오기
  Future<bool> getQuestions() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 질문을 가져올 수 없습니다');
      return false;
    }

    if (_resumeId == null) {
      onError('이력서 ID가 없어 질문을 가져올 수 없습니다');
      return false;
    }

    try {
      final response = await _httpService.get('get_questions/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        _questions = List<String>.from(jsonResponse['questions']);
        _currentQuestionIndex = -1;

        // 질문 로드 콜백 호출
        onQuestionsLoaded?.call(_questions);

        onStateChanged?.call();
        return true;
      } else {
        onError('질문 가져오기 실패: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('질문 가져오기 오류: $e');
      onError('질문 가져오기 실패: $e');
      return false;
    }
  }

  /// 다음 질문으로 이동
  bool moveToNextQuestion() {
    if (!_isInterviewStarted || _questions.isEmpty) {
      return false;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      print('다음 질문으로 이동: ${_questions[_currentQuestionIndex]}');
      onStateChanged?.call();
      return true;
    } else {
      print('더 이상 질문이 없습니다');
      return false;
    }
  }

  /// 분석 로그 가져오기
  Future<String?> getAnalysisLog() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 분석 로그를 가져올 수 없습니다');
      return null;
    }

    if (_resumeId == null) {
      onError('이력서 ID가 없어 분석 로그를 가져올 수 없습니다');
      return null;
    }

    try {
      final response = await _httpService.get('get_log/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        return jsonResponse['log'];
      } else {
        onError('분석 로그 가져오기 실패: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      print('분석 로그 가져오기 오류: $e');
      onError('분석 로그 가져오기 실패: $e');
      return null;
    }
  }

  /// 피드백 요약 가져오기
  Future<String?> getFeedbackSummary() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 피드백을 가져올 수 없습니다');
      return null;
    }

    if (_resumeId == null) {
      onError('이력서 ID가 없어 피드백을 가져올 수 없습니다');
      return null;
    }

    try {
      final response = await _httpService.get('get_feedback_summary/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        return jsonResponse['feedback_summary'];
      } else {
        onError('피드백 가져오기 실패: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      print('피드백 가져오기 오류: $e');
      onError('피드백 가져오기 실패: $e');
      return null;
    }
  }

  /// 리소스 해제
  void dispose() {
    if (_isInterviewStarted) {
      stopInterview();
    }
  }
}
