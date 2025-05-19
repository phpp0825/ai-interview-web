import 'package:flutter/material.dart';
import '../views/resume_view.dart';
import '../widgets/interview/interview_status_bar.dart';
import '../widgets/interview/interview_video_preview.dart';
import '../widgets/interview/interview_server_video_view.dart';
import '../widgets/interview/interview_control_bar.dart';
import '../controllers/interview_controller.dart';

/// HTTP 기반 인터뷰 화면
/// HTTP를 사용하여 비디오와 오디오 데이터를 서버로 전송합니다.
class HttpInterviewView extends StatefulWidget {
  final String? selectedResumeId;

  const HttpInterviewView({Key? key, this.selectedResumeId}) : super(key: key);

  @override
  _HttpInterviewViewState createState() => _HttpInterviewViewState();
}

class _HttpInterviewViewState extends State<HttpInterviewView> {
  // 컨트롤러 - nullable로 변경하고 초기값은 null로 설정
  InterviewController? _controller;

  // 상태 변수
  bool _isLoading = true;
  bool _resumeDialogShown = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  /// 컨트롤러 초기화
  Future<void> _initController() async {
    try {
      print('HttpInterviewView: 컨트롤러 초기화 시작');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('HttpInterviewView: InterviewController.create() 호출');
      final controller = await InterviewController.create();

      print(
          'HttpInterviewView: InterviewController 생성 ${controller != null ? "성공" : "실패"}');

      // 위젯이 아직 마운트 상태인지 확인
      if (!mounted) {
        print('HttpInterviewView: 위젯이 언마운트되어 초기화 중단');
        return;
      }

      // 컨트롤러가 null인 경우 처리
      if (controller == null) {
        print('HttpInterviewView: 컨트롤러가 null 값으로 반환됨');
        setState(() {
          _errorMessage = '면접 컨트롤러를 초기화할 수 없습니다. 다시 시도해 주세요.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      print(
          'HttpInterviewView: 컨트롤러 초기화 완료, 이력서 목록 크기: ${_controller?.resumeList.length ?? 0}');

      // 전달받은 이력서 ID가 있는 경우, 해당 이력서 선택
      if (widget.selectedResumeId != null && mounted && _controller != null) {
        print(
            'HttpInterviewView: 전달받은 이력서 ID로 이력서 선택: ${widget.selectedResumeId}');
        await _controller!.selectResume(widget.selectedResumeId!);
        _resumeDialogShown = true;
        return;
      }

      // 이력서 선택 다이얼로그를 항상 표시 (이력서가 없는 경우는 내부에서 처리)
      if (_controller != null && !_resumeDialogShown) {
        print('HttpInterviewView: 이력서 선택 다이얼로그 예약');
        _resumeDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('HttpInterviewView: 이력서 선택 다이얼로그 표시');
          _showResumeSelectionDialog();
        });
      } else {
        print('HttpInterviewView: 이력서 선택 다이얼로그를 표시할 수 없음');
      }
    } catch (e) {
      print('HttpInterviewView: 컨트롤러 초기화 중 예외 발생: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '컨트롤러 초기화 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });

        // 에러 메시지 표시
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog(_errorMessage!);
        });
      }
    }
  }

  /// 에러 처리
  void _handleError(String error) {
    _showErrorDialog(error);
  }

  /// 이력서 선택 다이얼로그 표시
  void _showResumeSelectionDialog() {
    // 컨트롤러가 초기화되지 않았으면 리턴
    if (_controller == null) {
      print('HttpInterviewView: 컨트롤러가 초기화되지 않아 다이얼로그를 표시할 수 없음');
      return;
    }

    // 이력서가 없는 경우 새 이력서 작성 안내
    if (_controller!.resumeList.isEmpty) {
      print('HttpInterviewView: 이력서 목록이 비어 있어 작성 안내 다이얼로그 표시');
      _showCreateResumeDialog();
      return;
    }

    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.5; // 화면 너비의 50%로 제한
    final dialogHeight = screenSize.height * 0.7; // 화면 높이의 70%로 설정

    print(
        'HttpInterviewView: 이력서 선택 다이얼로그 표시 (${_controller!.resumeList.length}개 항목)');

    showDialog(
      context: context,
      barrierDismissible: false, // 배경 탭으로 닫기 불가능
      builder: (context) => Dialog(
        // 다이얼로그 크기 제한
        insetPadding: EdgeInsets.symmetric(
          horizontal: (screenSize.width - dialogWidth) / 2,
          vertical: (screenSize.height - dialogHeight) / 3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 영역
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text(
                      '이력서 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 안내 텍스트
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '면접을 시작하기 전에 먼저 이력서를 선택해주세요. 이력서는 면접 질문과 분석에 사용됩니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 이력서 목록 (Expanded로 감싸 남은 공간을 차지하도록 함)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _controller!.resumeList.length,
                  itemBuilder: (context, index) {
                    final resume = _controller!.resumeList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(Icons.business_center,
                              color: Colors.deepPurple),
                        ),
                        title: Text(
                          resume['position'] ?? '직무 정보 없음',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(resume['field'] ?? '분야 정보 없음'),
                            Text(resume['experience'] ?? '경력 정보 없음',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                )),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            print(
                                'HttpInterviewView: 이력서 선택됨 - ${resume['id']}');
                            await _controller!.selectResume(resume['id']);
                            if (mounted) {
                              Navigator.pop(context);
                              _showSnackBar('이력서가 선택되었습니다');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('선택'),
                        ),
                        onTap: () async {
                          print('HttpInterviewView: 이력서 선택됨 - ${resume['id']}');
                          await _controller!.selectResume(resume['id']);
                          if (mounted) {
                            Navigator.pop(context);
                            _showSnackBar('이력서가 선택되었습니다');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // 버튼 영역
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('새 이력서'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateResumeDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이력서 작성 화면으로 이동 여부 확인
  void _showCreateResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이력서가 필요합니다'),
        content: const Text('면접을 시작하려면 이력서가 필요합니다. 이력서를 작성하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResumeView();
            },
            child: const Text('이력서 작성'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 이력서 작성 화면으로 이동
  void _navigateToResumeView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeView()),
    ).then((_) {
      // 이력서 작성 후 돌아왔을 때 목록 새로고침
      if (_controller != null) {
        _controller!.loadResumeList();
      }
    });
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (_controller != null) {
                _controller!.clearErrorMessage();
              }
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 에러가 있을 때 표시할 화면
    if (_isLoading) {
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

    // 에러 메시지가 있을 때 표시할 화면
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('면접 화면')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initController,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 컨트롤러가 초기화되지 않았을 때 표시할 화면
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('면접 화면')),
        body: const Center(
          child: Text('면접 컨트롤러를 초기화하지 못했습니다.'),
        ),
      );
    }

    // 정상적인 화면
    return AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('면접 화면'),
              actions: [
                // 이력서 선택 버튼
                IconButton(
                  icon: const Icon(Icons.description),
                  onPressed: _showResumeSelectionDialog,
                  tooltip: '이력서 선택',
                ),
                // 서버 연결 버튼
                IconButton(
                  icon: Icon(
                      _controller!.isConnected ? Icons.link : Icons.link_off),
                  onPressed: _controller!.isConnecting
                      ? null
                      : (_controller!.isConnected
                          ? () {
                              _controller!.disconnectFromServer();
                              _showSnackBar('서버와의 연결이 해제되었습니다');
                            }
                          : () async {
                              final success =
                                  await _controller!.connectToServer();
                              if (success) {
                                _showSnackBar('서버에 연결되었습니다');
                              }
                            }),
                  tooltip: _controller!.isConnected ? '서버 연결 해제' : '서버 연결',
                ),
              ],
            ),
            body: Column(
              children: [
                // 상태 표시줄
                InterviewStatusBar(
                  isConnected: _controller!.isConnected,
                  isInterviewStarted: _controller!.isInterviewStarted,
                  selectedResume: _controller!.selectedResume,
                ),

                // 비디오 영역 (웹캠 + 서버 영상)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 왼쪽: 웹캠 비디오
                      Expanded(
                        flex: 1,
                        child: InterviewVideoPreview(
                          cameraService: _controller!.cameraService,
                          isInterviewStarted: _controller!.isInterviewStarted,
                          onStartInterview: () async {
                            if (_controller!.selectedResume == null) {
                              _showResumeSelectionDialog();
                              return;
                            }

                            final success = await _controller!.startInterview();
                            if (success) {
                              _showSnackBar('면접이 시작되었습니다');
                            }
                          },
                        ),
                      ),

                      // 오른쪽: 서버 응답 영상
                      Expanded(
                        flex: 1,
                        child: InterviewServerVideoView(
                          serverResponseImage: _controller!.lastCapturedFrame,
                          isConnected: _controller!.isConnected,
                          isInterviewStarted: _controller!.isInterviewStarted,
                          currentQuestion: _controller!.currentQuestion,
                        ),
                      ),
                    ],
                  ),
                ),

                // 하단 컨트롤 바
                InterviewControlBar(
                  isInterviewStarted: _controller!.isInterviewStarted,
                  isUploadingVideo: _controller!.isUploadingVideo,
                  onStartInterview: () async {
                    if (_controller!.selectedResume == null) {
                      _showResumeSelectionDialog();
                      return;
                    }

                    final success = await _controller!.startInterview();
                    if (success) {
                      _showSnackBar('면접이 시작되었습니다');
                    }
                  },
                  onStopInterview: () async {
                    await _controller!.stopInterview();
                    _showSnackBar('면접이 종료되었습니다. 비디오가 업로드되고 보고서가 자동으로 생성됩니다.');
                  },
                ),
              ],
            ),
          );
        });
  }
}
