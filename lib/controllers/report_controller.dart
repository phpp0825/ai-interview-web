import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../services/report/interfaces/report_service_interface.dart';
import '../core/di/service_locator.dart';
import 'package:video_player/video_player.dart';

/// 간단한 리포트 컨트롤러
/// 리포트 목록과 기본 데이터만 관리합니다.
class ReportController extends ChangeNotifier {
  // 의존성
  final IReportService _reportService;

  // 상태 변수
  ReportModel? _reportData;
  bool _isLoading = true;
  String? _error;
  bool _isLoadingReports = false;
  List<Map<String, dynamic>> _reportList = [];
  bool _isCreatingReport = false;
  bool _isVideoInitialized = false;
  VideoPlayerController? _videoPlayerController;
  int _selectedQuestionIndex = 0; // 현재 선택된 질문 인덱스
  String _currentVideoUrl = ''; // 현재 재생 중인 비디오 URL

  // Getters
  ReportModel? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingReports => _isLoadingReports;
  List<Map<String, dynamic>> get reportList => _reportList;
  bool get isCreatingReport => _isCreatingReport;
  bool get isVideoInitialized => _isVideoInitialized;
  dynamic get videoPlayerController => _videoPlayerController;
  int get selectedQuestionIndex => _selectedQuestionIndex;
  String get currentVideoUrl => _currentVideoUrl;

  // 비디오 관련 getter들 (목업)
  dynamic seekToTime(int time) {
    if (_isVideoInitialized && _videoPlayerController != null) {
      _videoPlayerController!.seekTo(Duration(seconds: time));
      print('비디오를 ${time}초로 이동했습니다');
    } else {
      print('비디오 컨트롤러가 초기화되지 않아 ${time}초로 이동할 수 없습니다');
    }
  }

  dynamic formatDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(secs)}";
  }

  /// 생성자
  ReportController() : _reportService = serviceLocator<IReportService>() {
    loadReportList();
  }

  // 리포트 목록 로드
  Future<void> loadReportList() async {
    try {
      _isLoadingReports = true;
      _error = null;
      notifyListeners();

      _reportList = await _reportService.getCurrentUserReportList();

      _isLoadingReports = false;
      notifyListeners();
    } catch (e) {
      _error = '리포트 목록을 불러오는데 실패했습니다: $e';
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  /// 리포트 데이터 로드
  Future<void> loadReport(String reportId) async {
    try {
      _setLoading(true);
      print('📋 리포트 로드 시작: $reportId');

      _reportData = await _reportService.getReport(reportId);
      print('📋 리포트 데이터 로드 완료');

      if (_reportData != null) {
        print('📹 비디오 URL: ${_reportData!.videoUrl}');
        print('📅 리포트 제목: ${_reportData!.title}');
        print('📊 리포트 점수: ${_reportData!.score}');
        print('🔗 비디오 URL 길이: ${_reportData!.videoUrl.length}');
        print(
            '🔗 비디오 URL 첫 50자: ${_reportData!.videoUrl.length > 50 ? _reportData!.videoUrl.substring(0, 50) : _reportData!.videoUrl}');

        // 질문-답변 데이터가 있으면 영상이 있는 첫 번째 질문의 비디오 로드
        if (_reportData!.questionAnswers != null &&
            _reportData!.questionAnswers!.isNotEmpty) {
          // 영상이 있는 첫 번째 질문 찾기
          final questionsWithVideo = _reportData!.questionAnswers!
              .where((qa) => qa.videoUrl.isNotEmpty)
              .toList();

          if (questionsWithVideo.isNotEmpty) {
            // 원본 리스트에서의 인덱스 찾기
            final firstQuestionWithVideo = questionsWithVideo.first;
            final originalIndex =
                _reportData!.questionAnswers!.indexOf(firstQuestionWithVideo);

            print(
                '🎬 영상이 있는 첫 번째 질문 (${originalIndex + 1}번) 비디오 로드: ${firstQuestionWithVideo.videoUrl}');
            _selectedQuestionIndex = originalIndex;
            _currentVideoUrl = firstQuestionWithVideo.videoUrl;
            await _initializeVideoPlayer(firstQuestionWithVideo.videoUrl);
          } else {
            print('⚠️ 영상이 있는 질문이 없습니다');
            _setError('답변 영상이 있는 질문이 없습니다.');
          }
        } else if (_reportData!.videoUrl.isNotEmpty) {
          // 기존 방식: 메인 비디오 URL 사용
          print('📹 메인 비디오 URL 사용');
          _currentVideoUrl = _reportData!.videoUrl;
          await _initializeVideoPlayer(_reportData!.videoUrl);
        } else {
          print('⚠️ 비디오 URL이 비어있습니다');
          _setError('비디오 URL이 없습니다. 면접이 제대로 완료되지 않았을 수 있습니다.');
        }
      } else {
        print('❌ 리포트 데이터가 null입니다');
        _setError('리포트 데이터를 찾을 수 없습니다.');
      }

      _setLoading(false);
    } catch (e) {
      print('❌ 리포트 로드 실패: $e');
      _setError('리포트를 불러올 수 없습니다: $e');
      _setLoading(false);
    }
  }

  /// 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      print('🎬 비디오 플레이어 초기화 시작');
      print('🔗 비디오 URL: $videoUrl');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await _videoPlayerController!.initialize();
      _isVideoInitialized = true;

      print('✅ 비디오 플레이어 초기화 완료');
      notifyListeners();
    } catch (e) {
      print('❌ 비디오 플레이어 초기화 실패: $e');
      _isVideoInitialized = false;
      _setError('비디오를 로드할 수 없습니다: $e');
    }
  }

  // 날짜 포맷팅 유틸리티 함수
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return '날짜 정보 없음';

    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        // Firestore 타임스탬프 변환
        date = (timestamp as Timestamp).toDate();
      }

      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 정보 오류';
    }
  }

  /// 면접 완료 후 보고서 생성
  ///
  /// 면접이 완료된 후 면접 데이터를 기반으로 보고서를 생성합니다.
  /// [interviewId]는 완료된 면접의 고유 식별자입니다.
  /// [resumeId]는 면접에 사용된 이력서의 고유 식별자입니다.
  /// [resumeData]는 면접에 사용된 이력서 데이터입니다.
  Future<String?> createInterviewReport(String interviewId, String resumeId,
      Map<String, dynamic> resumeData) async {
    try {
      _isCreatingReport = true;
      notifyListeners();

      // 서비스에 위임
      final report = await _reportService.createReport(
        interviewId: interviewId,
        resumeId: resumeId,
        resumeData: resumeData,
      );

      // 리포트 목록을 새로고침
      await loadReportList();

      _isCreatingReport = false;
      notifyListeners();
      return report?.id;
    } catch (e) {
      _setError('면접 보고서 생성 중 오류가 발생했습니다: $e');
      _isCreatingReport = false;
      notifyListeners();
      return null;
    }
  }

  /// 보고서 상태 업데이트
  ///
  /// [reportId] 보고서의 상태를 [status]로 업데이트합니다.
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      _setLoading(true);
      final result = await _reportService.updateReportStatus(reportId, status);

      // 상태 업데이트가 성공하면 목록 새로고침
      if (result) {
        await loadReportList();
      }

      _setLoading(false);
      return result;
    } catch (e) {
      _setError('보고서 상태 업데이트 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 보고서 비디오 URL 업데이트
  ///
  /// [reportId] 보고서의 비디오 URL을 [videoUrl]로 업데이트합니다.
  Future<bool> updateReportVideoUrl(String reportId, String videoUrl) async {
    try {
      final result =
          await _reportService.updateReportVideoUrl(reportId, videoUrl);

      // 현재 로드된 보고서가 업데이트 대상과 같다면 비디오 플레이어 갱신
      if (result && _reportData != null && _reportData!.id == reportId) {
        // 보고서 데이터 새로 로드
        await loadReport(reportId);
      }

      return result;
    } catch (e) {
      _setError('보고서 비디오 URL 업데이트 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 보고서 삭제
  ///
  /// [reportId] 보고서를 삭제합니다.
  Future<bool> deleteReport(String reportId) async {
    print('🗑️ 컨트롤러: 리포트 삭제 요청 - $reportId');

    try {
      final result = await _reportService.deleteReport(reportId);
      print('🗑️ 삭제 결과: $result');

      // 삭제가 성공하면 목록 새로고침
      if (result) {
        print('✅ 삭제 성공 - 목록 새로고침 중...');
        await loadReportList();
        print('✅ 목록 새로고침 완료');
      } else {
        print('❌ 삭제 실패');
      }

      return result;
    } catch (e) {
      print('❌ 삭제 중 예외 발생: $e');
      return false;
    }
  }

  // 리포트 목록 새로고침
  Future<void> refreshReportList() async {
    await loadReportList();
  }

  /// 질문 선택 시 해당 질문의 비디오로 전환
  Future<void> selectQuestion(int questionIndex) async {
    try {
      print('🎯 질문 ${questionIndex + 1} 선택됨');

      if (_reportData?.questionAnswers == null ||
          questionIndex >= _reportData!.questionAnswers!.length) {
        print('❌ 잘못된 질문 인덱스: $questionIndex');
        return;
      }

      final selectedQuestion = _reportData!.questionAnswers![questionIndex];
      final newVideoUrl = selectedQuestion.videoUrl;

      print('📹 새 비디오 URL: $newVideoUrl');
      print('📹 현재 비디오 URL: $_currentVideoUrl');

      // 상태 업데이트 (비디오 URL이 없어도 선택된 질문은 변경)
      _selectedQuestionIndex = questionIndex;
      notifyListeners();

      // 비디오 URL이 비어있으면 기존 비디오 정리하고 메시지 표시
      if (newVideoUrl.isEmpty) {
        print('⚠️ 선택된 질문의 비디오 URL이 비어있습니다');

        // 기존 비디오 컨트롤러 해제
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
        _isVideoInitialized = false;
        _currentVideoUrl = '';

        // 에러는 설정하지 않음 (정상적인 상황)
        notifyListeners();
        print('📝 질문 ${questionIndex + 1}: 답변 영상이 없는 정상 상태');
        return;
      }

      // 같은 비디오면 무시
      if (newVideoUrl == _currentVideoUrl) {
        print('🔄 동일한 비디오 - 변경 없음');
        return;
      }

      // 새 비디오로 전환
      _currentVideoUrl = newVideoUrl;

      // 기존 비디오 컨트롤러 해제
      _videoPlayerController?.dispose();
      _isVideoInitialized = false;
      notifyListeners();

      // 새 비디오 초기화
      await _initializeVideoPlayer(newVideoUrl);

      print('✅ 질문 ${questionIndex + 1} 비디오 전환 완료');
    } catch (e) {
      print('❌ 질문 선택 중 오류: $e');
      _setError('비디오 전환 중 오류가 발생했습니다: $e');
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 메시지 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // 컨트롤러 리소스 해제
  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
