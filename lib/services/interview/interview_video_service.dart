import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../common/video_recording_service.dart';

/// 면접 비디오 관련 기능을 관리하는 서비스
/// 녹화, 업로드, 면접관 영상 재생 등을 처리합니다
class InterviewVideoService {
  // === 서비스 의존성 ===
  VideoRecordingService? _cameraService;

  // === 비디오 상태 ===
  bool _isUploadingVideo = false;
  bool _isInterviewerVideoPlaying = false;
  String _currentInterviewerVideoPath = '';
  final List<String> _videoUrls = [];

  // === 콜백 함수들 ===
  VoidCallback? _onStateChanged;
  VoidCallback? _onVideoCompleted;

  // === Getters ===
  VideoRecordingService? get cameraService => _cameraService;
  bool get isUploadingVideo => _isUploadingVideo;
  bool get isInterviewerVideoPlaying => _isInterviewerVideoPlaying;
  String get currentInterviewerVideoPath => _currentInterviewerVideoPath;
  List<String> get videoUrls => List.unmodifiable(_videoUrls);

  /// 상태 변경 콜백 설정
  void setStateChangedCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  /// 면접관 영상 완료 콜백 설정
  void setVideoCompletedCallback(VoidCallback callback) {
    _onVideoCompleted = callback;
  }

  /// 카메라 서비스 초기화
  Future<bool> initializeCameraService(
      VideoRecordingService cameraService) async {
    try {
      _cameraService = cameraService;
      await _cameraService!.initialize();
      return true;
    } catch (e) {
      print('카메라 서비스 초기화 실패: $e');
      return false;
    }
  }

  /// 카메라 준비 상태 확인
  bool isCameraReady() {
    if (_cameraService == null || !_cameraService!.isInitialized) {
      return false;
    }
    return true;
  }

  /// 카메라가 더미 모드인지 확인
  bool isUsingDummyCamera() {
    return _cameraService?.isUsingDummyCamera ?? false;
  }

  /// 현재 질문의 면접관 영상 재생
  Future<void> playInterviewerVideo(int questionIndex) async {
    try {
      final questionNumber = questionIndex + 1;
      _currentInterviewerVideoPath =
          'assets/videos/question_$questionNumber.mp4';
      _isInterviewerVideoPlaying = false;
      _notifyStateChanged();

      // 영상 로드 대기
      await Future.delayed(const Duration(seconds: 2));

      _isInterviewerVideoPlaying = true;
      _notifyStateChanged();
    } catch (e) {
      print('면접관 영상 재생 중 오류: $e');
    }
  }

  /// 면접관 영상 완료 처리
  void onInterviewerVideoCompleted() {
    _onVideoCompleted?.call();
  }

  /// 답변 녹화 시작
  Future<bool> startAnswerRecording() async {
    try {
      if (_cameraService != null && !_cameraService!.isRecording) {
        await _cameraService!.startVideoRecording();
        return true;
      }
      return false;
    } catch (e) {
      print('답변 녹화 시작 실패: $e');
      return false;
    }
  }

  /// 녹화 중지 및 영상 업로드
  Future<bool> stopRecordingAndUpload(String? reportId) async {
    if (_cameraService == null || !_cameraService!.isRecording) {
      return false;
    }

    try {
      _isUploadingVideo = true;
      _notifyStateChanged();

      // 녹화 중지 및 영상 파일 가져오기
      await _cameraService!.stopVideoRecording();
      final videoBytes = await _cameraService!.getRecordedVideoBytes();

      if (videoBytes != null) {
        await _uploadToFirebase(videoBytes, reportId);
        return true;
      }
      return false;
    } catch (e) {
      print('비디오 업로드 중 오류: $e');
      return false;
    } finally {
      _isUploadingVideo = false;
      _notifyStateChanged();
    }
  }

  /// Firebase Storage에 영상 업로드
  Future<void> _uploadToFirebase(Uint8List videoBytes, String? reportId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final interviewId =
        reportId ?? 'interview_${DateTime.now().millisecondsSinceEpoch}';
    final questionIndex = _videoUrls.length; // 현재 업로드할 질문 번호
    final fileName =
        'question_${questionIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    print('🔄 Firebase Storage 영상 업로드 시작 - 질문 ${questionIndex + 1}');

    try {
      // Firebase Storage 참조 생성
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('interview_videos')
          .child(currentUser.uid)
          .child(interviewId)
          .child(fileName);

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'userId': currentUser.uid,
          'interviewId': interviewId,
          'questionIndex': '${questionIndex + 1}',
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
    }
  }

  /// 어떤 녹화든 중지 (안전한 정리)
  Future<void> stopAnyRecording() async {
    if (_cameraService != null && _cameraService!.isRecording) {
      await _cameraService!.stopVideoRecording();
    }
  }

  /// 영상 상태 초기화
  void resetVideoState() {
    _isInterviewerVideoPlaying = false;
    _currentInterviewerVideoPath = '';
    _notifyStateChanged();
  }

  /// 상태 변경 알림
  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  /// 메모리 정리
  void dispose() {
    _cameraService?.dispose().catchError((error) {
      print('카메라 해제 중 오류: $error');
    });

    _onStateChanged = null;
    _onVideoCompleted = null;
  }
}
