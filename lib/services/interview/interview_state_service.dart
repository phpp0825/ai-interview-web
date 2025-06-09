import 'dart:async';
import 'package:flutter/material.dart';

/// 면접 상태와 진행 과정을 관리하는 서비스
/// 면접의 시작/종료, 질문 진행, 카운트다운 등을 처리합니다
class InterviewStateService {
  // === 면접 상태 ===
  bool _isInterviewStarted = false;
  int _currentQuestionIndex = -1;
  DateTime? _interviewStartTime;

  // === 카운트다운 ===
  bool _isCountdownActive = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  // === 콜백 함수들 ===
  VoidCallback? _onStateChanged;
  VoidCallback? _onCountdownCompleted;

  // === Getters ===
  bool get isInterviewStarted => _isInterviewStarted;
  int get currentQuestionIndex => _currentQuestionIndex;
  DateTime? get interviewStartTime => _interviewStartTime;
  bool get isCountdownActive => _isCountdownActive;
  int get countdownSeconds => _countdownSeconds;

  /// 면접 상태 변경 콜백 설정
  void setStateChangedCallback(VoidCallback callback) {
    _onStateChanged = callback;
  }

  /// 카운트다운 완료 콜백 설정
  void setCountdownCompletedCallback(VoidCallback callback) {
    _onCountdownCompleted = callback;
  }

  /// 면접 시작
  bool startInterview() {
    if (_isInterviewStarted) {
      return false;
    }

    _isInterviewStarted = true;
    _interviewStartTime = DateTime.now();
    _currentQuestionIndex = 0;

    _notifyStateChanged();
    return true;
  }

  /// 면접 종료
  void endInterview() {
    _isInterviewStarted = false;
    _cleanupTimers();
    _notifyStateChanged();
  }

  /// 다음 질문으로 이동
  bool moveToNextQuestion() {
    const totalQuestions = 3;

    if (_currentQuestionIndex < totalQuestions - 1) {
      _currentQuestionIndex++;
      _notifyStateChanged();
      return true;
    }

    // 모든 질문 완료
    return false;
  }

  /// 현재 면접 진행 시간 계산 (초)
  int getInterviewDuration() {
    if (_interviewStartTime == null) return 0;
    return DateTime.now().difference(_interviewStartTime!).inSeconds;
  }

  /// 답변 준비 카운트다운 시작
  void startAnswerCountdown() {
    _isCountdownActive = true;
    _countdownSeconds = 5;
    _notifyStateChanged();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      _notifyStateChanged();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _isCountdownActive = false;
        _notifyStateChanged();

        // 카운트다운 완료 알림
        _onCountdownCompleted?.call();
      }
    });
  }

  /// 면접 질문 목록 반환
  List<String> getInterviewQuestions() {
    return [
      "먼저 간단한 자기소개와 우리 회사에 지원하게 된 구체적인 동기를 말씀해주세요.",
      "팀 프로젝트에서 협업하는 것을 중요하게 생각하시나요? 팀 내에서 자신의 역할을 어떻게 생각하며, 팀워크를 향상시키기 위해 어떤 노력을 할 수 있을까요?",
      "새로운 기술을 배우는 것을 즐기시는 편인가요? 최근에 학습한 기술이나 도구가 있다면, 그것이 귀하의 업무에 어떻게 적용될 수 있을지 설명해주실 수 있나요?",
    ];
  }

  /// 현재 질문 텍스트 반환
  String? getCurrentQuestion() {
    final questions = getInterviewQuestions();
    if (_currentQuestionIndex >= 0 &&
        _currentQuestionIndex < questions.length) {
      return questions[_currentQuestionIndex];
    }
    return null;
  }

  /// 상태 변경 알림
  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  /// 타이머 정리
  void _cleanupTimers() {
    _countdownTimer?.cancel();
    _isCountdownActive = false;
    _countdownSeconds = 0;
  }

  /// 메모리 정리
  void dispose() {
    _cleanupTimers();
    _onStateChanged = null;
    _onCountdownCompleted = null;
  }
}
