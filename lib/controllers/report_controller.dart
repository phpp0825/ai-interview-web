import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  // 의존성
  final ReportService _reportService = ReportService();

  // 상태 변수
  ReportModel? _reportData;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;

  // Getters
  ReportModel? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  bool get isVideoInitialized => _isVideoInitialized;

  // 리포트 데이터 로드
  Future<void> loadReport(String reportId) async {
    try {
      _setLoading(true);
      _setError(null);

      // 서비스를 통해 데이터 로드
      final report = await _reportService.getReport(reportId);
      _reportData = report;

      // 비디오 플레이어 초기화
      await _initializeVideoPlayer();

      _setLoading(false);
    } catch (e) {
      _setError('리포트를 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
  }

  // 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer() async {
    if (_reportData?.videoUrl == null) return;

    try {
      _videoPlayerController =
          VideoPlayerController.network(_reportData!.videoUrl);
      await _videoPlayerController!.initialize();
      _isVideoInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('비디오를 불러오는데 실패했습니다: $e');
    }
  }

  // 특정 시간으로 이동
  void seekToTime(int seconds) {
    if (_videoPlayerController == null) return;
    _videoPlayerController!.seekTo(Duration(seconds: seconds));
  }

  // 시간 포맷팅 유틸리티 함수
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 로딩 상태 변경
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
