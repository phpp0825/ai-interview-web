/// 인터뷰 서비스 인터페이스
///
/// 인터뷰 관련 기능을 제공하는 서비스의 인터페이스입니다.
abstract class IInterviewService {
  /// 인터뷰가 시작되었는지 여부
  bool get isInterviewStarted;

  /// 현재 인터뷰에 사용 중인 이력서 ID
  String? get resumeId;

  /// 인터뷰 질문 목록
  List<String> get questions;

  /// 현재 질문 인덱스
  int get currentQuestionIndex;

  /// 더 많은 질문이 있는지 여부
  bool get hasMoreQuestions;

  /// 인터뷰 시작
  ///
  /// 인터뷰 세션을 시작합니다.
  Future<bool> startInterview();

  /// 인터뷰 종료
  ///
  /// 현재 진행 중인 인터뷰를 종료합니다.
  Future<void> stopInterview();

  /// 인터뷰 영상 업로드
  ///
  /// [resumeId]에 해당하는 이력서의 인터뷰 영상을 업로드합니다.
  Future<bool> uploadInterviewVideo(String resumeId);

  /// 이력서 데이터 업로드
  ///
  /// 인터뷰에 사용할 이력서 데이터를 업로드합니다.
  Future<bool> uploadResumeData(Map<String, dynamic> resumeData);

  /// 인터뷰 질문 가져오기
  ///
  /// 서버에서 인터뷰 질문 목록을 가져옵니다.
  Future<bool> getQuestions();

  /// 다음 질문으로 이동
  ///
  /// 다음 인터뷰 질문으로 이동합니다.
  bool moveToNextQuestion();

  /// 질문에 대한 답변 제출
  ///
  /// 현재 질문에 대한 답변을 제출합니다.
  Future<bool> submitAnswer(String answer);

  /// 분석 로그 가져오기
  ///
  /// 인터뷰 분석 로그를 가져옵니다.
  Future<String?> getAnalysisLog();

  /// 피드백 요약 가져오기
  ///
  /// 인터뷰 피드백 요약을 가져옵니다.
  Future<String?> getFeedbackSummary();
}
