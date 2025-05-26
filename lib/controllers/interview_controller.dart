import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:async';

import '../services/api/server_api_service.dart';
import '../services/common/video_recording_service.dart';
import '../services/common/audio_service.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
import '../services/interview/media_service.dart';
import '../services/interview/interfaces/streaming_service_interface.dart';
import '../services/interview/streaming_service.dart';
import '../repositories/report/firebase_report_repository.dart';
import '../models/resume_model.dart';
import 'package:get_it/get_it.dart';
import '../core/constants/app_constants.dart';

/// 면접 관련 로직을 관리하는 컨트롤러
/// UI에서 면접 관련 비즈니스 로직을 분리하여 관리합니다.
class InterviewController extends ChangeNotifier {
  // 서비스들
  late ServerApiService _serverApiService;
  VideoRecordingService? _cameraService;
  AudioService? _audioService;
  IResumeService? _resumeService;
  MediaService? _mediaService;
  final FirebaseReportRepository _reportRepository = FirebaseReportRepository();

  // 상태 변수
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  String? _errorMessage;

  // 목업 모드용 추가 상태 변수
  bool _isServerConnecting = false;
  String _serverConnectionMessage = '';
  bool _isQuestionsGenerating = false;
  String _questionGenerationMessage = '';

  // 카운트다운 및 녹화 관련 상태 변수
  bool _isCountdownActive = false;
  int _countdownValue = 5;
  bool _isAutoRecording = false;
  Timer? _countdownTimer;

  // 면접 진행 상태 변수
  DateTime? _interviewStartTime;
  final List<String> _videoUrls = [];
  String? _generatedReportId;

  // 면접 관련 상태
  ResumeModel? _selectedResume;
  List<Map<String, dynamic>> _resumeList = [];
  List<String> _questions = [];
  int _currentQuestionIndex = -1;
  Uint8List? _lastCapturedFrame;
  final List<String> _answers = [];
  final List<Uint8List> _audioRecordings = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get isInterviewStarted => _isInterviewStarted;
  bool get isUploadingVideo => _isUploadingVideo;
  String? get errorMessage => _errorMessage;
  ResumeModel? get selectedResume => _selectedResume;
  List<Map<String, dynamic>> get resumeList => _resumeList;
  List<String> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Uint8List? get lastCapturedFrame => _lastCapturedFrame;
  VideoRecordingService? get cameraService => _cameraService;
  AudioService? get audioService => _audioService;

  // 목업 모드용 추가 Getters
  bool get isServerConnecting => _isServerConnecting;
  String get serverConnectionMessage => _serverConnectionMessage;
  bool get isServerConnected => _isConnected;
  bool get isQuestionsGenerating => _isQuestionsGenerating;
  String get questionGenerationMessage => _questionGenerationMessage;
  bool get isQuestionsGenerated => _questions.isNotEmpty;

  // 카운트다운 및 녹화 관련 Getters
  bool get isCountdownActive => _isCountdownActive;
  int get countdownValue => _countdownValue;
  bool get isAutoRecording => _isAutoRecording;
  String? get generatedReportId => _generatedReportId;

  String? get currentQuestion =>
      _currentQuestionIndex >= 0 && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  /// 서비스 초기화
  Future<void> initializeServices() async {
    try {
      print('InterviewController: 서비스 초기화 시작');
      _setLoading(true);
      _setErrorMessage(null);

      // 1. 서버 API 서비스 초기화 (연결은 하지 않음)
      _serverApiService =
          ServerApiService(baseUrl: AppConstants.defaultServerUrl);

      // 2. GetIt에서 필요한 서비스들 가져오기
      final serviceLocator = GetIt.instance;

      try {
        _cameraService = serviceLocator<VideoRecordingService>();
        await _cameraService!.initialize();
        print('InterviewController: 카메라 서비스 초기화 성공');
      } catch (e) {
        print('InterviewController: 카메라 서비스 초기화 실패: $e');
      }

      try {
        _audioService = serviceLocator<AudioService>();
        await _audioService!.initialize();
        print('InterviewController: 오디오 서비스 초기화 성공');
      } catch (e) {
        print('InterviewController: 오디오 서비스 초기화 실패: $e');
      }

      try {
        _resumeService = serviceLocator<IResumeService>();
        await loadResumeList();
        print('InterviewController: 이력서 서비스 초기화 성공');
      } catch (e) {
        print('InterviewController: 이력서 서비스 초기화 실패: $e');
      }

      // MediaService 초기화 (수동 생성)
      try {
        if (_cameraService != null) {
          // StreamingService 생성 (목업용)
          final streamingService = StreamingService(
            onError: (String error) {
              print('StreamingService 오류: $error');
              _setErrorMessage(error);
            },
          );

          _mediaService = MediaService(
            httpService: streamingService,
            cameraService: _cameraService!,
            onError: (String error) {
              print('MediaService 오류: $error');
              _setErrorMessage(error);
            },
            onStateChanged: () {
              notifyListeners();
            },
          );
          print('InterviewController: 미디어 서비스 초기화 성공');
        }
      } catch (e) {
        print('InterviewController: 미디어 서비스 초기화 실패: $e');
      }

      // 3. 서버 연결은 사용자가 수동으로 시작하도록 변경
      _isConnected = false;
      print('InterviewController: 서비스 초기화 완료 (서버 연결은 수동)');

      _setLoading(false);
    } catch (e) {
      print('InterviewController: 서비스 초기화 중 예외 발생: $e');
      _setErrorMessage('서비스 초기화 중 오류가 발생했습니다: $e');
      _setLoading(false);
    }
  }

  /// 이력서 목록 로드
  Future<void> loadResumeList() async {
    try {
      if (_resumeService != null) {
        final resumeList = await _resumeService!.getCurrentUserResumeList();
        _resumeList = resumeList;
        notifyListeners();
        print('InterviewController: 이력서 목록 로드 완료: ${resumeList.length}개');
      }
    } catch (e) {
      print('InterviewController: 이력서 목록 로드 실패: $e');
    }
  }

  /// 이력서 선택
  Future<bool> selectResume(String resumeId) async {
    try {
      if (_resumeService != null) {
        final resumeData = await _resumeService!.getResume(resumeId);
        if (resumeData != null) {
          _selectedResume = resumeData;
          notifyListeners();
          // 자동으로 질문 생성하지 않음 - 사용자가 수동으로 시작
          print('InterviewController: 이력서 선택 완료: ${resumeData.position}');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('InterviewController: 이력서 선택 실패: $e');
      _setErrorMessage('이력서 선택 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 목업 질문 생성 (수동 호출)
  Future<bool> generateQuestions() async {
    try {
      _isQuestionsGenerating = true;
      _questionGenerationMessage = '질문 생성 중...';
      notifyListeners();

      // 목업 지연시간
      await Future.delayed(Duration(seconds: 2));

      // 백엔드 개발자용 목업 질문들
      final List<String> mockQuestions = [
        '간단한 자기소개와 백엔드 개발 경험에 대해 말씀해주세요.',
        '주로 사용하는 백엔드 기술 스택은 무엇이며, 왜 선택했나요?',
        'RESTful API와 GraphQL의 차이점과 각각의 장단점을 설명해주세요.',
        '데이터베이스 설계 시 정규화와 비정규화를 언제 적용하시나요?',
        '대용량 트래픽 처리를 위한 성능 최적화 경험이 있다면 말씀해주세요.',
        '마이크로서비스 아키텍처의 장단점과 도입 시 고려사항은 무엇인가요?',
        '서버 보안을 위해 어떤 방법들을 사용하시나요?',
        '가장 어려웠던 백엔드 문제를 어떻게 해결하셨나요?',
      ];

      _questions = mockQuestions;
      _currentQuestionIndex = 0;
      _questionGenerationMessage = '질문 생성 완료! (목업 모드)';
      print('목업: 질문 생성 완료 - ${_questions.length}개');

      _isQuestionsGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _questionGenerationMessage = '질문 생성 실패: $e';
      print('목업: 질문 생성 오류 - $e');
      _isQuestionsGenerating = false;
      notifyListeners();
      return false;
    }
  }

  /// 면접 시작
  Future<bool> startInterview() async {
    if (_isInterviewStarted) return true;

    if (_selectedResume == null) {
      _setErrorMessage('인터뷰를 시작하려면 이력서를 선택해야 합니다');
      return false;
    }

    if (_questions.isEmpty) {
      _setErrorMessage('질문이 생성되지 않았습니다');
      return false;
    }

    try {
      // 서버에 비디오 녹화 시작 요청
      final videoStarted = await _serverApiService.startVideoRecording();
      if (!videoStarted) {
        _setErrorMessage('서버 비디오 녹화를 시작할 수 없습니다');
        return false;
      }

      _isInterviewStarted = true;
      _currentQuestionIndex = 0;
      notifyListeners();

      print('InterviewController: 면접 시작됨');
      return true;
    } catch (e) {
      print('InterviewController: 면접 시작 실패: $e');
      _setErrorMessage('면접 시작 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접 종료
  Future<void> stopInterview() async {
    if (!_isInterviewStarted) return;

    try {
      _isUploadingVideo = true;
      notifyListeners();

      // 서버에 비디오 녹화 종료 요청
      final result = await _serverApiService.stopVideoRecording();
      print('InterviewController: 비디오 녹화 종료 결과: $result');

      // 면접 평가 요청
      if (_answers.isNotEmpty && _audioRecordings.isNotEmpty) {
        await _serverApiService.evaluateInterview(
          questions: _questions,
          answers: _answers,
          audioFiles: _audioRecordings,
        );
        print('InterviewController: 면접 평가 완료');
      }

      _isInterviewStarted = false;
      _isUploadingVideo = false;
      notifyListeners();
    } catch (e) {
      print('InterviewController: 면접 종료 실패: $e');
      _isUploadingVideo = false;
      notifyListeners();
      _setErrorMessage('면접 종료 중 오류가 발생했습니다: $e');
    }
  }

  /// 목업 서버 연결
  Future<bool> connectToServer() async {
    await checkServerConnection();
    return _isConnected;
  }

  /// 카운트다운 시작 후 자동 녹화
  /// [questionIndex] - 시작할 질문 인덱스
  Future<void> startQuestionWithCountdown(int questionIndex) async {
    if (questionIndex < 0 || questionIndex >= _questions.length) {
      _setErrorMessage('유효하지 않은 질문 인덱스입니다.');
      return;
    }

    try {
      // 첫 번째 질문인 경우 면접 시작 시간 기록
      if (questionIndex == 0) {
        _interviewStartTime = DateTime.now();
        print('⏰ 면접 시작 시간 기록: $_interviewStartTime');
      }

      // 현재 질문 설정
      _currentQuestionIndex = questionIndex;
      print('🎯 질문 ${questionIndex + 1} 시작: ${_questions[questionIndex]}');

      // 카운트다운 시작
      await _startCountdown();
    } catch (e) {
      print('질문 시작 중 오류: $e');
      _setErrorMessage('질문 시작 중 오류가 발생했습니다: $e');
    }
  }

  /// 5초 카운트다운 시작
  Future<void> _startCountdown() async {
    print('⏱️ 카운트다운 시작!');

    _isCountdownActive = true;
    _countdownValue = 5;
    notifyListeners();

    // 기존 타이머가 있다면 취소
    _countdownTimer?.cancel();

    // 1초마다 카운트다운
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_countdownValue > 1) {
        _countdownValue--;
        print('⏰ 카운트다운: $_countdownValue');
        notifyListeners();
      } else {
        // 카운트다운 완료
        timer.cancel();
        _isCountdownActive = false;
        _countdownValue = 0;
        print('🎬 카운트다운 완료! 녹화 시작!');
        notifyListeners();

        // 자동으로 녹화 시작
        await _startAutoRecording();
      }
    });
  }

  /// 자동 녹화 시작
  Future<void> _startAutoRecording() async {
    try {
      _isAutoRecording = true;
      notifyListeners();

      // MediaService를 통한 녹화 시작 (Firebase Storage 연동)
      if (_mediaService != null) {
        // 면접 세션 정보 설정
        final interviewId =
            'interview_${DateTime.now().millisecondsSinceEpoch}';
        _mediaService!.startInterviewSession(interviewId, null);

        // 실제 웹캠 녹화 시작
        final success = await _mediaService!.startVideoRecording();

        if (success) {
          print('✅ 자동 녹화 시작 성공! (Firebase Storage 연동)');
          _isInterviewStarted = true;
        } else {
          print('❌ 자동 녹화 시작 실패');
          _setErrorMessage('카메라 녹화를 시작할 수 없습니다.');
          _isAutoRecording = false;
        }
      } else {
        print('❌ 미디어 서비스가 초기화되지 않았습니다');
        _setErrorMessage('카메라가 준비되지 않았습니다.');
        _isAutoRecording = false;
      }

      notifyListeners();
    } catch (e) {
      print('자동 녹화 시작 중 오류: $e');
      _setErrorMessage('녹화 시작 중 오류가 발생했습니다: $e');
      _isAutoRecording = false;
      notifyListeners();
    }
  }

  /// 현재 질문 녹화 중지 및 다음 질문으로 이동
  Future<bool> finishCurrentQuestionAndNext() async {
    try {
      // 현재 녹화 중지하고 비디오 URL 수집
      if (_isAutoRecording && _mediaService != null) {
        print('🛑 현재 질문 녹화 중지');
        await _mediaService!.stopVideoRecording();

        // 업로드된 비디오 URL 수집 (목업)
        final videoUrl =
            'https://firebasestorage.googleapis.com/v0/b/your-app/o/videos%2Fquestion_${_currentQuestionIndex + 1}.mp4?alt=media';
        _videoUrls.add(videoUrl);
        print('📹 비디오 URL 수집: $videoUrl');

        _isAutoRecording = false;
      }

      // 다음 질문이 있는지 확인
      if (_currentQuestionIndex < _questions.length - 1) {
        // 다음 질문으로 이동 (자동으로 카운트다운 시작)
        await startQuestionWithCountdown(_currentQuestionIndex + 1);
        return true;
      } else {
        // 모든 질문 완료 - 리포트 생성
        await _generateFinalReport();
        _isInterviewStarted = false;
        _isAutoRecording = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('질문 완료 처리 중 오류: $e');
      _setErrorMessage('질문 완료 처리 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접 전체 중지
  Future<void> stopFullInterview() async {
    try {
      // 카운트다운 중지
      _countdownTimer?.cancel();
      _isCountdownActive = false;

      // 녹화 중지하고 비디오 URL 수집
      if (_isAutoRecording && _mediaService != null) {
        await _mediaService!.stopVideoRecording();

        // 현재까지의 비디오 URL 수집
        final videoUrl =
            'https://firebasestorage.googleapis.com/v0/b/your-app/o/videos%2Fquestion_${_currentQuestionIndex + 1}.mp4?alt=media';
        _videoUrls.add(videoUrl);
        print('📹 중지 시 비디오 URL 수집: $videoUrl');
      }

      // 중도 종료인 경우에도 리포트 생성
      if (_selectedResume != null && _questions.isNotEmpty) {
        await _generateFinalReport();
      }

      _isAutoRecording = false;
      _isInterviewStarted = false;
      print('🏁 면접 전체 중지 완료');

      notifyListeners();
    } catch (e) {
      print('면접 중지 중 오류: $e');
      _setErrorMessage('면접 중지 중 오류가 발생했습니다: $e');
    }
  }

  /// 최종 리포트 생성 및 Firebase 저장
  Future<void> _generateFinalReport() async {
    if (_selectedResume == null || _interviewStartTime == null) {
      print('❌ 리포트 생성에 필요한 데이터가 부족합니다');
      return;
    }

    try {
      print('📊 최종 리포트 생성 시작...');

      // 면접 소요 시간 계산 (초)
      final duration =
          DateTime.now().difference(_interviewStartTime!).inSeconds;

      // Firebase에 리포트 저장
      _generatedReportId = await _reportRepository.generateInterviewReport(
        questions: _questions,
        videoUrls: _videoUrls,
        resume: _selectedResume!,
        duration: duration,
        userId: 'user_001', // 목업용 사용자 ID
      );

      print('🎉 리포트 생성 완료! ID: $_generatedReportId');
      print('⏱️ 면접 소요 시간: ${duration ~/ 60}분 ${duration % 60}초');
      print('🎬 수집된 비디오: ${_videoUrls.length}개');

      notifyListeners();
    } catch (e) {
      print('❌ 리포트 생성 실패: $e');
      _setErrorMessage('리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 서버 연결 해제
  void disconnectFromServer() {
    _isConnected = false;
    notifyListeners();
  }

  // Private 메서드들
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 리소스 해제
  @override
  void dispose() {
    // 카운트다운 타이머 해제
    _countdownTimer?.cancel();

    if (_isInterviewStarted) {
      stopInterview();
    }

    _cameraService?.dispose();
    _audioService?.dispose();
    super.dispose();
  }

  /// 목업 서버 연결 체크
  Future<void> checkServerConnection() async {
    try {
      _isServerConnecting = true;
      _serverConnectionMessage = '서버 연결 확인 중...';
      notifyListeners();

      // 목업 지연시간
      await Future.delayed(Duration(seconds: 1));

      _isConnected = true;
      _serverConnectionMessage = '서버 연결 성공! (목업 모드)';
      print('목업: 서버 연결 성공');
    } catch (e) {
      _isConnected = false;
      _serverConnectionMessage = '서버 연결 실패: $e';
      print('목업: 서버 연결 오류 - $e');
    } finally {
      _isServerConnecting = false;
      notifyListeners();
    }
  }
}
