class ResumeModel {
  String field;
  String position;
  String experience;
  List<String> interviewTypes;
  List<Certificate> certificates;
  Education education;
  SelfIntroduction selfIntroduction;

  ResumeModel({
    this.field = '웹 개발',
    this.position = '백엔드 개발자',
    this.experience = '신입',
    List<String>? interviewTypes,
    List<Certificate>? certificates,
    Education? education,
    SelfIntroduction? selfIntroduction,
  })  : interviewTypes = interviewTypes ?? ['직무면접'],
        certificates = certificates ?? [],
        education = education ?? Education(),
        selfIntroduction = selfIntroduction ?? SelfIntroduction();

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'position': position,
      'experience': experience,
      'interviewTypes': interviewTypes,
      'certificates': certificates.map((c) => c.toMap()).toList(),
      'education': education.toMap(),
      'selfIntroduction': selfIntroduction.toMap(),
    };
  }

  static ResumeModel fromMap(Map<String, dynamic> map) {
    return ResumeModel(
      field: map['field'] ?? '웹 개발',
      position: map['position'] ?? '백엔드 개발자',
      experience: map['experience'] ?? '신입',
      interviewTypes: List<String>.from(map['interviewTypes'] ?? ['직무면접']),
      certificates: (map['certificates'] as List?)
              ?.map((c) => Certificate.fromMap(c))
              .toList() ??
          [],
      education: map['education'] != null
          ? Education.fromMap(map['education'])
          : Education(),
      selfIntroduction: map['selfIntroduction'] != null
          ? SelfIntroduction.fromMap(map['selfIntroduction'])
          : SelfIntroduction(),
    );
  }

  bool get hasPersonalityInterview => interviewTypes.contains('인성면접');
}

class Certificate {
  String name;
  String issuer;
  String date;
  String score;

  Certificate({
    this.name = '',
    this.issuer = '',
    this.date = '',
    this.score = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'issuer': issuer,
      'date': date,
      'score': score,
    };
  }

  static Certificate fromMap(Map<String, dynamic> map) {
    return Certificate(
      name: map['name'] ?? '',
      issuer: map['issuer'] ?? '',
      date: map['date'] ?? '',
      score: map['score'] ?? '',
    );
  }
}

class Education {
  String school;
  String major;
  String degree;
  String startDate;
  String endDate;
  String gpa;
  String totalGpa;

  Education({
    this.school = '',
    this.major = '',
    this.degree = '학사',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
    this.totalGpa = '4.5',
  });

  Map<String, dynamic> toMap() {
    return {
      'school': school,
      'major': major,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
      'gpa': gpa,
      'totalGpa': totalGpa,
    };
  }

  static Education fromMap(Map<String, dynamic> map) {
    return Education(
      school: map['school'] ?? '',
      major: map['major'] ?? '',
      degree: map['degree'] ?? '학사',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      gpa: map['gpa'] ?? '',
      totalGpa: map['totalGpa'] ?? '4.5',
    );
  }
}

class SelfIntroduction {
  String? motivation;
  String? strength;

  SelfIntroduction({
    this.motivation,
    this.strength,
  });

  Map<String, dynamic> toMap() {
    return {
      'motivation': motivation,
      'strength': strength,
    };
  }

  factory SelfIntroduction.fromMap(Map<String, dynamic> map) {
    return SelfIntroduction(
      motivation: map['motivation'],
      strength: map['strength'],
    );
  }
}
