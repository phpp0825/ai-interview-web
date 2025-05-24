import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/interview_controller.dart';
import '../widgets/interview/interview_status_bar.dart';
import '../widgets/interview/interview_video_preview.dart';
import '../widgets/interview/interview_server_video_view.dart';
import '../widgets/interview/interview_control_bar.dart';
import '../widgets/interview/interview_dialogs.dart';

/// 간단해진 면접 화면
/// 컨트롤러 패턴을 사용하여 비즈니스 로직을 분리했습니다.
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

    final success = await _controller.startInterview();
    if (success && mounted) {
      InterviewDialogs.showSnackBar(context: context, message: '면접이 시작되었습니다');
    } else if (_controller.errorMessage != null && mounted) {
      InterviewDialogs.showErrorDialog(
        context: context,
        message: _controller.errorMessage!,
      );
    }
  }

  /// 면접 종료 처리
  Future<void> _handleStopInterview() async {
    await _controller.stopInterview();
    if (mounted) {
      InterviewDialogs.showSnackBar(
          context: context, message: '면접이 종료되었습니다. 평가가 진행됩니다.');
    }
  }

  /// 서버 연결 처리
  Future<void> _handleServerConnection() async {
    if (_controller.isConnected) {
      _controller.disconnectFromServer();
      InterviewDialogs.showSnackBar(
          context: context, message: '서버와의 연결이 해제되었습니다');
    } else {
      final success = await _controller.connectToServer();
      if (mounted) {
        InterviewDialogs.showSnackBar(
            context: context,
            message: success ? '서버에 연결되었습니다' : '서버 연결에 실패했습니다');
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
        title: const Text('면접 화면'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _showResumeSelectionDialog,
            tooltip: '이력서 선택',
          ),
          IconButton(
            icon: Icon(controller.isConnected ? Icons.link : Icons.link_off),
            onPressed: _handleServerConnection,
            tooltip: controller.isConnected ? '서버 연결 해제' : '서버 연결',
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 표시줄
          InterviewStatusBar(
            isConnected: controller.isConnected,
            isInterviewStarted: controller.isInterviewStarted,
            selectedResume: controller.selectedResume,
          ),

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

                // 오른쪽: 서버 응답 영상
                Expanded(
                  flex: 1,
                  child: InterviewServerVideoView(
                    serverResponseImage: controller.lastCapturedFrame,
                    isConnected: controller.isConnected,
                    isInterviewStarted: controller.isInterviewStarted,
                    currentQuestion: controller.currentQuestion,
                  ),
                ),
              ],
            ),
          ),

          // 하단 컨트롤 바
          InterviewControlBar(
            isInterviewStarted: controller.isInterviewStarted,
            isUploadingVideo: controller.isUploadingVideo,
            onStartInterview: _handleStartInterview,
            onStopInterview: _handleStopInterview,
          ),
        ],
      ),
    );
  }
}
