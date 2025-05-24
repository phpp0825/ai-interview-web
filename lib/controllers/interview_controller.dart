import 'package:flutter/foundation.dart';

import '../services/api/server_api_service.dart';
import '../services/common/video_recording_service.dart';
import '../services/common/audio_service.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
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

  // 상태 변수
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  String? _errorMessage;

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

      // 1. 서버 API 서비스 초기화
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

      // 3. 서버 연결 확인
      _isConnected = await _serverApiService.checkServerConnection();
      print('InterviewController: 서버 연결 상태: $_isConnected');

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
          await _generateQuestions();
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

  /// 질문 생성
  Future<void> _generateQuestions() async {
    try {
      if (_selectedResume == null) return;

      print('InterviewController: 질문 생성 시작');

      // 이력서 PDF 파일 가져오기 (실제로는 이력서 데이터에서 PDF 바이트를 가져와야 함)
      // 여기서는 임시로 더미 데이터를 사용
      final dummyPdfBytes = Uint8List.fromList([]);

      final questions = await _serverApiService.generateQuestions(
          dummyPdfBytes, 'resume.pdf');

      if (questions != null && questions.isNotEmpty) {
        _questions = questions;
        _currentQuestionIndex = 0;
        notifyListeners();
        print('InterviewController: 질문 생성 완료: ${questions.length}개 질문');
      } else {
        print('InterviewController: 질문 생성 실패');
        _setErrorMessage('질문을 생성하지 못했습니다');
      }
    } catch (e) {
      print('InterviewController: 질문 생성 중 오류: $e');
      _setErrorMessage('질문 생성 중 오류가 발생했습니다: $e');
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

  /// 서버 연결
  Future<bool> connectToServer() async {
    if (_isConnected) return true;

    try {
      final success = await _serverApiService.checkServerConnection();
      _isConnected = success;
      notifyListeners();
      return success;
    } catch (e) {
      print('InterviewController: 서버 연결 실패: $e');
      _isConnected = false;
      notifyListeners();
      return false;
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
    if (_isInterviewStarted) {
      stopInterview();
    }
    _cameraService?.dispose();
    _audioService?.dispose();
    super.dispose();
  }
}
