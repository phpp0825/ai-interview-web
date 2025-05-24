import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 서버로부터 받아온 영상을 표시하는 위젯
class InterviewServerVideoView extends StatelessWidget {
  final Uint8List? serverResponseImage;
  final bool isConnected;
  final bool isInterviewStarted;
  final String? currentQuestion;

  const InterviewServerVideoView({
    Key? key,
    required this.serverResponseImage,
    required this.isConnected,
    required this.isInterviewStarted,
    this.currentQuestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: _buildContent(),
      ),
    );
  }

  /// 내용 표시
  Widget _buildContent() {
    // 서버에 연결되지 않은 경우
    if (!isConnected) {
      return _buildNotConnectedView();
    }

    // 인터뷰가 시작되지 않은 경우
    if (!isInterviewStarted) {
      return _buildNotStartedView();
    }

    // 서버 응답 이미지가 있는 경우
    if (serverResponseImage != null && serverResponseImage!.isNotEmpty) {
      return _buildServerImageView();
    }

    // 서버 응답이 없는 경우 질문 표시
    return _buildQuestionView();
  }

  /// 서버 연결 안됨 화면
  Widget _buildNotConnectedView() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '서버에 연결되지 않았습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '서버에 연결하려면 우측 상단의 연결 버튼을 클릭하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 인터뷰 시작 안 됨 화면
  Widget _buildNotStartedView() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '인터뷰가 시작되지 않았습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '인터뷰를 시작하면 이곳에 AI의 응답이 표시됩니다',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 서버 이미지 표시 화면
  Widget _buildServerImageView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Image.memory(
          serverResponseImage!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 질문 표시 화면
  Widget _buildQuestionView() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.question_answer,
                size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              '현재 질문:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (currentQuestion != null && currentQuestion!.isNotEmpty)
              Text(
                currentQuestion!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              )
            else
              const Text(
                '질문을 기다리는 중...',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
