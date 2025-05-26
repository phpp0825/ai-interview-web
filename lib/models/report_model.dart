import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ReportModel {
  final String id;
  final String title;
  final DateTime date;
  final String field;
  final String position;
  final String interviewType;
  final int duration;
  final int score;
  final String videoUrl;
  final List<TimeStampModel> timestamps;
  final List<FlSpot> speechSpeedData;
  final List<ScatterSpot> gazeData;

  // 면접 세부 정보 필드 추가
  final List<QuestionAnswerModel>? questionAnswers;
  final List<SkillEvaluationModel>? skillEvaluations;
  final String? feedback;
  final String? grade;
  final Map<String, int>? categoryScores;

  ReportModel({
    required this.id,
    required this.title,
    required this.date,
    required this.field,
    required this.position,
    required this.interviewType,
    required this.duration,
    required this.score,
    required this.videoUrl,
    required this.timestamps,
    required this.speechSpeedData,
    required this.gazeData,
    // 새 필드들 (선택적)
    this.questionAnswers,
    this.skillEvaluations,
    this.feedback,
    this.grade,
    this.categoryScores,
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
      videoUrl: json['videoUrl'] ?? '',
      timestamps: (json['timestamps'] as List?)
              ?.map((t) => TimeStampModel.fromJson(t))
              .toList() ??
          [],
      speechSpeedData: _parseSpeechSpeedData(json['speechSpeedData']),
      gazeData: _parseGazeData(json['gazeData']),
      // 새 필드들 파싱
      questionAnswers: (json['questionAnswers'] as List?)
          ?.map((qa) => QuestionAnswerModel.fromJson(qa))
          .toList(),
      skillEvaluations: (json['skillEvaluations'] as List?)
          ?.map((se) => SkillEvaluationModel.fromJson(se))
          .toList(),
      feedback: json['feedback'],
      grade: json['grade'],
      categoryScores: json['categoryScores'] != null
          ? Map<String, int>.from(json['categoryScores'])
          : null,
    );
  }

  static List<FlSpot> _parseSpeechSpeedData(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((item) {
      return FlSpot(
        (item['x'] ?? 0).toDouble(),
        (item['y'] ?? 0).toDouble(),
      );
    }).toList();
  }

  static List<ScatterSpot> _parseGazeData(dynamic data) {
    if (data == null || data is! List) return [];

    return data.map((item) {
      return ScatterSpot(
        (item['x'] ?? 0).toDouble(),
        (item['y'] ?? 0).toDouble(),
        color: _parseColor(item['color'] ?? '#0000FF'),
        radius: (item['radius'] ?? 5).toDouble(),
      );
    }).toList();
  }

  static Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      return Color(int.parse('0xFF${colorStr.substring(1)}'));
    }
    // 기본값으로 파란색 반환
    return Colors.blue;
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
      'videoUrl': videoUrl,
      'timestamps': timestamps.map((t) => t.toJson()).toList(),
      'speechSpeedData': speechSpeedData
          .map((spot) => {
                'x': spot.x,
                'y': spot.y,
              })
          .toList(),
      'gazeData': gazeData
          .map((spot) => {
                'x': spot.x,
                'y': spot.y,
                'radius': spot.radius,
                'color': '#${spot.color.value.toRadixString(16).substring(2)}',
              })
          .toList(),
      // 새 필드들 추가
      if (questionAnswers != null)
        'questionAnswers': questionAnswers!.map((qa) => qa.toJson()).toList(),
      if (skillEvaluations != null)
        'skillEvaluations': skillEvaluations!.map((se) => se.toJson()).toList(),
      if (feedback != null) 'feedback': feedback,
      if (grade != null) 'grade': grade,
      if (categoryScores != null) 'categoryScores': categoryScores,
    };
  }
}

class TimeStampModel {
  final int time;
  final String label;
  final String description;

  TimeStampModel({
    required this.time,
    required this.label,
    required this.description,
  });

  factory TimeStampModel.fromJson(Map<String, dynamic> json) {
    return TimeStampModel(
      time: json['time'] ?? 0,
      label: json['label'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'label': label,
      'description': description,
    };
  }
}

/// 질문-답변 모델 (ReportModel용)
class QuestionAnswerModel {
  final String question;
  final String answer;
  final String videoUrl;
  final int score;
  final String evaluation;
  final int answerDuration;

  QuestionAnswerModel({
    required this.question,
    required this.answer,
    required this.videoUrl,
    required this.score,
    required this.evaluation,
    required this.answerDuration,
  });

  factory QuestionAnswerModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnswerModel(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      score: json['score'] ?? 0,
      evaluation: json['evaluation'] ?? '',
      answerDuration: json['answerDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'videoUrl': videoUrl,
      'score': score,
      'evaluation': evaluation,
      'answerDuration': answerDuration,
    };
  }
}

/// 기술 평가 모델 (ReportModel용)
class SkillEvaluationModel {
  final String skillName;
  final int score;
  final String level;
  final String comment;

  SkillEvaluationModel({
    required this.skillName,
    required this.score,
    required this.level,
    required this.comment,
  });

  factory SkillEvaluationModel.fromJson(Map<String, dynamic> json) {
    return SkillEvaluationModel(
      skillName: json['skillName'] ?? '',
      score: json['score'] ?? 0,
      level: json['level'] ?? 'Beginner',
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillName': skillName,
      'score': score,
      'level': level,
      'comment': comment,
    };
  }
}
