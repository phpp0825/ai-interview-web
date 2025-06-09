import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../services/common/video_recording_service.dart';

import '../services/resume/interfaces/resume_service_interface.dart';
import '../services/interview/interview_submission_service.dart';
import '../repositories/report/firebase_report_repository.dart';
import '../models/resume_model.dart';
import 'package:get_it/get_it.dart';

import '../services/interview/interview_state_service.dart';
import '../services/interview/interview_video_service.dart';
import '../services/interview/interview_analysis_service.dart';

/// 면접 화면의 UI 상태를 관리하는 컨트롤러
/// 실제 비즈니스 로직은 각 서비스에서 처리합니다
class InterviewController extends ChangeNotifier {
  // === 서비스들 ===
  late final InterviewStateService _stateService;
  late final InterviewVideoService _videoService;
  late final InterviewAnalysisService _analysisService;
  late final IResumeService _resumeService;
  final _reportRepository = FirebaseReportRepository();

  // === UI 상태 ===
  bool _isLoading = true;
  String? _errorMessage;
  ResumeModel? _selectedResume;
  List<Map<String, dynamic>> _resumeList = [];
  String? _generatedReportId;

  // === Getters ===
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ResumeModel? get selectedResume => _selectedResume;
  List<Map<String, dynamic>> get resumeList => _resumeList;
  String? get generatedReportId => _generatedReportId;

  // 상태 서비스 연결
  bool get isInterviewStarted => _stateService.isInterviewStarted;
  int get currentQuestionIndex => _stateService.currentQuestionIndex;
  bool get isCountdownActive => _stateService.isCountdownActive;
  int get countdownSeconds => _stateService.countdownSeconds;

  // 비디오 서비스 연결
  bool get isUploadingVideo => _videoService.isUploadingVideo;
  bool get isInterviewerVideoPlaying => _videoService.isInterviewerVideoPlaying;
  String get currentInterviewerVideoPath =>
      _videoService.currentInterviewerVideoPath;
  get cameraService => _videoService.cameraService;

  // 분석 서비스 연결
  bool get isAnalyzingVideo => _analysisService.isAnalyzingVideo;

  /// 생성자 - 서비스 의존성 주입
  InterviewController() {
    _initializeServices();
  }

  /// 서비스들 초기화 및 콜백 설정
  Future<void> _initializeServices() async {
    try {
      _updateState(loading: true);

      final serviceLocator = GetIt.instance;

      // 서비스 인스턴스 가져오기
      _stateService = serviceLocator<InterviewStateService>();
      _videoService = serviceLocator<InterviewVideoService>();
      _analysisService = serviceLocator<InterviewAnalysisService>();
      _resumeService = serviceLocator<IResumeService>();

      // 상태 변경 콜백 설정
      _stateService.setStateChangedCallback(_notifyListeners);
      _videoService.setStateChangedCallback(_notifyListeners);
      _analysisService.setStateChangedCallback(_notifyListeners);

      // 카운트다운 완료 콜백 설정
      _stateService.setCountdownCompletedCallback(_onCountdownCompleted);

      // 면접관 영상 완료 콜백 설정
      _videoService.setVideoCompletedCallback(_onInterviewerVideoCompleted);

      // 카메라 서비스 초기화
      final cameraService = serviceLocator<VideoRecordingService>();
      await _videoService.initializeCameraService(cameraService);

      // 이력서 목록 로드
      await _loadResumeList();

      _updateState(loading: false);
    } catch (e) {
      _updateState(loading: false, error: '서비스 초기화 중 오류가 발생했습니다: $e');
    }
  }

  /// 이력서 목록 가져오기
  Future<void> _loadResumeList() async {
    try {
      _resumeList = await _resumeService.getCurrentUserResumeList();
      notifyListeners();
    } catch (e) {
      print('이력서 목록 로드 실패: $e');
    }
  }

  /// 이력서 선택
  Future<bool> selectResume(String resumeId) async {
    try {
      final resumeData = await _resumeService.getResume(resumeId);
      if (resumeData != null) {
        _selectedResume = resumeData;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _updateState(error: '이력서 선택 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접 시작
  Future<bool> startInterview() async {
    if (_selectedResume == null) {
      _updateState(error: '이력서를 선택해주세요.');
      return false;
    }

    if (!_videoService.isCameraReady()) {
      _updateState(error: '카메라가 준비되지 않았습니다.');
      return false;
    }

    if (_videoService.isUsingDummyCamera()) {
      _updateState(error: '카메라에 접근할 수 없습니다. 더미 모드로 진행됩니다.');
    }

    try {
      await _videoService.stopAnyRecording();

      // 면접 상태 시작
      final started = _stateService.startInterview();
      if (!started) return false;

      // 첫 번째 질문 영상 재생
      await _videoService
          .playInterviewerVideo(_stateService.currentQuestionIndex);

      return true;
    } catch (e) {
      _updateState(error: '면접 시작 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접관 영상 완료 처리
  void _onInterviewerVideoCompleted() {
    if (_stateService.isInterviewStarted) {
      _stateService.startAnswerCountdown();
    }
  }

  /// 카운트다운 완료 처리
  void _onCountdownCompleted() {
    if (_stateService.isInterviewStarted) {
      _videoService.startAnswerRecording();
    }
  }

  /// 면접관 영상 완료 알림 (UI에서 호출)
  void onInterviewerVideoCompleted() {
    _videoService.onInterviewerVideoCompleted();
  }

  /// 다음 질문으로 넘어가기
  Future<void> moveToNextVideo() async {
    try {
      // 현재 답변 영상 업로드
      await _videoService.stopRecordingAndUpload(_generatedReportId);

      // 다음 질문으로 진행
      final hasNextQuestion = _stateService.moveToNextQuestion();

      if (hasNextQuestion) {
        // 다음 질문 영상 재생
        _videoService.resetVideoState();
        await Future.delayed(const Duration(milliseconds: 500));
        await _videoService
            .playInterviewerVideo(_stateService.currentQuestionIndex);
      } else {
        // 모든 질문 완료 - 면접 종료
        await _completeInterview();
      }
    } catch (e) {
      _updateState(error: '면접 진행 중 오류가 발생했습니다: $e');
    }
  }

  /// 면접 완료 처리
  Future<void> _completeInterview() async {
    _stateService.endInterview();

    // 리포트 생성
    await _generateReport();

    // 모든 영상 분석 요청
    final questions = _stateService.getInterviewQuestions();
    await _analysisService.analyzeAllVideos(
      videoUrls: _videoService.videoUrls,
      questions: questions,
      reportId: _generatedReportId,
    );

    _videoService.resetVideoState();
  }

  /// 면접 강제 종료
  Future<bool> endInterview() async {
    try {
      await _videoService.stopRecordingAndUpload(_generatedReportId);
      _stateService.endInterview();

      // 리포트 생성 (영상이 있으면)
      if (_selectedResume != null && _videoService.videoUrls.isNotEmpty) {
        await _generateReport();

        final questions = _stateService.getInterviewQuestions();
        await _analysisService.analyzeAllVideos(
          videoUrls: _videoService.videoUrls,
          questions: questions,
          reportId: _generatedReportId,
        );
      }

      _videoService.resetVideoState();
      return true;
    } catch (e) {
      _updateState(error: '면접 종료 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접 리포트 생성
  Future<void> _generateReport() async {
    try {
      if (_selectedResume == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final duration = _stateService.getInterviewDuration();

      final reportId = await _reportRepository.generateInterviewReport(
        questions: [],
        answers: [],
        videoUrls: _videoService.videoUrls,
        resume: _selectedResume!,
        duration: duration,
        userId: currentUser.uid,
      );

      _generatedReportId = reportId;
    } catch (e) {
      _updateState(error: '면접 리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 하위 호환성을 위한 별칭 메서드
  Future<void> stopFullInterview() => endInterview();

  /// 상태 업데이트
  void _updateState({bool? loading, String? error}) {
    if (loading != null) _isLoading = loading;
    if (error != null) _errorMessage = error;
    notifyListeners();
  }

  /// 상태 변경 알림
  void _notifyListeners() {
    notifyListeners();
  }

  /// 메모리 정리
  @override
  void dispose() {
    if (_stateService.isInterviewStarted) {
      endInterview().catchError((error) {
        print('dispose에서 면접 종료 중 오류: $error');
      });
    }

    _stateService.dispose();
    _videoService.dispose();
    _analysisService.dispose();

    super.dispose();
  }
}
