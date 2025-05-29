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
      _isInterviewStarted = true;
      _interviewStartTime = DateTime.now();
      _currentQuestionIndex = 0; // 첫 번째 영상부터 시작
      _playInterviewerVideo();
      notifyListeners();
      print('🎬 면접이 시작되었습니다!');
      return true;
    } catch (e) {
      _setErrorMessage('면접 시작 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접관 영상 재생 (비디오+음성 녹화 시작)
  Future<void> _playInterviewerVideo() async {
    try {
      // 현재 질문에 해당하는 면접관 영상 경로 설정
      _currentInterviewerVideoPath =
          'assets/videos/interviewer/question_${_currentQuestionIndex + 1}.mp4';
      _isInterviewerVideoPlaying = true;
      notifyListeners();

      print('🎬 면접관 영상 재생 시작: $_currentInterviewerVideoPath');

      // 비디오 녹화 시작 (음성도 함께 녹화됨!)
      if (_cameraService != null) {
        final recordingStarted = await _cameraService!.startVideoRecording();
        if (recordingStarted) {
          print('📹🎤 지원자 비디오+음성 녹화 시작 성공');
        } else {
          print('❌ 지원자 비디오+음성 녹화 시작 실패');
        }
      }

      // 별도 오디오 녹음 제거 (비디오에 음성이 포함되므로 불필요)
      // 초보 개발자를 위한 설명: 비디오 녹화할 때 음성도 자동으로 녹화돼요!
    } catch (e) {
      print('면접관 영상 재생 중 오류: $e');
      _setErrorMessage('면접관 영상 재생 중 오류가 발생했습니다: $e');
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
    const totalVideos = 8; // 총 영상 개수

    try {
      // 현재 녹화 중인 비디오 중지 및 업로드
      await _stopAndUploadCurrentVideo();

      if (_currentQuestionIndex < totalVideos - 1) {
        _currentQuestionIndex++;
        await _playInterviewerVideo();
      } else {
        // 모든 영상 완료 - 면접 종료
        _isInterviewStarted = false;
        await _generateFinalReport();
      }
      notifyListeners();
    } catch (e) {
      print('다음 영상으로 이동 중 오류: $e');
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
      _isUploadingVideo = true;
      notifyListeners();

      print('📹 현재 비디오 녹화 중지 중...');
      final videoPath = await _cameraService!.stopVideoRecording();

      if (videoPath != null) {
        print('✅ 비디오 녹화 중지 완료: $videoPath');

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
      print('면접을 종료하고 결과를 저장하고 있습니다...');

      // 별도 오디오 중지 제거 (비디오에 음성이 포함되므로 불필요)
      // 초보 개발자를 위한 설명: 비디오 녹화만 중지하면 음성도 함께 중지돼요!

      print('면접 종료 완료!');
      return true;
    } catch (e) {
      print('면접 종료 중 오류 발생: $e');
      return false;
    }
  }

  /// 면접 전체 중지 (실제 비디오 업로드 포함)
  Future<void> stopFullInterview() async {
    try {
      print('🏁 면접을 종료하고 마지막 비디오+음성을 업로드하고 있습니다...');

      // 마지막 녹화 중인 비디오 중지 및 업로드 (음성 포함)
      await _stopAndUploadCurrentVideo();

      // 별도 오디오 녹음 중지 제거 (비디오에 음성이 포함되므로 불필요)

      // 리포트 생성
      if (_selectedResume != null) {
        await _generateFinalReport();
      }

      _isInterviewStarted = false;
      print('🏁 면접 전체 중지 완료');

      notifyListeners();
    } catch (e) {
      print('면접 중지 중 오류: $e');
      _setErrorMessage('면접 중지 중 오류가 발생했습니다: $e');
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
      endInterview();
    }

    _cameraService?.dispose();
    super.dispose();
  }

  /// 서버 응답 이미지 설정
  void _setServerResponseImage(Uint8List? image) {
    _serverResponseImage = image;
    notifyListeners();
  }
}
