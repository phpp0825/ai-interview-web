import 'dart:convert';
import 'dart:typed_data';
import 'interfaces/interview_service_interface.dart';
import 'interfaces/media_service_interface.dart';
import 'interfaces/streaming_service_interface.dart';
import 'interfaces/connection_status.dart';

class HttpInterviewService implements IInterviewService {
  final IStreamingService _httpService;
  final IMediaService _mediaService;

  bool _isInterviewStarted = false;
  String? _resumeId;
  List<String> _questions = [];
  int _currentQuestionIndex = -1;
  Map<String, dynamic>? _resumeData;

  final Function(String) onError;
  final Function()? onStateChanged;
  final Function(List<String>)? onQuestionsLoaded;
  final Function(String, String, Map<String, dynamic>)? onInterviewCompleted;

  @override
  bool get isInterviewStarted => _isInterviewStarted;
  @override
  String? get resumeId => _resumeId;
  @override
  List<String> get questions => _questions;
  @override
  int get currentQuestionIndex => _currentQuestionIndex;
  @override
  bool get hasMoreQuestions => _currentQuestionIndex < _questions.length - 1;

  HttpInterviewService({
    required IStreamingService httpService,
    required IMediaService mediaService,
    required this.onError,
    this.onStateChanged,
    this.onQuestionsLoaded,
    this.onInterviewCompleted,
  })  : _httpService = httpService,
        _mediaService = mediaService {
    _httpService.connectionStatus.listen(_handleConnectionStatusChanged);
  }

  void _handleConnectionStatusChanged(ConnectionStatus status) {
    if (status != ConnectionStatus.connected && _isInterviewStarted) {
      stopInterview();
    }
  }

  @override
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
      final videoStarted = await _mediaService.startVideoStreaming();
      final audioStarted = await _mediaService.startAudioStreaming();

      if (videoStarted && audioStarted) {
        _isInterviewStarted = true;
        onStateChanged?.call();
        return true;
      } else {
        _mediaService.stopVideoStreaming();
        _mediaService.stopAudioStreaming();
        return false;
      }
    } catch (e) {
      onError('인터뷰 시작 중 오류 발생: $e');
      return false;
    }
  }

  @override
  Future<void> stopInterview() async {
    if (!_isInterviewStarted) {
      return;
    }

    _mediaService.stopVideoStreaming();
    _mediaService.stopAudioStreaming();

    _isInterviewStarted = false;

    if (_resumeId != null && _httpService.isConnected) {
      await uploadInterviewVideo(_resumeId!);
    }

    onStateChanged?.call();
  }

  @override
  Future<bool> uploadInterviewVideo(String resumeId) async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 비디오를 업로드할 수 없습니다');
      return false;
    }

    try {
      final videoData = _mediaService.lastCapturedVideoFrame;
      final audioData = _mediaService.lastCapturedAudioData;
      final interviewId = 'interview_${DateTime.now().millisecondsSinceEpoch}';

      if (videoData != null && videoData.isNotEmpty) {
        final videoResponse = await _httpService.post(
          'complete_video/$resumeId',
          videoData,
          headers: {'Content-Type': 'application/octet-stream'},
        );

        if (videoResponse?.statusCode != 200) {
          onError('비디오 데이터 업로드 실패: ${videoResponse?.statusCode}');
          return false;
        }
      }

      if (audioData != null && audioData.isNotEmpty) {
        final audioResponse = await _httpService.post(
          'complete_audio/$resumeId',
          audioData,
          headers: {'Content-Type': 'application/octet-stream'},
        );

        if (audioResponse?.statusCode != 200) {
          onError('오디오 데이터 업로드 실패: ${audioResponse?.statusCode}');
          return false;
        }
      }

      final completeResponse = await _httpService.post(
        'complete_interview/$resumeId',
        {'completed': true, 'interviewId': interviewId},
      );

      if (completeResponse?.statusCode == 200) {
        if (onInterviewCompleted != null && _resumeData != null) {
          onInterviewCompleted!(interviewId, resumeId, _resumeData!);
        }
        return true;
      } else {
        onError('면접 완료 처리 실패: ${completeResponse?.statusCode}');
        return false;
      }
    } catch (e) {
      onError('면접 데이터 업로드 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> uploadResumeData(Map<String, dynamic> resumeData) async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 이력서를 전송할 수 없습니다');
      return false;
    }

    try {
      final response = await _httpService.post('resume', resumeData);

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        _resumeId = jsonResponse['resume_id'];
        _resumeData = resumeData;

        if (jsonResponse.containsKey('questions')) {
          _questions = List<String>.from(jsonResponse['questions']);
          _currentQuestionIndex = -1;
          onQuestionsLoaded?.call(_questions);
        }

        onStateChanged?.call();
        return true;
      } else {
        onError('이력서 업로드 실패: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      onError('이력서 전송 실패: $e');
      return false;
    }
  }

  @override
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
      final response = await _httpService.get('questions/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        _questions = List<String>.from(jsonResponse['questions']);
        _currentQuestionIndex = -1;

        onQuestionsLoaded?.call(_questions);
        onStateChanged?.call();
        return true;
      } else {
        onError('질문 불러오기 실패: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      onError('질문 불러오기 실패: $e');
      return false;
    }
  }

  @override
  bool moveToNextQuestion() {
    if (!_isInterviewStarted || _questions.isEmpty) {
      onError('인터뷰가 시작되지 않았거나 질문이 없습니다');
      return false;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      onStateChanged?.call();
      return true;
    } else {
      onError('더 이상 질문이 없습니다');
      return false;
    }
  }

  @override
  Future<bool> submitAnswer(String answer) async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 답변을 제출할 수 없습니다');
      return false;
    }

    if (!_isInterviewStarted) {
      onError('인터뷰가 시작되지 않았습니다');
      return false;
    }

    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questions.length) {
      onError('유효한 질문이 선택되지 않았습니다');
      return false;
    }

    try {
      final response = await _httpService.post(
        'answer/$_resumeId',
        {
          'question_index': _currentQuestionIndex,
          'question': _questions[_currentQuestionIndex],
          'answer': answer,
        },
      );

      if (response?.statusCode == 200) {
        return true;
      } else {
        onError('답변 제출 실패: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      onError('답변 제출 실패: $e');
      return false;
    }
  }

  @override
  Future<String?> getAnalysisLog() async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 분석 로그를 가져올 수 없습니다');
      return null;
    }

    if (_resumeId == null) {
      onError('인터뷰가 시작되지 않았습니다');
      return null;
    }

    try {
      final response = await _httpService.get('analysis/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        return jsonResponse['analysis'];
      } else {
        onError('분석 로그 불러오기 실패: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      onError('분석 로그 불러오기 실패: $e');
      return null;
    }
  }

  @override
  Future<String?> getFeedbackSummary() async {
    if (!_httpService.isConnected || _resumeId == null) {
      onError('서버에 연결되지 않았거나 이력서 ID가 없어 피드백 요약을 가져올 수 없습니다');
      return null;
    }

    try {
      final response = await _httpService.get('feedback_summary/$_resumeId');

      if (response?.statusCode == 200) {
        final jsonResponse = jsonDecode(response!.body);
        return jsonResponse['summary'];
      } else {
        onError('피드백 요약 가져오기 실패: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      onError('피드백 요약 가져오기 실패: $e');
      return null;
    }
  }

  @override
  Future<Uint8List?> requestTtsAudio(String text) async {
    if (!_httpService.isConnected) {
      onError('서버에 연결되지 않아 TTS 음성을 요청할 수 없습니다');
      return null;
    }

    try {
      // TTS 요청 헤더 설정
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'audio/mp3, audio/wav, audio/*',
      };

      // 서버에 TTS 요청 전송
      final response = await _httpService.post(
        'tts/generate',
        {'text': text},
        headers: headers,
      );

      // 응답 확인
      if (response?.statusCode == 200) {
        // Content-Type 확인
        final contentType = response!.headers['content-type'];
        if (contentType != null &&
            (contentType.contains('audio/') ||
                contentType.contains('application/octet-stream'))) {
          print('TTS 오디오 데이터 수신 성공: ${response.bodyBytes.length} 바이트');
          return response.bodyBytes;
        } else if (contentType != null &&
            contentType.contains('application/json')) {
          // 서버가 JSON 형식으로 오류 응답을 보낸 경우
          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse.containsKey('error')) {
              onError('TTS 서버 오류: ${jsonResponse['error']}');
            } else {
              onError('알 수 없는 JSON 응답 형식');
            }
          } catch (e) {
            onError('JSON 응답 파싱 오류: $e');
          }
          return null;
        } else {
          onError('TTS 응답이 지원되지 않는 형식입니다: $contentType');
          return null;
        }
      } else {
        // 오류 응답 처리
        String errorMessage = '상태 코드: ${response?.statusCode}';

        // JSON 오류 메시지 추출 시도
        if (response?.body != null && response!.body.isNotEmpty) {
          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse.containsKey('error')) {
              errorMessage =
                  '${jsonResponse['error']} (코드: ${response.statusCode})';
            }
          } catch (_) {
            // JSON 파싱 실패 시 원래 오류 메시지 사용
          }
        }

        onError('TTS 음성 생성 요청 실패: $errorMessage');
        return null;
      }
    } catch (e) {
      onError('TTS 음성 생성 요청 중 네트워크 오류: $e');
      return null;
    }
  }

  void dispose() {
    if (_isInterviewStarted) {
      stopInterview();
    }
  }
}
