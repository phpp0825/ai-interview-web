import 'dart:typed_data';
import 'dart:async';
import 'interfaces/media_service_interface.dart';
import 'interfaces/streaming_service_interface.dart';
import '../common/video_recording_service.dart';
import '../common/firebase_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 하이브리드 미디어 서비스 (실제 웹캠 + Firebase Storage)
/// 로컬 웹캠 기능은 실제로 사용하고, 녹화된 파일은 Firebase Storage에 저장합니다
class MediaService implements IMediaService {
  final IStreamingService _httpService;
  final VideoRecordingService _cameraService;
  final FirebaseStorageService _storageService;
  final Function(String) onError;
  final Function()? onStateChanged;

  bool _isVideoStreaming = false;
  bool _isAudioStreaming = false;
  bool _isVideoRecording = false;
  bool _isUploading = false;
  Uint8List? _lastVideoFrame;
  Uint8List? _lastAudioData;
  String? _recordedVideoPath;
  Uint8List? _recordedVideoData;

  // 현재 면접 세션 정보
  String? _currentInterviewId;
  String? _currentUserId;

  MediaService({
    required IStreamingService httpService,
    required VideoRecordingService cameraService,
    required this.onError,
    this.onStateChanged,
  })  : _httpService = httpService,
        _cameraService = cameraService,
        _storageService = FirebaseStorageService();

  @override
  Uint8List? get lastCapturedVideoFrame => _lastVideoFrame;

  @override
  Uint8List? get lastCapturedAudioData => _lastAudioData;

  /// 업로드 상태 getter
  bool get isUploading => _isUploading;
  bool get isVideoRecording => _isVideoRecording;
  String? get recordedVideoPath => _recordedVideoPath;
  Uint8List? get recordedVideoData => _recordedVideoData;

  @override
  Future<bool> connect(String serverUrl) async {
    print('목업: 미디어 서버 연결 - $serverUrl (실제 웹캠은 로컬 동작, Firebase Storage 연동)');
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  @override
  Future<void> disconnect() async {
    print('목업: 미디어 서버 연결 해제');
    stopVideoStreaming();
    stopAudioStreaming();
    await Future.delayed(Duration(milliseconds: 500));
  }

  @override
  void setVideoFrameCallback(Future<Uint8List?> Function() callback) {
    print('실제: 비디오 프레임 콜백 설정');
    // 실제 콜백 설정 (목업이 아님)
  }

  @override
  void setAudioDataCallback(Future<Uint8List?> Function() callback) {
    print('실제: 오디오 데이터 콜백 설정');
    // 실제 콜백 설정 (목업이 아님)
  }

  /// 면접 세션 시작 (면접 ID와 사용자 ID 설정)
  void startInterviewSession(String interviewId, String? userId) {
    _currentInterviewId = interviewId;
    _currentUserId =
        userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    print('🎬 면접 세션 시작: $_currentInterviewId (사용자: $_currentUserId)');
  }

  @override
  Future<bool> startVideoStreaming() async {
    print('하이브리드: 비디오 스트리밍 시작 (로컬 웹캠 + Firebase Storage)');
    await Future.delayed(Duration(milliseconds: 300));
    _isVideoStreaming = true;
    onStateChanged?.call();
    return true;
  }

  @override
  void stopVideoStreaming() {
    print('하이브리드: 비디오 스트리밍 중지');
    _isVideoStreaming = false;
    onStateChanged?.call();
  }

  @override
  Future<bool> startAudioStreaming() async {
    print('하이브리드: 오디오 스트리밍 시작 (로컬 마이크 + Firebase Storage)');
    await Future.delayed(Duration(milliseconds: 300));
    _isAudioStreaming = true;
    onStateChanged?.call();
    return true;
  }

  @override
  void stopAudioStreaming() {
    print('하이브리드: 오디오 스트리밍 중지');
    _isAudioStreaming = false;
    onStateChanged?.call();
  }

  /// 실제 웹캠을 사용한 비디오 녹화 시작
  @override
  Future<bool> startVideoRecording() async {
    if (_isVideoRecording) {
      return true;
    }

    try {
      print('🎥 실제 웹캠 비디오 녹화 시작');
      final success = await _cameraService.startVideoRecording();
      _isVideoRecording = success;
      onStateChanged?.call();

      if (success) {
        print('✅ 웹캠 녹화 시작 성공!');
      } else {
        print('❌ 웹캠 녹화 시작 실패');
        onError('웹캠을 시작할 수 없습니다. 카메라 권한을 확인해주세요.');
      }

      return success;
    } catch (e) {
      print('웹캠 녹화 시작 중 오류: $e');
      onError('비디오 녹화 시작 중 오류 발생: $e');
      return false;
    }
  }

  /// 실제 웹캠 비디오 녹화 중지 및 Firebase Storage 업로드
  @override
  Future<String?> stopVideoRecording() async {
    if (!_isVideoRecording) {
      return null;
    }

    try {
      print('🎥 실제 웹캠 비디오 녹화 중지');
      final videoPath = await _cameraService.stopVideoRecording();
      _isVideoRecording = false;
      _recordedVideoPath = videoPath;
      onStateChanged?.call();

      if (videoPath != null) {
        print('✅ 웹캠 녹화 중지 성공! 로컬 파일: $videoPath');

        // 비디오 파일을 바이트 데이터로 읽기
        final videoData = await _cameraService.getRecordedVideoBytes();
        if (videoData != null) {
          _recordedVideoData = videoData;
          print(
              '📦 비디오 데이터 준비 완료: ${(videoData.length / 1024 / 1024).toStringAsFixed(2)} MB');

          // Firebase Storage에 업로드 (백그라운드)
          _uploadToFirebaseStorage(videoData);
        }
      } else {
        print('❌ 웹캠 녹화 중지 실패');
      }

      return videoPath;
    } catch (e) {
      print('웹캠 녹화 중지 중 오류: $e');
      onError('비디오 녹화 중지 중 오류 발생: $e');
      _isVideoRecording = false;
      return null;
    }
  }

  /// Firebase Storage에 비디오 업로드 (백그라운드)
  Future<void> _uploadToFirebaseStorage(Uint8List videoData) async {
    if (_currentInterviewId == null || _currentUserId == null) {
      print('❌ 면접 세션 정보가 없어 업로드할 수 없습니다');
      return;
    }

    try {
      _isUploading = true;
      onStateChanged?.call();
      print('🔥 Firebase Storage 업로드 시작...');

      final String? downloadUrl = await _storageService.uploadInterviewVideo(
        videoData: videoData,
        userId: _currentUserId!,
        interviewId: _currentInterviewId!,
      );

      if (downloadUrl != null) {
        print('🎉 Firebase Storage 업로드 성공!');
        print('🔗 보고서에서 사용할 URL: $downloadUrl');

        // TODO: 보고서 서비스에 URL 전달
        await _saveVideoUrlToReport(downloadUrl);
      } else {
        print('❌ Firebase Storage 업로드 실패');
        onError('비디오 업로드에 실패했습니다.');
      }
    } catch (e) {
      print('💥 Firebase Storage 업로드 오류: $e');
      onError('비디오 업로드 중 오류가 발생했습니다: $e');
    } finally {
      _isUploading = false;
      onStateChanged?.call();
    }
  }

  /// 보고서에 비디오 URL 저장
  Future<void> _saveVideoUrlToReport(String downloadUrl) async {
    try {
      // TODO: Firestore에 보고서 데이터 저장
      print('📊 보고서에 비디오 URL 저장: $downloadUrl');

      // 예시: Firestore에 저장하는 코드
      /*
      await FirebaseFirestore.instance
          .collection('interview_reports')
          .doc(_currentInterviewId)
          .update({
        'videoUrl': downloadUrl,
        'uploadTime': FieldValue.serverTimestamp(),
        'status': 'video_uploaded',
      });
      */
    } catch (e) {
      print('💥 보고서 업데이트 오류: $e');
    }
  }

  /// 면접 전체 세션 업로드 (비디오 + 메타데이터)
  Future<Map<String, String?>> uploadInterviewSession({
    required Map<String, dynamic> metadata,
  }) async {
    if (_recordedVideoData == null ||
        _currentInterviewId == null ||
        _currentUserId == null) {
      print('❌ 업로드할 데이터가 없습니다');
      return {'status': 'failed', 'error': 'No data to upload'};
    }

    print('🚀 면접 세션 전체 업로드 시작');

    return await _storageService.uploadInterviewSession(
      videoData: _recordedVideoData!,
      audioData: _lastAudioData,
      userId: _currentUserId!,
      interviewId: _currentInterviewId!,
      metadata: metadata,
    );
  }

  /// 목업: 서버로 비디오 프레임 전송 (실제로는 전송하지 않음)
  @override
  Future<dynamic> sendVideoFrame() async {
    print('목업: 비디오 프레임 서버 전송 (실제 전송 안함)');
    return {'status': 'success', 'frame_size': 1024};
  }

  /// 목업: 서버로 오디오 데이터 전송 (실제로는 전송하지 않음)
  @override
  Future<dynamic> sendAudioData() async {
    print('목업: 오디오 데이터 서버 전송 (실제 전송 안함)');
    return {'status': 'success', 'audio_size': 512};
  }

  @override
  void dispose() {
    print('리소스 해제: 웹캠 정리 + Firebase Storage 정리');

    // 실제 웹캠 리소스 해제
    if (_isVideoRecording) {
      stopVideoRecording();
    }

    // 스트리밍 중지
    stopVideoStreaming();
    stopAudioStreaming();

    // 카메라 서비스 해제
    _cameraService.dispose();
  }
}
