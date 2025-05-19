import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/interview/interfaces/interview_service_interface.dart';
import '../services/interview/interfaces/media_service_interface.dart';
import '../services/common/video_recording_service.dart';
import '../services/common/image_capture_service.dart';
import '../services/common/audio_service.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
import '../models/resume_model.dart';
import '../services/report/interfaces/report_service_interface.dart';
import 'package:get_it/get_it.dart';

/// 인터뷰 기능을 제어하는 컨트롤러
class InterviewController with ChangeNotifier {
  // 서비스 인스턴스
  final VideoRecordingService _cameraService;
  final ImageCaptureService _imageCaptureService;
  final AudioService _audioService;
  final IResumeService _resumeService;
  final IReportService _reportService;
  final IInterviewService _interviewService;
  final IMediaService _mediaService;

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
  VideoRecordingService get cameraService => _cameraService;
  ImageCaptureService get imageCaptureService => _imageCaptureService;

  // 생성자 - 직접 호출 대신 create 팩토리 메서드를 사용하세요
  InterviewController._internal({
    required VideoRecordingService cameraService,
    required ImageCaptureService imageCaptureService,
    required AudioService audioService,
    required IResumeService resumeService,
    required IReportService reportService,
    required IInterviewService interviewService,
    required IMediaService mediaService,
    required String serverUrl,
  })  : _cameraService = cameraService,
        _imageCaptureService = imageCaptureService,
        _audioService = audioService,
        _resumeService = resumeService,
        _reportService = reportService,
        _interviewService = interviewService,
        _mediaService = mediaService,
        _serverUrl = serverUrl {
    _initialize();
  }

  /// 상태 변경 유틸리티 메서드 - 상태 변수들을 한 번에 변경하고 알림
  void _updateState({
    bool? isInitialized,
    bool? isConnecting,
    bool? isConnected,
    bool? isInterviewStarted,
    bool? isUploadingVideo,
    bool? isCreatingReport,
    ResumeModel? selectedResume,
    List<Map<String, dynamic>>? resumeList,
    Uint8List? lastCapturedFrame,
    List<String>? questions,
    int? currentQuestionIndex,
    String? errorMessage,
  }) {
    if (isInitialized != null) _isInitialized = isInitialized;
    if (isConnecting != null) _isConnecting = isConnecting;
    if (isConnected != null) _isConnected = isConnected;
    if (isInterviewStarted != null) _isInterviewStarted = isInterviewStarted;
    if (isUploadingVideo != null) _isUploadingVideo = isUploadingVideo;
    if (isCreatingReport != null) _isCreatingReport = isCreatingReport;
    if (selectedResume != null) _selectedResume = selectedResume;
    if (resumeList != null) _resumeList = resumeList;
    if (lastCapturedFrame != null) _lastCapturedFrame = lastCapturedFrame;
    if (questions != null) _questions = questions;
    if (currentQuestionIndex != null)
      _currentQuestionIndex = currentQuestionIndex;
    if (errorMessage != null) _errorMessage = errorMessage;

    notifyListeners();
  }

  /// 에러 처리 유틸리티 메서드
  void _handleError(String message, dynamic error) {
    final errorMsg = '$message: $error';
    print(errorMsg); // 디버깅을 위한 로그
    _updateState(errorMessage: errorMsg);
  }

  /// 컨트롤러 초기화
  Future<void> _initialize() async {
    try {
      // 초기화 중임을 표시
      _updateState(isInitialized: false, errorMessage: null);

      print('인터뷰 컨트롤러 초기화 시작...');

      // 1단계: 카메라 초기화
      try {
        print('카메라 초기화 중...');
        await _cameraService.initialize();
        print('카메라 초기화 완료');
      } catch (e) {
        print('카메라 초기화 실패: $e');
        _updateState(errorMessage: '카메라를 초기화하는데 실패했습니다: $e');
        // 카메라 초기화 실패해도 계속 진행
      }

      // 2단계: 오디오 초기화
      try {
        print('오디오 초기화 중...');
        await _audioService.initialize();
        print('오디오 초기화 완료');
      } catch (e) {
        print('오디오 초기화 실패: $e');
        _updateState(errorMessage: '오디오를 초기화하는데 실패했습니다: $e');
        // 오디오 초기화 실패해도 계속 진행
      }

      // 3단계: 미디어 서비스 콜백 설정
      try {
        print('미디어 서비스 콜백 설정 중...');
        _mediaService.setVideoFrameCallback(() async {
          if (_cameraService.isInitialized) {
            final frameData = await _imageCaptureService.captureFrame();
            if (frameData == null && _cameraService.isUsingDummyCamera) {
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
        print('미디어 서비스 콜백 설정 완료');
      } catch (e) {
        print('미디어 서비스 콜백 설정 실패: $e');
        _updateState(errorMessage: '미디어 서비스를 설정하는데 실패했습니다: $e');
        // 미디어 서비스 설정 실패해도 계속 진행
      }

      // 4단계: 이력서 목록 로드
      try {
        print('이력서 목록 로드 중...');
        await loadResumeList();
        print('이력서 목록 로드 완료');
      } catch (e) {
        print('이력서 목록 로드 실패: $e');
        _updateState(errorMessage: '이력서 목록을 로드하는데 실패했습니다: $e');
        // 이력서 로드 실패해도 계속 진행
      }

      print('인터뷰 컨트롤러 초기화 완료');
      _updateState(isInitialized: true);
    } catch (e) {
      print('인터뷰 컨트롤러 초기화 중 치명적 오류: $e');
      _handleError('컨트롤러 초기화 중 오류가 발생했습니다', e);
    }
  }

  /// 이력서 목록 로드
  Future<void> loadResumeList() async {
    try {
      print('이력서 목록 가져오기 시작...');

      // 이력서 서비스가 초기화되었는지 확인
      if (_resumeService == null) {
        throw Exception('이력서 서비스가 초기화되지 않았습니다');
      }

      // 이력서 목록 요청
      final resumeList = await _resumeService.getCurrentUserResumeList();
      print('이력서 목록 가져오기 성공: ${resumeList.length}개 항목');

      _updateState(resumeList: resumeList);

      // 자동 선택 로직 제거
      if (resumeList.isEmpty) {
        print('이력서 목록이 비어있습니다');
      } else {
        print('이력서 목록을 성공적으로 불러왔습니다. 이력서를 선택해주세요.');
      }
    } catch (e) {
      print('이력서 목록 로드 중 오류 발생: $e');
      _handleError('이력서 목록을 로드하는 중 오류가 발생했습니다', e);
    }
  }

  /// 이력서 선택
  Future<void> selectResume(String resumeId) async {
    try {
      print('이력서 선택 시작: $resumeId');

      if (resumeId.isEmpty) {
        throw Exception('유효하지 않은 이력서 ID');
      }

      // 이력서 서비스가 초기화되었는지 확인
      if (_resumeService == null) {
        throw Exception('이력서 서비스가 초기화되지 않았습니다');
      }

      print('이력서 상세정보 요청 중...');
      final resumeData = await _resumeService.getResume(resumeId);

      if (resumeData != null) {
        print('이력서 선택 성공: ${resumeData.position} (${resumeData.field})');
        _updateState(selectedResume: resumeData);
      } else {
        print('이력서를 찾을 수 없음: $resumeId');
        throw Exception('해당 ID의 이력서를 찾을 수 없습니다: $resumeId');
      }
    } catch (e) {
      print('이력서 선택 중 오류 발생: $e');
      _handleError('이력서 데이터를 가져오는 중 오류가 발생했습니다', e);
    }
  }

  /// 서버 연결
  Future<bool> connectToServer() async {
    if (_isConnected) return true;

    _updateState(isConnecting: true, errorMessage: null);

    try {
      // 서버에 연결
      final success = await _mediaService.connect(_serverUrl);

      _updateState(
          isConnecting: false,
          isConnected: success,
          errorMessage: success ? null : '서버에 연결할 수 없습니다');

      return success;
    } catch (e) {
      _updateState(isConnecting: false, isConnected: false);
      _handleError('서버 연결 중 오류가 발생했습니다', e);
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
      await _mediaService.disconnect();

      _updateState(isConnected: false);
    } catch (e) {
      _handleError('서버 연결 해제 중 오류가 발생했습니다', e);
    }
  }

  /// 면접 시작
  Future<bool> startInterview() async {
    if (_isInterviewStarted) return true;

    if (_selectedResume == null) {
      _updateState(errorMessage: '인터뷰를 시작하려면 이력서를 선택해야 합니다');
      return false;
    }

    try {
      final success = await _interviewService.startInterview();
      if (success) {
        _updateState(isInterviewStarted: true, errorMessage: null);
      }
      return success;
    } catch (e) {
      _handleError('인터뷰 시작 중 오류가 발생했습니다', e);
      return false;
    }
  }

  /// 면접 종료
  Future<void> stopInterview() async {
    if (!_isInterviewStarted) return;

    try {
      _updateState(isUploadingVideo: true);

      await _interviewService.stopInterview();

      _updateState(isInterviewStarted: false);

      // 비디오 업로드가 완료되면 상태 업데이트
      await Future.delayed(const Duration(seconds: 2));
      _updateState(isUploadingVideo: false);
    } catch (e) {
      _updateState(isUploadingVideo: false);
      _handleError('인터뷰 종료 중 오류가 발생했습니다', e);
    }
  }

  /// 다음 질문으로 이동
  bool moveToNextQuestion() {
    if (!_isInterviewStarted || _questions.isEmpty) {
      return false;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _updateState(currentQuestionIndex: _currentQuestionIndex + 1);
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
      _handleError('분석 로그를 가져오는 중 오류가 발생했습니다', e);
      return null;
    }
  }

  /// 피드백 요약 가져오기
  Future<String?> getFeedbackSummary() async {
    try {
      return await _interviewService.getFeedbackSummary();
    } catch (e) {
      _handleError('피드백을 가져오는 중 오류가 발생했습니다', e);
      return null;
    }
  }

  /// 현재 질문에 대한 TTS 음성 재생
  Future<bool> playCurrentQuestionTts() async {
    if (!_isInterviewStarted) {
      _updateState(errorMessage: '인터뷰가 시작되지 않았습니다');
      return false;
    }

    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questions.length) {
      _updateState(errorMessage: '유효한 질문이 없습니다');
      return false;
    }

    try {
      _updateState(errorMessage: '음성 변환 중...');

      // 현재 질문 텍스트 가져오기
      final questionText = _questions[_currentQuestionIndex];
      print('TTS 요청: "$questionText"');

      // TTS 음성 데이터 요청
      final audioData = await _interviewService.requestTtsAudio(questionText);

      if (audioData == null || audioData.isEmpty) {
        _updateState(errorMessage: 'TTS 음성 생성에 실패했습니다');
        return false;
      }

      print('TTS 음성 데이터 수신: ${audioData.length} 바이트');
      _updateState(errorMessage: '음성 재생 중...');

      // 오디오 재생 (서버 응답의 Content-Type 자동 감지)
      await _audioService.playAudioBytes(audioData);

      _updateState(errorMessage: null);
      return true;
    } catch (e) {
      _handleError('TTS 재생 중 오류가 발생했습니다', e);
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearErrorMessage() {
    _updateState(errorMessage: null);
  }

  /// 면접 완료 후 리포트 생성
  Future<String?> createReportFromInterview() async {
    if (_selectedResume == null) {
      _updateState(errorMessage: '리포트를 생성하려면 이력서가 필요합니다');
      return null;
    }

    try {
      _updateState(isCreatingReport: true);

      // 인터뷰 ID 생성 (실제 앱에서는 인터뷰 서비스에서 제공할 수 있음)
      final interviewId = 'interview_${DateTime.now().millisecondsSinceEpoch}';

      // 리포트 서비스를 통해 리포트 생성
      final report = await _reportService.createReport(
        interviewId: interviewId,
        resumeId: _selectedResume!.resume_id,
        resumeData: _selectedResume!.toJson(),
      );

      _updateState(isCreatingReport: false);
      return report?.id;
    } catch (e) {
      _handleError('리포트를 생성하는데 실패했습니다', e);
      _updateState(isCreatingReport: false);
      return null;
    }
  }

  @override
  void dispose() {
    // 인터뷰 중지
    if (_isInterviewStarted) {
      _interviewService.stopInterview();
    }

    // 서버 연결 해제
    if (_isConnected) {
      _mediaService.disconnect();
    }

    // 리소스 해제
    _imageCaptureService.dispose();
    _cameraService.dispose();
    _audioService.dispose();
    _mediaService.dispose();

    super.dispose();
  }

  /// 팩토리 생성자 - 모든 서비스를 초기화해서 컨트롤러를 만듭니다
  static Future<InterviewController?> create({
    String serverUrl = 'http://localhost:8080',
  }) async {
    try {
      print('InterviewController 생성 시작...');
      final serviceLocator = GetIt.instance;

      // 필요한 서비스가 등록되어 있는지 확인
      print('서비스 로케이터에서 필요한 서비스 확인 중...');

      // 서비스 가져오기 (하나라도 실패하면 예외 발생)
      print('서비스 로케이터에서 서비스 가져오기...');

      final VideoRecordingService cameraService;
      final ImageCaptureService imageCaptureService;
      final AudioService audioService;
      final IResumeService resumeService;
      final IReportService reportService;
      final IInterviewService interviewService;
      final IMediaService mediaService;

      try {
        cameraService = serviceLocator<VideoRecordingService>();
        print('VideoRecordingService 가져오기 성공');
      } catch (e) {
        print('VideoRecordingService 가져오기 실패: $e');
        throw Exception('카메라 서비스를 찾을 수 없습니다: $e');
      }

      try {
        imageCaptureService = serviceLocator<ImageCaptureService>();
        print('ImageCaptureService 가져오기 성공');
      } catch (e) {
        print('ImageCaptureService 가져오기 실패: $e');
        throw Exception('이미지 캡처 서비스를 찾을 수 없습니다: $e');
      }

      try {
        audioService = serviceLocator<AudioService>();
        print('AudioService 가져오기 성공');
      } catch (e) {
        print('AudioService 가져오기 실패: $e');
        throw Exception('오디오 서비스를 찾을 수 없습니다: $e');
      }

      try {
        resumeService = serviceLocator<IResumeService>();
        print('IResumeService 가져오기 성공');
      } catch (e) {
        print('IResumeService 가져오기 실패: $e');
        throw Exception('이력서 서비스를 찾을 수 없습니다: $e');
      }

      try {
        reportService = serviceLocator<IReportService>();
        print('IReportService 가져오기 성공');
      } catch (e) {
        print('IReportService 가져오기 실패: $e');
        throw Exception('리포트 서비스를 찾을 수 없습니다: $e');
      }

      try {
        interviewService = serviceLocator<IInterviewService>();
        print('IInterviewService 가져오기 성공');
      } catch (e) {
        print('IInterviewService 가져오기 실패: $e');
        throw Exception('인터뷰 서비스를 찾을 수 없습니다: $e');
      }

      try {
        mediaService = serviceLocator<IMediaService>();
        print('IMediaService 가져오기 성공');
      } catch (e) {
        print('IMediaService 가져오기 실패: $e');
        throw Exception('미디어 서비스를 찾을 수 없습니다: $e');
      }

      print('모든 서비스 로드 완료, 컨트롤러 생성 중...');

      // 모든 서비스 로드 성공, 컨트롤러 생성
      return InterviewController._internal(
        cameraService: cameraService,
        imageCaptureService: imageCaptureService,
        audioService: audioService,
        resumeService: resumeService,
        reportService: reportService,
        interviewService: interviewService,
        mediaService: mediaService,
        serverUrl: serverUrl,
      );
    } catch (e) {
      print('InterviewController 생성 실패: $e');
      return null;
    }
  }
}
