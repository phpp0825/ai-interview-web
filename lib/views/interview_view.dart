import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/interview_controller.dart';
import '../widgets/interview/interview_video_preview.dart';
import '../widgets/interview/interview_server_video_view.dart';
import '../widgets/interview/interview_control_bar.dart';
import '../widgets/interview/interview_dialogs.dart';

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
    await _controller.initializeServices();

    // 전달받은 이력서 ID가 있는 경우, 해당 이력서 선택
    if (widget.selectedResumeId != null && mounted) {
      final success = await _controller.selectResume(widget.selectedResumeId!);
      if (success) {
        _resumeDialogShown = true;
        InterviewDialogs.showSnackBar(
            context: context, message: '이력서가 선택되었습니다');
      }
      return;
    }

    // 이력서 선택 다이얼로그를 항상 표시
    if (!_resumeDialogShown && mounted) {
      _resumeDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeSelectionDialog();
      });
    }
  }

  /// 이력서 선택 다이얼로그 표시
  void _showResumeSelectionDialog() {
    InterviewDialogs.showResumeSelectionDialog(
      context: context,
      resumeList: _controller.resumeList,
      onResumeSelected: (String resumeId) async {
        final success = await _controller.selectResume(resumeId);
        if (success && mounted) {
          InterviewDialogs.showSnackBar(
              context: context, message: '이력서가 선택되었습니다');
        }
      },
      onCreateResume: () {
        _controller.loadResumeList();
      },
    );
  }

  /// 면접 시작 처리
  Future<void> _handleStartInterview() async {
    if (_controller.selectedResume == null) {
      _showResumeSelectionDialog();
      return;
    }

    // 면접 시작 (서버 연결 체크 제거)
    final success = await _controller.startInterview();
    if (success && mounted) {
      InterviewDialogs.showSnackBar(
        context: context,
        message: '🎬 면접이 시작되었습니다! 면접관 영상을 확인하세요.',
      );
    }
  }

  /// 면접 종료 처리
  Future<void> _handleStopInterview() async {
    // 로딩 표시 (선택사항)
    if (mounted) {
      InterviewDialogs.showSnackBar(
        context: context,
        message: '🎬 면접을 종료하고 있습니다...',
      );
    }

    // 면접 종료 처리
    await _controller.stopFullInterview();

    if (mounted) {
      // 간단한 완료 메시지만 표시
      InterviewDialogs.showSnackBar(
        context: context,
        message: '✅ 면접이 완료되었습니다!',
      );

      // 잠시 대기 후 홈 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        // 홈 화면으로 즉시 이동 (모든 이전 화면 제거)
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  /// 다음 영상으로 이동 처리
  Future<void> _handleNextVideo() async {
    try {
      // 업로드 시작 알림
      if (mounted) {
        InterviewDialogs.showSnackBar(
            context: context, message: '📤 답변 영상을 업로드하고 있습니다...');
      }

      await _controller.moveToNextVideo();

      // 업로드 완료 및 다음 질문 이동 알림
      if (mounted) {
        InterviewDialogs.showSnackBar(
            context: context, message: '✅ 업로드 완료! 다음 질문이 시작됩니다.');
      }
    } catch (e) {
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
            onPressed: _showResumeSelectionDialog,
            tooltip: '이력서 선택',
          ),
        ],
      ),
      body: _buildInterviewBody(controller),
    );
  }

  /// 면접 본문 (상태에 따라 다른 화면 표시)
  Widget _buildInterviewBody(InterviewController controller) {
    // 기본 면접 화면
    return Column(
      children: [
        // 비디오 영역
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 왼쪽: 웹캠 비디오
              Expanded(
                flex: 1,
                child: controller.cameraService != null
                    ? InterviewVideoPreview(
                        cameraService: controller.cameraService!,
                        isInterviewStarted: controller.isInterviewStarted,
                        onStartInterview: _handleStartInterview,
                      )
                    : const Center(child: Text('카메라를 초기화하는 중...')),
              ),

              // 오른쪽: 서버 응답 영상 (서버 연결 상태 제거)
              Expanded(
                flex: 1,
                child: InterviewServerVideoView(
                  serverResponseImage: controller.serverResponseImage,
                  isConnected: true, // 항상 연결된 것으로 표시
                  isInterviewStarted: controller.isInterviewStarted,
                  videoPath: controller.currentInterviewerVideoPath,
                  isVideoPlaying: controller.isInterviewerVideoPlaying,
                  isCountdownActive: controller.isCountdownActive,
                  countdownSeconds: controller.countdownSeconds,
                  onVideoCompleted: controller.onInterviewerVideoCompleted,
                ),
              ),
            ],
          ),
        ),

        // 하단 컨트롤 바 (서버 연결 관련 제거)
        InterviewControlBar(
          isInterviewStarted: controller.isInterviewStarted,
          isUploadingVideo: controller.isUploadingVideo,
          hasSelectedResume: controller.selectedResume != null,
          onStartInterview: _handleStartInterview,
          onStopInterview: _handleStopInterview,
          onNextVideo: _handleNextVideo,
        ),
      ],
    );
  }
}
