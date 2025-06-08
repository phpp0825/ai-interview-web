/// 정리된 리포트 모델 - 핵심 데이터만 포함
class ReportModel {
  final String id;
  final String title;
  final DateTime date;
  final String field;
  final String position;
  final String interviewType;
  final int duration;
  final int score;

  // 핵심 데이터 - 각 질문별 모든 정보가 포함됨
  final List<QuestionAnswerModel>? questionAnswers;

  ReportModel({
    required this.id,
    required this.title,
    required this.date,
    required this.field,
    required this.position,
    required this.interviewType,
    required this.duration,
    required this.score,
    this.questionAnswers,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      field: json['field'] ?? '',
      position: json['position'] ?? '',
      interviewType: json['interviewType'] ?? '',
      duration: json['duration'] ?? 0,
      score: json['score'] ?? 0,
      questionAnswers: (json['questionAnswers'] as List?)
          ?.map((qa) => QuestionAnswerModel.fromJson(qa))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'field': field,
      'position': position,
      'interviewType': interviewType,
      'duration': duration,
      'score': score,
      if (questionAnswers != null)
        'questionAnswers': questionAnswers!.map((qa) => qa.toJson()).toList(),
    };
  }
}

/// 질문-답변 모델 - 개별 질문의 모든 정보 포함
class QuestionAnswerModel {
  final String question;
  final String answer;
  final String videoUrl; // Firebase Storage 다운로드 URL
  final int score;
  final String evaluation;
  final int answerDuration;
  final String? poseAnalysis;

  QuestionAnswerModel({
    required this.question,
    required this.answer,
    required this.videoUrl,
    required this.score,
    required this.evaluation,
    required this.answerDuration,
    this.poseAnalysis,
  });

  factory QuestionAnswerModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnswerModel(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      score: json['score'] ?? 0,
      evaluation: json['evaluation'] ?? '',
      answerDuration: json['answerDuration'] ?? 0,
      poseAnalysis: json['poseAnalysis'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'question': question,
      'answer': answer,
      'videoUrl': videoUrl,
      'score': score,
      'evaluation': evaluation,
      'answerDuration': answerDuration,
    };

    // 선택적 필드들 추가
    if (poseAnalysis != null) json['poseAnalysis'] = poseAnalysis!;

    return json;
  }
}
