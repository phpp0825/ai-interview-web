import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/common/video_recording_service.dart';
import '../services/common/firebase_storage_service.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
import '../repositories/report/firebase_report_repository.dart';
import '../models/resume_model.dart';
import 'package:get_it/get_it.dart';

/// 면접 전체 과정을 관리하는 컨트롤러
/// 면접의 시작부터 끝까지 모든 단계를 처리합니다
class InterviewController extends ChangeNotifier {
  // === 서비스들 ===
  VideoRecordingService? _cameraService;
  IResumeService? _resumeService;
  final _reportRepository = FirebaseReportRepository();
  final _storageService = FirebaseStorageService();

  // === 기본 상태 ===
  bool _isLoading = true;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  String? _errorMessage;

  // === 면접 데이터 ===
  DateTime? _interviewStartTime;
  final List<String> _videoUrls = [];
  String? _generatedReportId;
  ResumeModel? _selectedResume;
  List<Map<String, dynamic>> _resumeList = [];

  // === 현재 진행 상황 ===
  int _currentQuestionIndex = -1;
  bool _isInterviewerVideoPlaying = false;
  String _currentInterviewerVideoPath = '';

  // === 카운트다운 ===
  bool _isCountdownActive = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  // === 화면에서 사용할 데이터들 (Getters) ===
  bool get isLoading => _isLoading;
  bool get isInterviewStarted => _isInterviewStarted;
  bool get isUploadingVideo => _isUploadingVideo;
  String? get errorMessage => _errorMessage;
  ResumeModel? get selectedResume => _selectedResume;
  List<Map<String, dynamic>> get resumeList => _resumeList;
  int get currentQuestionIndex => _currentQuestionIndex;
  VideoRecordingService? get cameraService => _cameraService;
  IResumeService? get resumeService => _resumeService;
  bool get isInterviewerVideoPlaying => _isInterviewerVideoPlaying;
  String get currentInterviewerVideoPath => _currentInterviewerVideoPath;
  String? get generatedReportId => _generatedReportId;
  bool get isCountdownActive => _isCountdownActive;
  int get countdownSeconds => _countdownSeconds;

  // === 생성자 - 컨트롤러가 만들어질 때 서비스들을 준비합니다 ===
  InterviewController() {
    _initializeServices();
  }

  // === 서비스 초기화 - 카메라와 이력서 서비스를 준비합니다 ===
  Future<void> _initializeServices() async {
    try {
      _updateState(loading: true);

      final serviceLocator = GetIt.instance;

      // 카메라 서비스 초기화
      _cameraService = serviceLocator<VideoRecordingService>();
      await _cameraService!.initialize();

      // 이력서 서비스 초기화 및 목록 로드
      _resumeService = serviceLocator<IResumeService>();
      await _loadResumeList();

      _updateState(loading: false);
    } catch (e) {
      _updateState(loading: false, error: '서비스 초기화 중 오류가 발생했습니다: $e');
    }
  }

  // === 이력서 목록 가져오기 ===
  Future<void> _loadResumeList() async {
    try {
      if (_resumeService != null) {
        _resumeList = await _resumeService!.getCurrentUserResumeList();
        notifyListeners();
      }
    } catch (e) {
      print('이력서 목록 로드 실패: $e');
    }
  }

  // === 사용할 이력서 선택하기 ===
  Future<bool> selectResume(String resumeId) async {
    try {
      if (_resumeService != null) {
        final resumeData = await _resumeService!.getResume(resumeId);
        if (resumeData != null) {
          _selectedResume = resumeData;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _updateState(error: '이력서 선택 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  // === 면접 시작하기 ===
  Future<bool> startInterview() async {
    if (_selectedResume == null) {
      _updateState(error: '이력서를 선택해주세요.');
      return false;
    }

    if (!_isCameraReady()) {
      return false;
    }

    try {
      await _stopAnyRecording(); // 기존 녹화 정리

      // 면접 시작 설정
      _isInterviewStarted = true;
      _interviewStartTime = DateTime.now();
      _currentQuestionIndex = 0;

      // 첫 번째 질문 영상 재생
      await _playCurrentQuestion();

      notifyListeners();
      return true;
    } catch (e) {
      _updateState(error: '면접 시작 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  // === 카메라 준비 상태 확인 ===
  bool _isCameraReady() {
    if (_cameraService == null || !_cameraService!.isInitialized) {
      _updateState(error: '카메라가 준비되지 않았습니다. 잠시 후 다시 시도해주세요.');
      return false;
    }

    if (_cameraService!.isUsingDummyCamera) {
      _updateState(
          error: '카메라에 접근할 수 없습니다. 브라우저에서 카메라 권한을 허용해주세요.\n'
              '더미 모드로 면접을 진행하지만 영상이 녹화되지 않을 수 있습니다.');
    }

    return true;
  }

  // === 현재 질문 영상 재생 ===
  Future<void> _playCurrentQuestion() async {
    try {
      final questionNumber = _currentQuestionIndex + 1;
      _currentInterviewerVideoPath =
          'assets/videos/question_$questionNumber.mp4';
      _isInterviewerVideoPlaying = false;
      notifyListeners();

      // 영상 로드 대기
      await Future.delayed(const Duration(seconds: 2));

      if (_isInterviewStarted) {
        _isInterviewerVideoPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      _updateState(error: '면접관 영상 재생 중 오류가 발생했습니다: $e');
    }
  }

  // === 면접관 영상이 끝났을 때 호출되는 함수 ===
  void onInterviewerVideoCompleted() {
    if (_isInterviewStarted) {
      _startAnswerCountdown();
    }
  }

  // === 답변 준비 카운트다운 시작 ===
  void _startAnswerCountdown() {
    _isCountdownActive = true;
    _countdownSeconds = 5;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _isCountdownActive = false;
        _isInterviewerVideoPlaying = false;
        notifyListeners();

        if (_isInterviewStarted) {
          _startRecordingAnswer();
        }
      }
    });
  }

  // === 답변 녹화 시작 ===
  Future<void> _startRecordingAnswer() async {
    try {
      if (_cameraService != null && !_cameraService!.isRecording) {
        await _cameraService!.startVideoRecording();
      }
    } catch (e) {
      print('답변 녹화 시작 실패: $e');
    }
  }

  // === 다음 질문으로 넘어가기 ===
  Future<void> moveToNextVideo() async {
    const totalQuestions = 3;

    try {
      // 현재 답변 영상 업로드
      await _stopAndUploadVideo();

      if (_currentQuestionIndex < totalQuestions - 1) {
        // 다음 질문으로 이동
        _currentQuestionIndex++;
        _resetVideoState();
        await Future.delayed(const Duration(milliseconds: 500));
        await _playCurrentQuestion();
      } else {
        // 모든 질문 완료 - 면접 종료
        await _completeInterview();
      }

      notifyListeners();
    } catch (e) {
      _updateState(error: '면접 진행 중 오류가 발생했습니다: $e');
    }
  }

  // === 녹화 중지 및 영상 업로드 (통합된 메서드) ===
  Future<void> _stopAndUploadVideo() async {
    if (_cameraService == null || !_cameraService!.isRecording) {
      return;
    }

    try {
      _isUploadingVideo = true;
      notifyListeners();

      // 녹화 중지 및 영상 파일 가져오기
      await _cameraService!.stopVideoRecording();
      final videoBytes = await _cameraService!.getRecordedVideoBytes();

      if (videoBytes != null) {
        await _uploadToFirebase(videoBytes);
      }
    } catch (e) {
      print('비디오 업로드 중 오류: $e');
    } finally {
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  // === Firebase에 영상 업로드 ===
  Future<void> _uploadToFirebase(Uint8List videoBytes) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final interviewId = _generatedReportId ??
        'interview_${DateTime.now().millisecondsSinceEpoch}';
    final fileName =
        'question_${_currentQuestionIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final uploadedUrl = await _storageService.uploadInterviewVideo(
      videoData: videoBytes,
      userId: currentUser.uid,
      interviewId: interviewId,
      fileName: fileName,
    );

    if (uploadedUrl != null) {
      _videoUrls.add(uploadedUrl);
    }
  }

  // === 영상 상태 초기화 ===
  void _resetVideoState() {
    _isInterviewerVideoPlaying = false;
    _currentInterviewerVideoPath = '';
    notifyListeners();
  }

  // === 어떤 녹화든 중지 (안전한 정리) ===
  Future<void> _stopAnyRecording() async {
    if (_cameraService != null && _cameraService!.isRecording) {
      await _cameraService!.stopVideoRecording();
    }
  }

  // === 면접 완료 처리 (모든 질문 끝) ===
  Future<void> _completeInterview() async {
    _isInterviewStarted = false;
    _resetVideoState();
    await _generateReport();
  }

  // === 면접 강제 종료 (사용자가 중간에 종료) ===
  Future<bool> endInterview() async {
    try {
      // 현재 녹화 중인 것 정리 및 업로드
      await _stopAndUploadVideo();

      // 면접 상태 완전히 정리
      _isInterviewStarted = false;
      _resetVideoState();
      _cleanupTimers();

      // 리포트 생성 (영상이 있으면)
      if (_selectedResume != null && _videoUrls.isNotEmpty) {
        await _generateReport();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _updateState(error: '면접 종료 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  // === 면접 리포트 생성 ===
  Future<void> _generateReport() async {
    try {
      if (_selectedResume == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final duration = _interviewStartTime != null
          ? DateTime.now().difference(_interviewStartTime!).inSeconds
          : 0;

      final reportId = await _reportRepository.generateInterviewReport(
        questions: [],
        answers: [],
        videoUrls: _videoUrls,
        resume: _selectedResume!,
        duration: duration,
        userId: currentUser.uid,
      );

      _generatedReportId = reportId;
    } catch (e) {
      _updateState(error: '면접 리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  // === 타이머들 정리 ===
  void _cleanupTimers() {
    _countdownTimer?.cancel();
    _isCountdownActive = false;
    _countdownSeconds = 0;
  }

  // === 상태 업데이트 (통합된 메서드) ===
  void _updateState({bool? loading, String? error}) {
    if (loading != null) _isLoading = loading;
    if (error != null) _errorMessage = error;
    notifyListeners();
  }

  // === 별칭 메서드들 (하위 호환성) ===
  Future<void> stopFullInterview() => endInterview();

  // === 메모리 정리 ===
  @override
  void dispose() {
    _cleanupTimers();

    if (_isInterviewStarted) {
      endInterview().catchError((error) {
        print('dispose에서 면접 종료 중 오류: $error');
      });
    }

    _cameraService?.dispose().catchError((error) {
      print('카메라 해제 중 오류: $error');
    });

    super.dispose();
  }
}
