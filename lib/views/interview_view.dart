import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/interview_controller.dart';
import '../widgets/interview/interview_video_preview.dart';
import '../widgets/interview/interview_server_video_view.dart';
import '../widgets/interview/interview_control_bar.dart';
import '../widgets/interview/interview_dialogs.dart';
import 'resume_list_view.dart';

class InterviewView extends StatefulWidget {
  final String? selectedResumeId;

  const InterviewView({Key? key, this.selectedResumeId}) : super(key: key);

  @override
  _InterviewViewState createState() => _InterviewViewState();
}

class _InterviewViewState extends State<InterviewView> {
  late InterviewController _controller;
  bool _resumeDialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = InterviewController();
    _initializeInterview();
  }

  /// 면접 초기화
  Future<void> _initializeInterview() async {
    // 컨트롤러 초기화 완료까지 대기
    await _waitForControllerReady();

    // 전달받은 이력서 ID가 있는 경우, 해당 이력서 선택
    if (widget.selectedResumeId != null && mounted) {
      await _controller.selectResume(widget.selectedResumeId!);
      _resumeDialogShown = true;
      return;
    }

    // 이력서 선택 화면을 항상 표시
    if (!_resumeDialogShown && mounted) {
      _resumeDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeSelection();
      });
    }
  }

  /// 컨트롤러 준비 완료까지 대기
  Future<void> _waitForControllerReady() async {
    // 컨트롤러가 로딩 중이면 완료까지 대기
    while (_controller.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 이력서 선택 화면 표시
  void _showResumeSelection() {
    // 새로운 이력서 목록 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeListView(
          onResumeSelected: (resume) async {
            await _controller.selectResume(resume.resume_id);
            if (mounted) {
              // 이력서 선택 완료 후 면접 화면으로 돌아가기
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  /// 면접 시작 처리
  Future<void> _handleStartInterview() async {
    if (_controller.selectedResume == null) {
      _showResumeSelection();
      return;
    }

    // 면접 시작 (알림 제거)
    await _controller.startInterview();
  }

  /// 면접 종료 처리
  Future<void> _handleStopInterview() async {
    // 면접 종료 처리 (알림 제거)
    await _controller.stopFullInterview();

    if (mounted) {
      // 바로 홈 화면으로 이동 (대기 시간 제거)
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (Route<dynamic> route) => false,
      );
    }
  }

  /// 다음 영상으로 이동 처리
  Future<void> _handleNextVideo() async {
    try {
      await _controller.moveToNextVideo();
    } catch (e) {
      // 오류 발생 시에만 알림 표시
      if (mounted) {
        InterviewDialogs.showSnackBar(
            context: context, message: '❌ 질문 이동 중 오류가 발생했습니다: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<InterviewController>(
        builder: (context, controller, child) {
          // 로딩 중 화면
          if (controller.isLoading) {
            return _buildLoadingScreen();
          }

          // 에러 화면
          if (controller.errorMessage != null) {
            return _buildErrorScreen(controller.errorMessage!);
          }

          // 메인 면접 화면
          return _buildMainScreen(controller);
        },
      ),
    );
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('면접 화면')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('면접 환경을 준비하는 중...')
          ],
        ),
      ),
    );
  }

  /// 에러 화면
  Widget _buildErrorScreen(String errorMessage) {
    return Scaffold(
      appBar: AppBar(title: const Text('면접 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeInterview,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 메인 면접 화면
  Widget _buildMainScreen(InterviewController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 면접'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _showResumeSelection,
            tooltip: '이력서 선택',
          ),
        ],
      ),
      body: _buildInterviewBody(controller),
    );
  }

  /// 면접 본문 (면접관 영상만 표시)
  Widget _buildInterviewBody(InterviewController controller) {
    return Column(
      children: [
        // === 면접관 영상 영역 (전체 화면) ===
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InterviewServerVideoView(
              serverResponseImage: null,
              isConnected: true,
              isInterviewStarted: controller.isInterviewStarted,
              videoPath: controller.currentInterviewerVideoPath,
              isVideoPlaying: controller.isInterviewerVideoPlaying,
              isCountdownActive: controller.isCountdownActive,
              countdownSeconds: controller.countdownSeconds,
              onVideoCompleted: controller.onInterviewerVideoCompleted,
            ),
          ),
        ),

        // 하단 컨트롤 바
        InterviewControlBar(
          isInterviewStarted: controller.isInterviewStarted,
          isUploadingVideo: controller.isUploadingVideo,
          isAnalyzingVideo: controller.isAnalyzingVideo,
          hasSelectedResume: controller.selectedResume != null,
          onStartInterview: _handleStartInterview,
          onStopInterview: _handleStopInterview,
          onNextVideo: _handleNextVideo,
        ),
      ],
    );
  }
}
