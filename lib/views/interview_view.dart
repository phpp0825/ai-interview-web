import 'package:flutter/material.dart';
import '../models/resume_model.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import 'dart:math';

class InterviewView extends StatefulWidget {
  final ResumeModel? resumeData;

  const InterviewView({Key? key, this.resumeData}) : super(key: key);

  @override
  State<InterviewView> createState() => _InterviewViewState();
}

class _InterviewViewState extends State<InterviewView> {
  bool _isInterviewStarted = false;
  String _currentQuestion = '';
  List<String> _questionHistory = [];
  bool _isLoading = false;

  // 면접 질문 라이브러리
  final Map<String, List<String>> _questionLibrary = {
    '직무면접': [
      '해당 직무에 지원한 이유는 무엇인가요?',
      '본인의 기술 스택에 대해 설명해주세요.',
      '가장 어려웠던 프로젝트와 해결 방법을 설명해주세요.',
      '팀 프로젝트에서 맡았던 역할은 무엇인가요?',
      '코드 리뷰에 대한 본인의 의견은 어떠한가요?',
      '새로운 기술을 배우는데 어떤 방식으로 접근하시나요?',
      '버전 관리 시스템을 어떻게 활용하시나요?',
      '프로젝트 진행 중 일정이 지연될 때 어떻게 대처하시나요?',
      '최근에 공부하고 있는 기술이나 언어가 있나요?',
      '본인의 개발 스타일은 어떠한가요?'
    ],
    '인성면접': [
      '본인의 장점과 단점에 대해 말씀해주세요.',
      '스트레스를 받을 때 어떻게 해소하시나요?',
      '의견 충돌이 있을 때 어떻게 해결하시나요?',
      '실패했던 경험과 그 후의 대처에 대해 말씀해주세요.',
      '목표를 달성하기 위해 어떤 노력을 하시나요?',
      '팀원과 갈등이 생겼을 때 어떻게 해결하시나요?',
      '업무 외에 자기계발을 위해 무엇을 하고 계신가요?',
      '리더십을 발휘했던 경험이 있으신가요?',
      '10년 후 자신의 모습은 어떨 것 같나요?',
      '마지막으로 하고 싶은 말씀이 있으신가요?'
    ]
  };

  void _startInterview() {
    if (widget.resumeData == null) {
      _showNoResumeDialog();
      return;
    }

    setState(() {
      _isInterviewStarted = true;
      _questionHistory = [];
      _generateNextQuestion();
    });
  }

  void _showNoResumeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('이력서 정보 없음'),
          content:
              const Text('면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서 작성 페이지로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 홈 화면으로 돌아가기
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: BorderSide(color: Colors.deepPurple),
              ),
              child: const Text('이력서 작성하기'),
            ),
          ],
        );
      },
    );
  }

  void _generateNextQuestion() {
    setState(() {
      _isLoading = true;
    });

    // 실제로는 API, 호출이 필요할 수 있으므로 비동기 처리를 흉내냄
    Future.delayed(const Duration(seconds: 1), () {
      final List<String> availableQuestionTypes = [];

      // 선택된 면접 유형에 따라 질문 카테고리 결정
      if (widget.resumeData != null) {
        for (String type in widget.resumeData!.interviewTypes) {
          if (_questionLibrary.containsKey(type)) {
            availableQuestionTypes.add(type);
          }
        }
      } else {
        availableQuestionTypes.addAll(_questionLibrary.keys);
      }

      if (availableQuestionTypes.isEmpty) {
        availableQuestionTypes.add('직무면접'); // 기본값
      }

      // 랜덤 질문 카테고리 선택
      final random = Random();
      final questionType =
          availableQuestionTypes[random.nextInt(availableQuestionTypes.length)];

      // 해당 카테고리에서 아직 나오지 않은 질문 선택
      final questionsForType = _questionLibrary[questionType]!;
      final availableQuestions =
          questionsForType.where((q) => !_questionHistory.contains(q)).toList();

      // 모든 질문이 이미 나왔으면 전체에서 다시 선택
      final nextQuestion = availableQuestions.isEmpty
          ? questionsForType[random.nextInt(questionsForType.length)]
          : availableQuestions[random.nextInt(availableQuestions.length)];

      setState(() {
        _currentQuestion = nextQuestion;
        _questionHistory.add(nextQuestion);
        _isLoading = false;
      });
    });
  }

  void _endInterview() {
    setState(() {
      _isInterviewStarted = false;
      _currentQuestion = '';
      _questionHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isInterviewStarted ? '면접 진행 중' : '면접 실행'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    child: _isInterviewStarted
                        ? _buildInterviewScreen()
                        : _buildStartScreen(),
                  ),

                  // 오른쪽 여백 (화면의 1/6)
                  Expanded(flex: 1, child: Container()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
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
        ElevatedButton.icon(
          onPressed: _startInterview,
          icon: const Icon(Icons.play_arrow),
          label: const Text('면접 시작하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 1,
            side: BorderSide(color: Colors.deepPurple),
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

  Widget _buildInterviewSettings() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '면접 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.resumeData != null) ...[
              _buildInfoRow('지원 분야:', widget.resumeData!.field),
              _buildInfoRow('희망 직무:', widget.resumeData!.position),
              _buildInfoRow('경력 여부:', widget.resumeData!.experience),
              _buildInfoRow(
                  '면접 유형:', widget.resumeData!.interviewTypes.join(', ')),
            ] else ...[
              const Text(
                '이력서 정보가 없습니다. 일반적인 면접 질문으로 진행됩니다.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewScreen() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      const Icon(
                        Icons.question_answer,
                        size: 40,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentQuestion,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 40),
        _buildCameraPreviewPlaceholder(),
        const SizedBox(height: 30),
        _buildActionButtons(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCameraPreviewPlaceholder() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade600,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/camera_image.png',
            height: 150,
            color: Colors.white.withOpacity(0.9),
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            '카메라 영상이 여기에 표시됩니다',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _generateNextQuestion,
          icon: const Icon(Icons.refresh),
          label: const Text('다음 질문'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 1,
            side: BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _endInterview,
          icon: const Icon(Icons.close),
          label: const Text('면접 종료'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
