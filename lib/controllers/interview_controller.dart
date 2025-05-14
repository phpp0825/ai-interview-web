import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/common/camera_service.dart';
import '../services/common/audio_service.dart';
import '../services/livestream/http_streaming_service.dart';
import '../services/livestream/http_media_service.dart';
import '../services/livestream/http_interview_service.dart';
import '../services/resume/resume_service.dart';
import '../models/resume_model.dart';
import '../controllers/report_controller.dart';

/// 인터뷰 기능을 제어하는 컨트롤러
class InterviewController with ChangeNotifier {
  // 서비스 인스턴스
  final CameraService _cameraService;
  final AudioService _audioService;
  final ResumeService _resumeService;
  final ReportController _reportController;

  // late로 변경하여 생성자에서는 초기화하지 않고, initialize 메서드에서 초기화
  late HttpStreamingService _httpService;
  late HttpMediaService _mediaService;
  late HttpInterviewService _interviewService;

  // 상태 변수
  bool _isInitialized = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  bool _isCreatingReport = false;
  ResumeModel? _selectedResume;
  List<Map<String, dynamic>> _resumeList = [];
  Uint8List? _lastCapturedFrame;
  List<String> _questions = [];
  int _currentQuestionIndex = -1;
  String? _errorMessage;

  // 서버 설정
  final String _serverUrl;

  // 상태 게터
  bool get isInitialized => _isInitialized;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isInterviewStarted => _isInterviewStarted;
  bool get isUploadingVideo => _isUploadingVideo;
  bool get isCreatingReport => _isCreatingReport;
  ResumeModel? get selectedResume => _selectedResume;
  List<Map<String, dynamic>> get resumeList => _resumeList;
  Uint8List? get lastCapturedFrame => _lastCapturedFrame;
  List<String> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  String? get errorMessage => _errorMessage;
  bool get hasMoreQuestions => _currentQuestionIndex < _questions.length - 1;
  String? get currentQuestion =>
      _currentQuestionIndex >= 0 && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;

  // 서비스 게터 (필요한 경우)
  CameraService get cameraService => _cameraService;

  // 생성자 - 기본 서비스만 초기화
  InterviewController({
    required CameraService cameraService,
    required AudioService audioService,
    required ResumeService resumeService,
    required ReportController reportController,
    String serverUrl = 'http://localhost:8080',
  })  : _cameraService = cameraService,
        _audioService = audioService,
        _resumeService = resumeService,
        _reportController = reportController,
        _serverUrl = serverUrl;

  /// 팩토리 생성자 - 모든 서비스를 초기화해서 컨트롤러를 만듭니다
  static Future<InterviewController> create({
    String serverUrl = 'http://localhost:8080',
    ReportController? reportController,
  }) async {
    final cameraService = CameraService();
    final audioService = AudioService();
    final resumeService = ResumeService();
    final reportCtrl = reportController ?? ReportController();

    final controller = InterviewController(
      cameraService: cameraService,
      audioService: audioService,
      resumeService: resumeService,
      reportController: reportCtrl,
      serverUrl: serverUrl,
    );

    await controller.initialize();
    return controller;
  }

  /// 컨트롤러 초기화
  Future<void> initialize() async {
    try {
      // HTTP 스트리밍 서비스 초기화
      _httpService = HttpStreamingService(
        onError: _handleError,
        onStateChanged: _handleHttpStateChanged,
      );

      // 미디어 서비스 초기화
      _mediaService = HttpMediaService(
        httpService: _httpService,
        onError: _handleError,
        onStateChanged: _handleMediaStateChanged,
      );

      // 인터뷰 서비스 초기화
      _interviewService = HttpInterviewService(
        httpService: _httpService,
        mediaService: _mediaService,
        onError: _handleError,
        onStateChanged: _handleInterviewStateChanged,
        onQuestionsLoaded: _handleQuestionsLoaded,
        onInterviewCompleted: _handleInterviewCompleted,
      );

      // 서비스 리스너 설정
      _setServiceListeners();

      // 미디어 서비스에 비디오/오디오 콜백 설정
      _mediaService.setVideoFrameCallback(() async {
        if (_cameraService.isInitialized) {
          final frameData = await _cameraService.captureFrame();
          // 더미 카메라거나 프레임 캡처 실패 시에도 인터뷰는 계속 진행
          if (frameData == null && _cameraService.isUsingDummyCamera) {
            // 더미 카메라 사용 중일 때는 null 반환해도 괜찮음
            return null;
          }
          return frameData;
        }
        return null;
      });

      _mediaService.setAudioDataCallback(() async {
        if (_audioService.isInitialized) {
          return await _audioService.captureAudioData();
        }
        return null;
      });

      // 카메라 초기화
      await _cameraService.initialize();

      // 오디오 초기화
      await _audioService.initialize();

      // 이력서 목록 로드
      await loadResumeList();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = '컨트롤러 초기화 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow; // 오류를 다시 던져서 상위 레벨에서도 처리할 수 있게 함
    }
  }

  /// 서비스 리스너 설정
  void _setServiceListeners() {
    // HTTP 서비스 연결 상태 리스너
    _httpService.connectionStatus.listen((status) {
      _isConnected = status == ConnectionStatus.connected;
      notifyListeners();
    });
  }

  /// 면접 완료 콜백 처리
  void _handleInterviewCompleted(String interviewId, String resumeId,
      Map<String, dynamic> resumeData) async {
    _isCreatingReport = true;
    notifyListeners();

    try {
      // ReportController를 통해 보고서 생성
      await _reportController.createInterviewReport(
          interviewId, resumeId, resumeData);
      print('면접 보고서가 생성되었습니다.');
    } catch (e) {
      _errorMessage = '면접 보고서 생성 중 오류가 발생했습니다: $e';
      print('면접 보고서 생성 오류: $e');
    } finally {
      _isCreatingReport = false;
      notifyListeners();
    }
  }

  /// 이력서 목록 로드
  Future<void> loadResumeList() async {
    try {
      final resumeList = await _resumeService.getCurrentUserResumeList();
      _resumeList = resumeList;
      notifyListeners();
    } catch (e) {
      _errorMessage = '이력서 목록을 로드하는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  /// 이력서 선택
  Future<void> selectResume(String resumeId) async {
    try {
      final resumeData = await _resumeService.getResume(resumeId);
      if (resumeData != null) {
        _selectedResume = resumeData;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '이력서 데이터를 가져오는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  /// 서버 연결
  Future<bool> connectToServer() async {
    if (_isConnected) return true;

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 서버에 연결
      final success = await _httpService.connect(_serverUrl);

      _isConnecting = false;
      _isConnected = success;
      notifyListeners();

      if (!success) {
        _errorMessage = '서버에 연결할 수 없습니다';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _errorMessage = '서버 연결 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 서버 연결 해제
  Future<void> disconnectFromServer() async {
    if (!_isConnected) return;

    try {
      // 인터뷰 중이면 먼저 중지
      if (_isInterviewStarted) {
        await stopInterview();
      }

      // 서버 연결 해제
      _httpService.disconnect();

      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '서버 연결 해제 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  /// 면접 시작
  Future<bool> startInterview() async {
    if (_isInterviewStarted) return true;

    // 이력서가 선택되지 않았으면 에러
    if (_selectedResume == null) {
      _errorMessage = '인터뷰를 시작하려면 이력서를 선택해야 합니다';
      notifyListeners();
      return false;
    }

    // 서버에 연결되지 않았으면 연결
    if (!_isConnected) {
      final connected = await connectToServer();
      if (!connected) return false;
    }

    try {
      // 이력서 데이터 전송
      final resumeSuccess =
          await _interviewService.uploadResumeData(_selectedResume!.toJson());

      if (!resumeSuccess) {
        _errorMessage = '이력서 데이터 전송에 실패했습니다';
        notifyListeners();
        return false;
      }

      // 더미 카메라 사용 중임을 서버에 알림 (필요한 경우)
      if (_cameraService.isUsingDummyCamera) {
        print('더미 카메라를 사용 중입니다. 비디오 없이 인터뷰가 진행됩니다.');
      }

      // 인터뷰 시작
      final success = await _interviewService.startInterview();

      if (success) {
        _isInterviewStarted = true;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = '인터뷰 시작에 실패했습니다';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '인터뷰 시작 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  /// 면접 종료
  Future<void> stopInterview() async {
    if (!_isInterviewStarted) return;

    try {
      _isUploadingVideo = true;
      notifyListeners();

      _interviewService.stopInterview();
      _isInterviewStarted = false;

      // 비디오 업로드가 완료되면 상태 업데이트
      Future.delayed(const Duration(seconds: 2), () {
        _isUploadingVideo = false;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _errorMessage = '인터뷰 종료 중 오류가 발생했습니다: $e';
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  /// 다음 질문으로 이동
  bool moveToNextQuestion() {
    if (!_isInterviewStarted || _questions.isEmpty) {
      return false;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  /// 분석 로그 가져오기
  Future<String?> getAnalysisLog() async {
    try {
      return await _interviewService.getAnalysisLog();
    } catch (e) {
      _errorMessage = '분석 로그를 가져오는 중 오류가 발생했습니다: $e';
      notifyListeners();
      return null;
    }
  }

  /// 피드백 요약 가져오기
  Future<String?> getFeedbackSummary() async {
    try {
      return await _interviewService.getFeedbackSummary();
    } catch (e) {
      _errorMessage = '피드백을 가져오는 중 오류가 발생했습니다: $e';
      notifyListeners();
      return null;
    }
  }

  /// HTTP 상태 변경 처리
  void _handleHttpStateChanged() {
    _isConnected = _httpService.isConnected;
    notifyListeners();
  }

  /// 미디어 상태 변경 처리
  void _handleMediaStateChanged() {
    _lastCapturedFrame = _mediaService.lastCapturedVideoFrame;
    notifyListeners();
  }

  /// 인터뷰 상태 변경 처리
  void _handleInterviewStateChanged() {
    _isInterviewStarted = _interviewService.isInterviewStarted;
    notifyListeners();
  }

  /// 질문 로드 처리
  void _handleQuestionsLoaded(List<String> questions) {
    _questions = questions;
    _currentQuestionIndex = -1;
    notifyListeners();
  }

  /// 에러 처리
  void _handleError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // 인터뷰 중지
    if (_isInterviewStarted) {
      _interviewService.stopInterview();
    }

    // 서버 연결 해제
    if (_isConnected) {
      _httpService.disconnect();
    }

    // 리소스 해제
    _cameraService.dispose();
    _audioService.dispose();
    _mediaService.dispose();
    _httpService.dispose();

    super.dispose();
  }
}
