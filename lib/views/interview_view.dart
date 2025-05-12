import 'package:flutter/material.dart';
import '../models/resume_model.dart';
import 'package:provider/provider.dart';
import '../controllers/interview_controller.dart';

class InterviewView extends StatelessWidget {
  final ResumeModel? resumeData;

  const InterviewView({Key? key, this.resumeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 생성 및 제공
    return ChangeNotifierProvider(
      create: (_) => InterviewController(initialResume: resumeData),
      child: const InterviewViewContent(),
    );
  }
}

class InterviewViewContent extends StatelessWidget {
  const InterviewViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 참조
    final controller = Provider.of<InterviewController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, controller),
      body: _buildBody(context, controller),
    );
  }

  // 앱바 빌드
  AppBar _buildAppBar(BuildContext context, InterviewController controller) {
    return AppBar(
      title: Text(controller.isInterviewStarted ? '면접 진행 중' : '면접 실행'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      actions: [
        // 이력서 선택 버튼
        if (!controller.isInterviewStarted)
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: '이력서 선택',
            onPressed: () => controller.showResumeSelectionDialog(context),
          ),
      ],
    );
  }

  // 본문 빌드
  Widget _buildBody(BuildContext context, InterviewController controller) {
    return SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 1200), // 최대 너비 설정
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 여백 (화면의 1/6)
                  Expanded(flex: 1, child: Container()),

                  // 중앙 내용 (화면의 2/3)
                  Expanded(
                    flex: 4,
                  child: controller.isInterviewStarted
                      ? _buildInterviewScreen(context, controller)
                      : _buildStartScreen(context, controller),
                  ),

                  // 오른쪽 여백 (화면의 1/6)
                  Expanded(flex: 1, child: Container()),
                ],
            ),
          ),
        ),
      ),
    );
  }

  // 면접 시작 화면
  Widget _buildStartScreen(
      BuildContext context, InterviewController controller) {
    // 선택된 이력서가 있으면 정보 표시
    final selectedResume = controller.selectedResume;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.mic,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 30),
        const Text(
          '모의 면접 시작하기',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            '면접 시뮬레이션을 통해 실제 면접에 대비하세요. 답변을 녹음하고 피드백을 받을 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // 선택된 이력서 정보 표시 (있는 경우)
        if (selectedResume != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(
                      '선택된 이력서: ${selectedResume.position}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '분야: ${selectedResume.field} | 경력: ${selectedResume.experience}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '면접 유형: ${selectedResume.interviewTypes.join(", ")}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

        // 이력서 선택 버튼
        if (selectedResume == null)
          OutlinedButton.icon(
            onPressed: () => controller.showResumeSelectionDialog(context),
            icon: const Icon(Icons.description),
            label: const Text('이력서 선택하기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // 면접 시작 버튼
        ElevatedButton.icon(
          onPressed: () => controller.startInterview(context),
          icon: const Icon(Icons.play_arrow),
          label: const Text('면접 시작하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 1,
            side: const BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // 면접 진행 화면
  Widget _buildInterviewScreen(
      BuildContext context, InterviewController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 빠른 설정 카드
        _buildInterviewSettings(context, controller),
        const SizedBox(height: 24),

        // 현재 질문 카드
        _buildCurrentQuestionCard(context, controller),
        const SizedBox(height: 24),

        // 질문 기록 카드
        _buildQuestionHistoryCard(context, controller),
      ],
    );
  }

  // 면접 설정 위젯
  Widget _buildInterviewSettings(
      BuildContext context, InterviewController controller) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.settings, color: Colors.deepPurple),
            const SizedBox(width: 16),
            const Text(
              '면접 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // 음성 인식 토글 등 설정 버튼
            OutlinedButton.icon(
              onPressed: () {}, // 설정 기능 구현
              icon: const Icon(Icons.mic),
              label: const Text('음성 인식'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 현재 질문 카드
  Widget _buildCurrentQuestionCard(
      BuildContext context, InterviewController controller) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              '현재 질문',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            controller.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      controller.currentQuestion,
                        style: const TextStyle(
                        fontSize: 20,
                        height: 1.5,
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
                  onPressed: controller.generateNextQuestion,
          icon: const Icon(Icons.refresh),
          label: const Text('다음 질문'),
          style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
                  onPressed: controller.endInterview,
                  icon: const Icon(Icons.stop),
          label: const Text('면접 종료'),
          style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
            ),
          ],
        ),
      ),
    );
  }

  // 질문 기록 카드
  Widget _buildQuestionHistoryCard(
      BuildContext context, InterviewController controller) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '질문 기록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            // 질문 목록
            ...controller.questionHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(question),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
