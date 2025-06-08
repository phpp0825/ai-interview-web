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

/// 면접 전체 과정을 관리하는 컨트롤러
/// 면접의 시작부터 끝까지 모든 단계를 처리합니다
class InterviewController extends ChangeNotifier {
  // === 서비스들 ===
  VideoRecordingService? _cameraService;
  IResumeService? _resumeService;
  final _reportRepository = FirebaseReportRepository();

  final _submissionService = InterviewSubmissionService();

  // === 기본 상태 ===
  bool _isLoading = true;
  bool _isInterviewStarted = false;
  bool _isUploadingVideo = false;
  bool _isAnalyzingVideo = false; // AI 분석 상태 추가

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
  bool get isAnalyzingVideo => _isAnalyzingVideo; // AI 분석 상태 getter

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
    try {
      // 현재 답변 영상 업로드
      await _stopAndUploadVideo();

      // 바로 다음 질문으로 진행
      await _proceedToNextQuestion();
    } catch (e) {
      _updateState(error: '면접 진행 중 오류가 발생했습니다: $e');
    }
  }

  // === 실제 다음 질문으로 진행 (피드백 확인 후) ===
  Future<void> _proceedToNextQuestion() async {
    const totalQuestions = 3;

    try {
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
      _updateState(error: '다음 질문으로 진행 중 오류가 발생했습니다: $e');
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

  // === Firebase Storage에 영상 업로드 ===
  Future<void> _uploadToFirebase(Uint8List videoBytes) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final interviewId = _generatedReportId ??
        'interview_${DateTime.now().millisecondsSinceEpoch}';
    final fileName =
        'question_${_currentQuestionIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    print('🔄 Firebase Storage 영상 업로드 시작 - 질문 ${_currentQuestionIndex + 1}');

    try {
      // Firebase Storage 참조 생성
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('interview_videos')
          .child(currentUser.uid)
          .child(interviewId)
          .child(fileName);

      // 메타데이터 설정 (중요!)
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'userId': currentUser.uid,
          'interviewId': interviewId,
          'questionIndex': '${_currentQuestionIndex + 1}',
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      print('📤 Firebase Storage 업로드 진행 중...');
      final uploadTask = storageRef.putData(videoBytes, metadata);

      // 업로드 진행상황 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📊 업로드 진행률: ${progress.toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _videoUrls.add(downloadUrl);
      print('✅ Firebase Storage 업로드 성공: $downloadUrl');
    } catch (e) {
      print('❌ Firebase Storage 업로드 실패: $e');
      print('   - 네트워크 연결을 확인해주세요');
      print('   - Firebase Storage 권한을 확인해주세요');
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

    // 리포트 생성
    await _generateReport();

    // === 모든 영상을 서버로 분석 요청 ===
    print('🎯 면접 완료! 모든 영상을 서버로 분석 요청합니다...');
    await _getServerFeedback();

    // AI 분석 완료 후 영상 상태 정리
    _resetVideoState();
  }

  // === 면접 강제 종료 (사용자가 중간에 종료) ===
  Future<bool> endInterview() async {
    try {
      // 현재 녹화 중인 것 정리 및 업로드
      await _stopAndUploadVideo();

      // 면접 상태 정리 (영상 프레임은 AI 분석 중에 유지)
      _isInterviewStarted = false;
      _cleanupTimers();

      // 리포트 생성 (영상이 있으면)
      if (_selectedResume != null && _videoUrls.isNotEmpty) {
        await _generateReport();

        // === 모든 영상을 서버로 분석 요청 ===
        print('🎯 면접 중단! 업로드된 모든 영상을 서버로 분석 요청합니다...');
        await _getServerFeedback();
      }

      // AI 분석 완료 후 영상 상태 정리
      _resetVideoState();
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

  // === 안전한 문자열 자르기 (길이 초과 방지 + UTF-8 정리) ===
  String _safeSubstring(String text, int maxLength) {
    try {
      // UTF-8 문제가 있는 문자들 제거
      final cleanText = _cleanUtf8String(text);

      if (cleanText.length <= maxLength) {
        return cleanText;
      }
      return cleanText.substring(0, maxLength);
    } catch (e) {
      print('⚠️ 문자열 처리 중 오류: $e');
      return '문자 인코딩 오류';
    }
  }

  // === UTF-8 문자열 정리 (잘못된 문자 제거) ===
  String _cleanUtf8String(String input) {
    try {
      // 1. Replacement character (�) 제거
      String cleaned = input.replaceAll('�', '');

      // 2. 제어 문자 제거 (탭, 개행 제외)
      cleaned =
          cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

      // 3. 다양한 점 문자들을 공백으로 변경
      cleaned = cleaned.replaceAll(RegExp(r'[·․‧∙•]'), ' ');

      // 4. 연속된 공백 정리
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

      // 5. 기본적인 특수문자만 유지 (한글, 영어, 숫자, 기본 문장부호)
      cleaned = cleaned.replaceAll(
          RegExp(r'[^\w\sㄱ-ㅎㅏ-ㅣ가-힣.,!?():;"\' '-]', unicode: true), ' ');

      // 6. 최종 공백 정리
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      return cleaned.isEmpty ? '인식할 수 없는 텍스트' : cleaned;
    } catch (e) {
      print('⚠️ UTF-8 정리 중 오류: $e');
      return '텍스트 정리 오류';
    }
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

  // === 서버 피드백 받기 (면접 종료 시 모든 영상을 한번에 분석) ===
  Future<void> _getServerFeedback() async {
    try {
      print('🤖 면접 종료 - 모든 영상을 서버로 분석 요청 시작...');

      // AI 분석 상태 시작
      _isAnalyzingVideo = true;
      notifyListeners();

      if (_videoUrls.isEmpty) {
        print('⚠️ 업로드된 영상이 없어서 피드백을 건너뜁니다.');
        return;
      }

      // === 서버 연결 테스트 ===
      print('🔌 서버 연결 상태 확인 중...');
      final isServerAvailable = await _submissionService.testServerConnection();
      if (!isServerAvailable) {
        print('⚠️ 서버에 연결할 수 없어서 피드백을 건너뜁니다.');
        print('💡 서버를 실행하고 다시 시도해주세요.');
        return;
      }
      print('✅ 서버 연결 확인됨');

      // === 면접 질문 목록 준비 ===
      final questions = _getInterviewQuestions();
      if (questions.isEmpty) {
        print('⚠️ 질문 목록이 없어서 피드백을 건너뜁니다.');
        return;
      }

      print('📋 준비된 질문 개수: ${questions.length}개');
      print('🎬 업로드된 영상 개수: ${_videoUrls.length}개');
      print('📤 모든 영상 URL을 서버로 전송합니다...');

      // === 모든 영상을 바이트 데이터로 서버 전송 ===
      for (int i = 0; i < _videoUrls.length && i < questions.length; i++) {
        final videoPath = _videoUrls[i];
        final question = questions[i];

        print('📹 영상 ${i + 1} 분석 시작: 질문 "${_safeSubstring(question, 30)}..."');

        try {
          // Firebase Storage URL인지 확인
          if (videoPath.startsWith('https://firebasestorage.googleapis.com/')) {
            print('🔗 Firebase Storage URL을 서버에 직접 전달합니다...');

            // URL을 서버에 직접 전달하여 분석 요청
            final analysisResult =
                await _submissionService.getCompleteAnalysisFromUrl(
              videoUrl: videoPath,
              questions: [question], // 각 영상별로 해당 질문만 분석
            );

            if (analysisResult.success) {
              print('✅ 영상 ${i + 1} URL 분석 성공!');

              // 서버 응답에서 STT 결과 추출
              final extractedAnswer =
                  _extractAnswerFromEvaluation(analysisResult.evaluationResult);

              // 각 질문별 피드백을 Firestore에 저장
              await _saveQuestionFeedbackToFirestore(
                questionIndex: i,
                question: question,
                answer: extractedAnswer,
                poseAnalysis: analysisResult.poseAnalysis,
                evaluationResult: analysisResult.evaluationResult,
              );

              print('💾 질문 ${i + 1} 피드백이 Firestore에 저장되었습니다.');
            } else {
              print('❌ 영상 ${i + 1} URL 분석 실패:');
              print('  - 포즈 오류: ${analysisResult.poseError}');
              print('  - 평가 오류: ${analysisResult.evaluationError}');
            }
            continue; // URL 방식으로 처리했으므로 바이트 로드 건너뛰기
          }

          // 다른 형식의 URL이면 바이트 다운로드 시도
          final videoBytes = await _loadVideoBytes(videoPath);

          if (videoBytes == null) {
            print('❌ 영상 ${i + 1} 바이트 로드 실패: $videoPath');
            print('💡 서버에 URL을 직접 전달하는 방식을 권장합니다.');
            continue;
          }

          print(
              '✅ 영상 ${i + 1} 바이트 로드 성공: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');

          // 바이트 데이터로 서버 분석 요청
          final analysisResult = await _submissionService.getCompleteAnalysis(
            videoData: videoBytes,
            questions: [question], // 각 영상별로 해당 질문만 분석
          );

          if (analysisResult.success) {
            print('✅ 영상 ${i + 1} 분석 성공!');

            // 서버 응답에서 STT 결과 추출
            final extractedAnswer =
                _extractAnswerFromEvaluation(analysisResult.evaluationResult);

            // 각 질문별 피드백을 Firestore에 저장 (영상 URL 제외)
            await _saveQuestionFeedbackToFirestore(
              questionIndex: i,
              question: question,
              answer: extractedAnswer,
              poseAnalysis: analysisResult.poseAnalysis,
              evaluationResult: analysisResult.evaluationResult,
            );

            print('💾 질문 ${i + 1} 피드백이 Firestore에 저장되었습니다.');
          } else {
            print('❌ 영상 ${i + 1} 분석 실패:');
            print('  - 포즈 오류: ${analysisResult.poseError}');
            print('  - 평가 오류: ${analysisResult.evaluationError}');
          }
        } catch (e) {
          print('❌ 영상 ${i + 1} 처리 중 오류: $e');
        }

        // 다음 영상 처리 전 잠시 대기 (서버 부하 방지)
        if (i < _videoUrls.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      print('🎉 모든 영상 분석 완료!');
    } catch (e) {
      print('❌ 서버 피드백 요청 중 오류: $e');
      print('💡 이는 정상적인 상황입니다. 리포트는 저장되었고 나중에 분석을 다시 시도할 수 있습니다.');
    } finally {
      // AI 분석 상태 종료
      _isAnalyzingVideo = false;
      notifyListeners();
    }
  }

  // === Firebase Storage 영상을 바이트 데이터로 로드 ===
  Future<Uint8List?> _loadVideoBytes(String videoUrl) async {
    try {
      print(
          '📥 Firebase Storage 영상 바이트 로드 시작: ${_safeSubstring(videoUrl, 100)}...');

      // Firebase Storage URL인지 확인
      if (videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        return await _downloadVideoFromFirebase(videoUrl);
      }

      // 다른 형식의 URL은 지원하지 않음
      print('⚠️ 지원하지 않는 URL 형식입니다: ${_safeSubstring(videoUrl, 50)}...');
      return null;
    } catch (e) {
      print('❌ Firebase Storage 영상 바이트 로드 중 오류: $e');
      return null;
    }
  }

  // === Firebase에서 영상 다운로드 ===
  Future<Uint8List?> _downloadVideoFromFirebase(String videoUrl) async {
    try {
      print('📥 Firebase Storage에서 영상 다운로드 시작...');
      print('🔗 URL: ${_safeSubstring(videoUrl, 100)}...');

      // Firebase Storage SDK를 사용한 안전한 다운로드
      final ref = FirebaseStorage.instance.refFromURL(videoUrl);

      // 파일 메타데이터 확인
      final metadata = await ref.getMetadata();
      final fileSize = metadata.size ?? 0;
      print('📦 파일 크기: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // 웹 환경에서 안전한 다운로드
      final videoBytes = await ref.getData();

      if (videoBytes != null) {
        print(
            '✅ Firebase Storage 다운로드 성공: ${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
        return videoBytes;
      } else {
        print('❌ Firebase Storage에서 null 데이터 반환');
        return null;
      }
    } catch (e) {
      print('❌ Firebase Storage 다운로드 중 오류: $e');

      // 대안: HTTP를 통한 다운로드 시도 (CORS 문제가 있을 수 있음)
      try {
        print('🔄 HTTP를 통한 대안 다운로드 시도...');
        final uri = Uri.parse(videoUrl);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          print(
              '✅ HTTP 다운로드 성공: ${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(2)} MB');
          return response.bodyBytes;
        } else {
          print('❌ HTTP 다운로드 실패: ${response.statusCode}');
          return null;
        }
      } catch (httpError) {
        print('❌ HTTP 다운로드도 실패: $httpError');

        // 최종 대안: null 반환하여 URL 전달 방식 사용
        print('💡 대안: 서버에 URL을 직접 전달하도록 시도합니다.');
        return null; // null 반환하여 URL 전달 방식 사용
      }
    }
  }

  // === 면접 질문 목록 가져오기 ===
  List<String> _getInterviewQuestions() {
    // 실제 면접 질문들
    return [
      "먼저 간단한 자기소개와 우리 회사에 지원하게 된 구체적인 동기를 말씀해주세요.",
      "팀 프로젝트에서 협업하는 것을 중요하게 생각하시나요? 팀 내에서 자신의 역할을 어떻게 생각하며, 팀워크를 향상시키기 위해 어떤 노력을 할 수 있을까요?",
      "새로운 기술을 배우는 것을 즐기시는 편인가요? 최근에 학습한 기술이나 도구가 있다면, 그것이 귀하의 업무에 어떻게 적용될 수 있을지 설명해주실 수 있나요?",
    ];
  }

  // === 피드백 결과를 Firestore에 저장 ===
  Future<void> _saveFeedbackToFirestore(
      CompleteAnalysisResult analysisResult) async {
    try {
      if (_generatedReportId == null) {
        print('⚠️ 리포트 ID가 없어서 피드백 저장을 건너뜁니다.');
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ 로그인된 사용자가 없어서 피드백 저장을 건너뜁니다.');
        return;
      }

      // === Firestore에 피드백 저장 ===
      await _reportRepository.updateInterviewFeedback(
        reportId: _generatedReportId!,
        userId: currentUser.uid,
        poseAnalysis: analysisResult.poseAnalysis,
        evaluationResult: analysisResult.evaluationResult,
      );

      print('✅ 피드백이 Firestore에 저장되었습니다.');
    } catch (e) {
      print('❌ 피드백 저장 중 오류: $e');
    }
  }

  // === 각 질문별 피드백을 Firestore에 저장 (로컬 저장 전용) ===
  Future<void> _saveQuestionFeedbackToFirestore({
    required int questionIndex,
    required String question,
    String? answer,
    String? poseAnalysis,
    String? evaluationResult,
  }) async {
    try {
      if (_generatedReportId == null) {
        print('⚠️ 리포트 ID가 없어서 질문별 피드백 저장을 건너뜁니다.');
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ 로그인된 사용자가 없어서 질문별 피드백 저장을 건너뜁니다.');
        return;
      }

      // === Firebase Storage URL 확인 ===
      // questionIndex가 유효한 범위 내에 있고 해당 영상이 업로드되었는지 확인
      String videoUrl = '';
      bool hasVideo = false;

      if (questionIndex >= 0 && questionIndex < _videoUrls.length) {
        final firebaseUrl = _videoUrls[questionIndex];
        if (firebaseUrl.isNotEmpty) {
          videoUrl = firebaseUrl; // Firebase Storage URL 저장
          hasVideo = true;
          print('✅ 질문 ${questionIndex + 1}번 Firebase 영상 URL 확인됨: $videoUrl');
        }
      }

      // === Firestore에 질문별 피드백 저장 ===
      await _reportRepository.updateQuestionFeedback(
        reportId: _generatedReportId!,
        userId: currentUser.uid,
        questionIndex: questionIndex,
        question: question,
        videoUrl: videoUrl, // Firebase Storage URL 저장 (빈 문자열이면 영상 없음)
        answer: answer,
        poseAnalysis: poseAnalysis,
        evaluationResult: evaluationResult,
      );

      print(
          '✅ 질문 ${questionIndex + 1} 피드백이 Firestore에 저장되었습니다 (Firebase 영상: $hasVideo).');
    } catch (e) {
      print('❌ 질문별 피드백 저장 중 오류: $e');
    }
  }

  // === 평가 결과에서 STT 답변 추출 ===
  String? _extractAnswerFromEvaluation(String? evaluationResult) {
    if (evaluationResult == null || evaluationResult.isEmpty) {
      return null;
    }

    try {
      // 평가 결과에서 "사용자 답변:" 패턴으로 STT 결과 찾기
      final patterns = [
        RegExp(r'사용자 답변:\s*(.+?)(?=\n\n|\n평가 결과:|\n추천 답변:|\n답변 시간:|$)',
            dotAll: true),
        RegExp(
            r'User Answer:\s*(.+?)(?=\n\n|\nEvaluation:|\nRecommended Answer:|\nTotal Response Time:|$)',
            dotAll: true),
        RegExp(r'답변:\s*(.+?)(?=\n\n|\n점수:|\n평가:|\n피드백:|$)', dotAll: true),
        RegExp(r'응답:\s*(.+?)(?=\n\n|\n점수:|\n평가:|\n피드백:|$)', dotAll: true),
        RegExp(r'STT 결과:\s*(.+?)(?=\n\n|\n점수:|\n평가:|\n피드백:|$)', dotAll: true),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(evaluationResult);
        if (match != null && match.group(1) != null) {
          String answer = _cleanUtf8String(match.group(1)!.trim());

          // 중복 텍스트 제거
          answer = _removeDuplicateText(answer);

          if (answer.isNotEmpty &&
              answer != '음성을 인식할 수 없습니다.' &&
              answer != '인식할 수 없는 텍스트') {
            print('✅ STT 결과 추출됨: ${_safeSubstring(answer, 50)}...');
            return answer;
          }
        }
      }

      // 패턴으로 찾지 못한 경우, 전체 텍스트에서 첫 번째 문단 추출
      final lines = evaluationResult.split('\n');
      for (final line in lines) {
        final trimmed = _cleanUtf8String(line.trim());
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('질문:') &&
            !trimmed.startsWith('점수:') &&
            !trimmed.startsWith('평가:') &&
            !trimmed.startsWith('피드백:') &&
            !trimmed.startsWith('총점:') &&
            trimmed.length > 10 &&
            trimmed != '인식할 수 없는 텍스트') {
          print('📝 대안 답변 추출됨: ${_safeSubstring(trimmed, 50)}...');
          return trimmed;
        }
      }

      print('⚠️ STT 결과를 찾을 수 없습니다.');
      return null;
    } catch (e) {
      print('❌ STT 결과 추출 중 오류: $e');
      return null;
    }
  }

  // === 중복 텍스트 제거 메소드 ===
  String _removeDuplicateText(String input) {
    if (input.isEmpty) return input;

    try {
      // 1. 연속된 같은 문장 제거
      String result = input;

      // 문장 단위로 분리 (마침표, 느낌표, 물음표 기준)
      final sentences = result.split(RegExp(r'[.!?]\s*'));
      final uniqueSentences = <String>[];
      final seenSentences = <String>{};

      for (String sentence in sentences) {
        final trimmed = sentence.trim();
        if (trimmed.isNotEmpty && !seenSentences.contains(trimmed)) {
          uniqueSentences.add(trimmed);
          seenSentences.add(trimmed);
        }
      }

      result = uniqueSentences.join('. ');

      // 2. 연속된 같은 단어 제거 (3번 이상 반복되는 경우)
      final words = result.split(RegExp(r'\s+'));
      final filteredWords = <String>[];
      String? lastWord;
      int consecutiveCount = 0;

      for (String word in words) {
        final cleanWord = word.trim();
        if (cleanWord.isEmpty) continue;

        if (lastWord == cleanWord) {
          consecutiveCount++;
          // 같은 단어가 2번까지는 허용, 3번째부터는 제거
          if (consecutiveCount <= 2) {
            filteredWords.add(cleanWord);
          }
        } else {
          filteredWords.add(cleanWord);
          lastWord = cleanWord;
          consecutiveCount = 1;
        }
      }

      result = filteredWords.join(' ');

      // 3. 전체 텍스트가 반복되는 경우 처리
      if (result.length > 100) {
        // 앞의 50%와 뒤의 50%가 같은지 확인
        final halfLength = result.length ~/ 2;
        final firstHalf = result.substring(0, halfLength);
        final secondHalf = result.substring(halfLength);

        if (firstHalf == secondHalf) {
          print('🔄 중복된 텍스트 절반 제거');
          result = firstHalf;
        }

        // 1/3씩 나누어서 반복되는지 확인
        final thirdLength = result.length ~/ 3;
        if (thirdLength > 10) {
          final firstThird = result.substring(0, thirdLength);
          final secondThird = result.substring(thirdLength, thirdLength * 2);
          final thirdThird = result.substring(thirdLength * 2);

          if (firstThird == secondThird && secondThird == thirdThird) {
            print('🔄 중복된 텍스트 2/3 제거');
            result = firstThird;
          }
        }
      }

      // 4. 특정 반복 패턴 제거 ("테스트입니다" 같은 패턴)
      result = _removeSpecificRepeatedPatterns(result);

      print('🧹 중복 텍스트 정리 완료: ${_safeSubstring(result, 100)}...');
      return result.trim();
    } catch (e) {
      print('⚠️ 중복 텍스트 제거 중 오류: $e');
      return input; // 오류 시 원본 반환
    }
  }

  // === 특정 반복 패턴 제거 ===
  String _removeSpecificRepeatedPatterns(String input) {
    try {
      String result = input;

      // "테스트입니다", "입니다", "합니다" 등의 반복 제거
      final patterns = [
        RegExp(r'(\b테스트입니다\b\s*){2,}'),
        RegExp(r'(\b입니다\b\s*){3,}'),
        RegExp(r'(\b합니다\b\s*){3,}'),
        RegExp(r'(\b네\b\s*){4,}'),
        RegExp(r'(\b예\b\s*){4,}'),
        RegExp(r'(\b그렇습니다\b\s*){2,}'),
      ];

      for (final pattern in patterns) {
        result = result.replaceAllMapped(pattern, (match) {
          // 반복된 패턴을 한 번만 남기기
          final text = match.group(0) ?? '';
          final parts = text.split(RegExp(r'\s+'));
          return parts.isNotEmpty ? '${parts.first} ' : '';
        });
      }

      return result;
    } catch (e) {
      print('⚠️ 특정 패턴 제거 중 오류: $e');
      return input;
    }
  }
}
