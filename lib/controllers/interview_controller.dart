import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/common/video_recording_service.dart';
import '../services/common/firebase_storage_service.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
import '../repositories/report/firebase_report_repository.dart';
import '../models/resume_model.dart';
import 'package:get_it/get_it.dart';

/// 면접 관련 로직을 관리하는 컨트롤러
/// UI에서 면접 관련 비즈니스 로직을 분리하여 관리합니다.
///
class InterviewController extends ChangeNotifier {
  // 서비스들
  VideoRecordingService? _cameraService;
  IResumeService? _resumeService;
  final FirebaseReportRepository _reportRepository = FirebaseReportRepository();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // 상태 변수
  bool _isLoading = true;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  String? _errorMessage;

  // 면접 진행 상태 변수
  DateTime? _interviewStartTime;
  final List<String> _videoUrls = [];
  String? _generatedReportId;

  // 면접 관련 상태
  ResumeModel? _selectedResume;
  List<Map<String, dynamic>> _resumeList = [];
  int _currentQuestionIndex = -1; // 영상 인덱스로 사용
  Uint8List? _lastCapturedFrame;
  Uint8List? _serverResponseImage;

  // 면접관 영상 관련 상태
  bool _isInterviewerVideoPlaying = false;
  String _currentInterviewerVideoPath = '';

  // 카운트다운 관련 상태
  bool _isCountdownActive = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  Timer? _videoCompletionTimer;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInterviewStarted => _isInterviewStarted;
  bool get isUploadingVideo => _isUploadingVideo;
  String? get errorMessage => _errorMessage;
  ResumeModel? get selectedResume => _selectedResume;
  List<Map<String, dynamic>> get resumeList => _resumeList;
  int get currentQuestionIndex => _currentQuestionIndex;
  Uint8List? get lastCapturedFrame => _lastCapturedFrame;
  Uint8List? get serverResponseImage => _serverResponseImage;
  VideoRecordingService? get cameraService => _cameraService;
  IResumeService? get resumeService => _resumeService;
  bool get isInterviewerVideoPlaying => _isInterviewerVideoPlaying;
  String get currentInterviewerVideoPath => _currentInterviewerVideoPath;
  String? get generatedReportId => _generatedReportId;

  // 카운트다운 관련 게터들
  bool get isCountdownActive => _isCountdownActive;
  int get countdownSeconds => _countdownSeconds;

  /// 생성자
  InterviewController() {
    initializeServices();
  }

  /// 서비스 초기화 (간소화)
  Future<void> initializeServices() async {
    try {
      print('InterviewController: 서비스 초기화 시작');
      _setLoading(true);
      _setErrorMessage(null);

      // GetIt에서 필요한 서비스들 가져오기
      final serviceLocator = GetIt.instance;

      try {
        _cameraService = serviceLocator<VideoRecordingService>();
        await _cameraService!.initialize();
        print('InterviewController: 카메라 서비스 초기화 성공');
      } catch (e) {
        print('InterviewController: 카메라 서비스 초기화 실패: $e');
      }

      try {
        _resumeService = serviceLocator<IResumeService>();
        await loadResumeList();
        print('InterviewController: 이력서 서비스 초기화 성공');
      } catch (e) {
        print('InterviewController: 이력서 서비스 초기화 실패: $e');
      }

      print('InterviewController: 서비스 초기화 완료');
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

  /// 면접 시작
  Future<bool> startInterview() async {
    if (_selectedResume == null) {
      _setErrorMessage('이력서를 선택해주세요.');
      return false;
    }

    try {
      print('🎬 면접 시작 준비 중...');

      // 카메라 준비 상태 상세 확인
      if (_cameraService == null) {
        _setErrorMessage('카메라 서비스가 초기화되지 않았습니다.');
        return false;
      }

      if (!_cameraService!.isInitialized) {
        _setErrorMessage('카메라가 준비되지 않았습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }

      // 더미 카메라 모드 확인
      if (_cameraService!.isUsingDummyCamera) {
        print('⚠️ 더미 카메라 모드에서 면접을 진행합니다.');
        print('   - 실제 영상은 녹화되지 않습니다.');
        print('   - 브라우저에서 카메라 권한을 허용했는지 확인해주세요.');

        // 더미 카메라 모드에서도 면접은 진행하되, 경고 메시지 표시
        _setErrorMessage(
            '카메라에 접근할 수 없습니다. 브라우저에서 카메라 권한을 허용해주세요.\n더미 모드로 면접을 진행하지만 영상이 녹화되지 않을 수 있습니다.');
      }

      // 웹 환경에서 카메라 컨트롤러 상태 확인
      if (_cameraService!.controller != null) {
        final controller = _cameraService!.controller!;
        print('🔍 카메라 컨트롤러 상태 확인:');
        print('   - 초기화됨: ${controller.value.isInitialized}');
        print('   - 오류 상태: ${controller.value.hasError}');
        print('   - 해상도: ${controller.value.previewSize}');
        print('   - 오디오 활성화: ${controller.enableAudio}');

        if (controller.value.hasError) {
          _setErrorMessage('카메라 오류: ${controller.value.errorDescription}');
          return false;
        }
      }

      // 이미 녹화 중인 경우 중지
      if (_cameraService!.isRecording) {
        print('📹 기존 녹화 중지 중...');
        await _cameraService!.stopVideoRecording();
      }

      _isInterviewStarted = true;
      _interviewStartTime = DateTime.now();
      _currentQuestionIndex = 0; // 첫 번째 영상부터 시작

      print('✅ 면접 상태 설정 완료, 첫 번째 질문 시작');

      // 첫 번째 질문 영상 재생 및 녹화 시작
      await _playInterviewerVideo();

      notifyListeners();
      print('🎬 면접이 성공적으로 시작되었습니다!');
      return true;
    } catch (e) {
      print('❌ 면접 시작 중 오류: $e');
      _setErrorMessage('면접 시작 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접관 영상 재생
  Future<void> _playInterviewerVideo() async {
    try {
      // 현재 질문에 해당하는 면접관 영상 경로 생성
      final questionNumber = _currentQuestionIndex + 1;
      final videoPath = 'assets/videos/question_$questionNumber.mp4';

      print('🎭 면접관 영상 로드 시작: $videoPath');

      _currentInterviewerVideoPath = videoPath;
      _isInterviewerVideoPlaying = false; // 처음에는 로드만, 재생은 나중에
      notifyListeners();

      // 영상 로드 대기 후 재생 시작 (카운트다운은 영상 완료 후)
      await Future.delayed(const Duration(seconds: 2)); // 영상 로드 대기 시간

      // 면접이 여전히 진행 중인 경우에만 재생 시작
      if (_isInterviewStarted) {
        print('▶️ 면접관 영상 재생 시작');
        _isInterviewerVideoPlaying = true; // 재생 시작
        notifyListeners();

        // 영상 완료는 onInterviewerVideoCompleted 콜백으로 처리
        print('📺 영상 완료 시 자동으로 5초 카운트다운 시작됩니다');
      }
    } catch (e) {
      print('❌ 면접관 영상 재생 실패: $e');
      _setErrorMessage('면접관 영상 재생 중 오류가 발생했습니다: $e');
    }
  }

  /// 답변 녹화 스케줄링 (면접관 영상 재생 후)
  void _scheduleAnswerRecording() {
    // 이 메서드는 더 이상 사용하지 않음 - 카운트다운에서 직접 처리
  }

  /// 10초 카운트다운 시작
  void _startCountdown() {
    _isCountdownActive = true;
    _countdownSeconds = 5; // 10초에서 5초로 변경
    notifyListeners();

    print('⏰ 답변 준비 카운트다운 시작: ${_countdownSeconds}초');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      print('⏰ 카운트다운: ${_countdownSeconds}초');
      notifyListeners();

      if (_countdownSeconds <= 0) {
        // 카운트다운 완료 - 답변 녹화 시작 (면접관 영상은 정지)
        timer.cancel();
        _isCountdownActive = false;
        _countdownSeconds = 0;
        _isInterviewerVideoPlaying = false; // 면접관 영상 재생 중지
        notifyListeners();

        if (_isInterviewStarted) {
          print('🎤 답변 녹화 시작 (질문 ${_currentQuestionIndex + 1})');
          print('⏹️ 면접관 영상 재생 중지');
          _startAnswerRecording();
        }
      }
    });
  }

  /// 답변 녹화 시작
  Future<void> _startAnswerRecording() async {
    try {
      if (_cameraService != null && !_cameraService!.isRecording) {
        await _cameraService!.startVideoRecording();
        print('📹 답변 녹화 시작됨 (질문 ${_currentQuestionIndex + 1})');
      }
    } catch (e) {
      print('❌ 답변 녹화 시작 실패: $e');
    }
  }

  /// 면접관 영상 중지 및 답변 시간 시작
  Future<void> stopInterviewerVideo() async {
    _isInterviewerVideoPlaying = false;
    _currentInterviewerVideoPath = '';
    notifyListeners();
    print('⏹️ 면접관 영상 중지');
  }

  /// 다음 영상으로 이동 (비디오 업로드 포함)
  Future<void> moveToNextVideo() async {
    const totalVideos = 3; // 총 질문 개수 (3개로 변경)

    try {
      print('📤 현재 답변 영상 업로드 시작...');

      // 현재 녹화 중인 비디오 중지 및 업로드 완료까지 대기
      await _stopAndUploadCurrentVideo();

      print('✅ 업로드 완료! 다음 단계로 진행합니다.');

      if (_currentQuestionIndex < totalVideos - 1) {
        _currentQuestionIndex++;
        print('📋 다음 질문으로 이동: ${_currentQuestionIndex + 1}번째 질문');

        // 이전 면접관 영상 상태 초기화
        _isInterviewerVideoPlaying = false;
        _currentInterviewerVideoPath = '';
        notifyListeners();

        // 잠시 대기 후 다음 면접관 영상 재생
        await Future.delayed(const Duration(milliseconds: 500));
        await _playInterviewerVideo();
      } else {
        // 모든 질문 완료 - 면접 종료
        print('🎉 모든 질문 완료! 면접을 종료합니다.');
        _isInterviewStarted = false;
        _isInterviewerVideoPlaying = false;
        _currentInterviewerVideoPath = '';
        await _generateFinalReport();
      }
      notifyListeners();
    } catch (e) {
      print('❌ 다음 질문으로 이동 중 오류: $e');
      _setErrorMessage('면접 진행 중 오류가 발생했습니다: $e');
    }
  }

  /// 현재 비디오 녹화 중지 및 Firebase Storage 업로드
  Future<void> _stopAndUploadCurrentVideo() async {
    if (_cameraService == null || !_cameraService!.isRecording) {
      print('녹화 중인 비디오가 없습니다.');
      return;
    }

    try {
      print('📹 현재 비디오 녹화 중지 중...');

      // 1단계: 즉시 녹화 중지
      final videoPath = await _cameraService!.stopVideoRecording();
      print('✅ 비디오 녹화 중지 완료: $videoPath');

      // 2단계: 업로드 시작 표시
      _isUploadingVideo = true;
      notifyListeners();

      // 3단계: 녹화가 완전히 중지된 후 업로드 진행
      if (videoPath != null) {
        // 비디오 파일을 바이트로 읽기
        final videoBytes = await _cameraService!.getRecordedVideoBytes();

        if (videoBytes != null) {
          // 현재 로그인된 사용자 가져오기
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            // Firebase Storage에 업로드
            final interviewId = _generatedReportId ??
                'interview_${DateTime.now().millisecondsSinceEpoch}';
            final fileName =
                'question_${_currentQuestionIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

            print('🔥 Firebase Storage에 업로드 중: $fileName');
            final uploadedUrl = await _storageService.uploadInterviewVideo(
              videoData: videoBytes,
              userId: currentUser.uid,
              interviewId: interviewId,
              fileName: fileName,
            );

            if (uploadedUrl != null) {
              _videoUrls.add(uploadedUrl);
              print('✅ 비디오 업로드 성공: $uploadedUrl');
            } else {
              print('❌ 비디오 업로드 실패');
            }
          } else {
            print('❌ 로그인된 사용자가 없습니다.');
          }
        } else {
          print('❌ 비디오 파일을 읽을 수 없습니다.');
        }
      } else {
        print('❌ 비디오 녹화 중지 실패');
      }
    } catch (e) {
      print('❌ 비디오 중지 및 업로드 중 오류: $e');
    } finally {
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  /// 면접 종료 (비디오+음성 함께 처리)
  Future<bool> endInterview() async {
    try {
      print('🛑 면접을 즉시 종료합니다...');

      // 1단계: 즉시 모든 녹화 중지
      if (_cameraService != null && _cameraService!.isRecording) {
        print('📹 녹화 즉시 중지 중...');
        final videoPath = await _cameraService!.stopVideoRecording();
        print('✅ 녹화 중지 완료: $videoPath');
      }

      // 2단계: 면접 상태 즉시 종료 (추가 녹화 방지)
      _isInterviewStarted = false;
      _isInterviewerVideoPlaying = false;
      _currentInterviewerVideoPath = '';

      // 카운트다운 타이머 정리
      _countdownTimer?.cancel();
      _videoCompletionTimer?.cancel();
      _isCountdownActive = false;
      _countdownSeconds = 0;

      notifyListeners(); // UI 즉시 업데이트

      // 3단계: 마지막 비디오 업로드 (녹화가 완전히 중지된 후)
      if (_cameraService != null) {
        await _uploadLastRecordedVideo();
      }

      // 4단계: 카메라 리소스 완전히 해제
      if (_cameraService != null) {
        print('📷 카메라 리소스 해제 중...');
        await _cameraService!.dispose();
        print('✅ 카메라 리소스 해제 완료');
      }

      // 5단계: 리포트 생성 (모든 영상 업로드 완료 후)
      if (_selectedResume != null && _videoUrls.isNotEmpty) {
        print('📊 면접 리포트 생성 중...');
        await _generateFinalReport();
      }

      print('✅ 면접 종료 완료!');
      return true;
    } catch (e) {
      print('❌ 면접 종료 중 오류 발생: $e');
      _setErrorMessage('면접 종료 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 마지막 녹화된 비디오 업로드 (녹화 완전 중지 후 실행)
  Future<void> _uploadLastRecordedVideo() async {
    try {
      _isUploadingVideo = true;
      notifyListeners();

      print('📤 마지막 녹화 영상 업로드 시작...');

      // 비디오 파일을 바이트로 읽기
      final videoBytes = await _cameraService!.getRecordedVideoBytes();

      if (videoBytes != null) {
        // 현재 로그인된 사용자 가져오기
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Firebase Storage에 업로드
          final interviewId = _generatedReportId ??
              'interview_${DateTime.now().millisecondsSinceEpoch}';
          final fileName =
              'question_${_currentQuestionIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

          print('🔥 Firebase Storage에 마지막 영상 업로드 중: $fileName');
          final uploadedUrl = await _storageService.uploadInterviewVideo(
            videoData: videoBytes,
            userId: currentUser.uid,
            interviewId: interviewId,
            fileName: fileName,
          );

          if (uploadedUrl != null) {
            _videoUrls.add(uploadedUrl);
            print('✅ 마지막 비디오 업로드 성공: $uploadedUrl');
            print('📊 총 업로드된 영상: ${_videoUrls.length}개');
          } else {
            print('❌ 마지막 비디오 업로드 실패');
          }
        } else {
          print('❌ 로그인된 사용자가 없습니다.');
        }
      } else {
        print('⚠️ 업로드할 비디오 파일이 없습니다.');
      }
    } catch (e) {
      print('❌ 마지막 비디오 업로드 중 오류: $e');
    } finally {
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  /// 면접 전체 중지 (실제 비디오 업로드 포함)
  Future<void> stopFullInterview() async {
    try {
      print('🏁 면접을 완전히 종료합니다...');

      // endInterview 메서드 재사용
      final success = await endInterview();

      if (success) {
        print('🏁 면접 전체 종료 완료');
      } else {
        print('❌ 면접 종료 중 일부 오류 발생');
      }
    } catch (e) {
      print('❌ 면접 종료 중 오류: $e');
      _setErrorMessage('면접 종료 중 오류가 발생했습니다: $e');
    }
  }

  /// 최종 리포트 생성 (간소화)
  Future<void> _generateFinalReport() async {
    try {
      if (_selectedResume == null) {
        throw Exception('이력서가 선택되지 않았습니다.');
      }

      // 현재 로그인된 사용자 ID 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 면접 소요 시간 계산 (초 단위)
      final duration = _interviewStartTime != null
          ? DateTime.now().difference(_interviewStartTime!).inSeconds
          : 0;

      // 리포트 생성 (질문은 영상으로 전달되므로 빈 리스트)
      final reportId = await _reportRepository.generateInterviewReport(
        questions: [], // 질문은 영상으로 전달되므로 빈 리스트
        answers: [], // 빈 배열로 전달
        videoUrls: _videoUrls,
        resume: _selectedResume!,
        duration: duration,
        userId: currentUser.uid, // 현재 로그인된 사용자의 ID 사용
      );

      _generatedReportId = reportId;
      print('📊 면접 리포트 생성 완료: $reportId');
    } catch (e) {
      print('❌ 면접 리포트 생성 실패: $e');
      _setErrorMessage('면접 리포트 생성 중 오류가 발생했습니다: $e');
    }
  }

  /// 영상이 실제로 완료되었을 때 호출되는 메서드
  void onInterviewerVideoCompleted() {
    print('📺 면접관 영상 실제 완료 감지');

    // 기존 타이머가 있으면 취소
    _videoCompletionTimer?.cancel();

    // 즉시 5초 카운트다운 시작 (재생 상태는 유지)
    if (_isInterviewStarted) {
      print('🎭 영상 완료, 재생 상태 유지하며 5초 카운트다운 시작');
      // _isInterviewerVideoPlaying = false; // 재생 상태 유지 (변경하지 않음)
      notifyListeners();
      _startCountdown();
    }
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
    // 타이머들 정리
    _countdownTimer?.cancel();
    _videoCompletionTimer?.cancel();

    // 비동기 작업을 안전하게 처리
    if (_isInterviewStarted) {
      // 면접 중이면 백그라운드에서 종료 처리
      endInterview().then((_) {
        print('🧹 dispose에서 면접 종료 완료');
      }).catchError((error) {
        print('❌ dispose에서 면접 종료 중 오류: $error');
      });
    }

    // 카메라 서비스 직접 해제 시도
    _cameraService?.dispose().catchError((error) {
      print('❌ dispose에서 카메라 해제 중 오류: $error');
    });

    super.dispose();
  }

  /// 서버 응답 이미지 설정
  void _setServerResponseImage(Uint8List? image) {
    _serverResponseImage = image;
    notifyListeners();
  }
}
