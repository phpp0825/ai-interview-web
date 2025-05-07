import 'package:flutter/material.dart';
import 'dart:math';
import '../models/resume_model.dart';
import '../views/resume_view.dart';

class InterviewController extends ChangeNotifier {
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

  // 상태 변수들
  final ResumeModel? resumeData;
  bool _isInterviewStarted = false;
  String _currentQuestion = '';
  List<String> _questionHistory = [];
  bool _isLoading = false;

  // Getters
  bool get isInterviewStarted => _isInterviewStarted;
  String get currentQuestion => _currentQuestion;
  List<String> get questionHistory => _questionHistory;
  bool get isLoading => _isLoading;

  // 생성자
  InterviewController({this.resumeData});

  // 면접 시작
  void startInterview(BuildContext context) {
    if (resumeData == null) {
      showNoResumeDialog(context);
      return;
    }

    _isInterviewStarted = true;
    _questionHistory = [];
    generateNextQuestion();
    notifyListeners();
  }

  // 다음 질문 생성
  void generateNextQuestion() {
    _isLoading = true;
    notifyListeners();

    // 실제로는 API 호출이 필요할 수 있으므로 비동기 처리를 흉내냄
    Future.delayed(const Duration(seconds: 1), () {
      final List<String> availableQuestionTypes = [];

      // 선택된 면접 유형에 따라 질문 카테고리 결정
      if (resumeData != null) {
        for (String type in resumeData!.interviewTypes) {
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

      _currentQuestion = nextQuestion;
      _questionHistory.add(nextQuestion);
      _isLoading = false;
      notifyListeners();
    });
  }

  // 면접 종료
  void endInterview() {
    _isInterviewStarted = false;
    _currentQuestion = '';
    _questionHistory = [];
    notifyListeners();
  }

  // 이력서 없음 다이얼로그 표시
  void showNoResumeDialog(BuildContext context) {
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
                side: const BorderSide(color: Colors.deepPurple),
              ),
              child: const Text('이력서 작성하기'),
            ),
          ],
        );
      },
    );
  }

  // 이력서 작성 페이지로 이동
  void navigateToResumeView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeView()),
    );
  }
}
