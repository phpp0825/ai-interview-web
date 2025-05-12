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

  // Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'position': position,
      'experience': experience,
      'interviewTypes': interviewTypes,
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'education': education.toJson(),
      'selfIntroduction': selfIntroduction.toJson(),
    };
  }

  // 기존 호환성을 위해 toMap 메소드 유지
  Map<String, dynamic> toMap() => toJson();

  // Map에서 객체 생성 (JSON 역직렬화)
  static ResumeModel fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      field: json['field'] ?? '웹 개발',
      position: json['position'] ?? '백엔드 개발자',
      experience: json['experience'] ?? '신입',
      interviewTypes: List<String>.from(json['interviewTypes'] ?? ['직무면접']),
      certificates: (json['certificates'] as List?)
              ?.map((c) => Certificate.fromJson(c))
              .toList() ??
          [],
      education: json['education'] != null
          ? Education.fromJson(json['education'])
          : Education(),
      selfIntroduction: json['selfIntroduction'] != null
          ? SelfIntroduction.fromJson(json['selfIntroduction'])
          : SelfIntroduction(),
    );
  }

  // 기존 호환성을 위해 fromMap 메소드 유지
  static ResumeModel fromMap(Map<String, dynamic> map) => fromJson(map);

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

  // Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'date': date,
      'score': score,
    };
  }

  // 기존 호환성을 위해 toMap 메소드 유지
  Map<String, dynamic> toMap() => toJson();

  // Map에서 객체 생성 (JSON 역직렬화)
  static Certificate fromJson(Map<String, dynamic> json) {
    return Certificate(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      date: json['date'] ?? '',
      score: json['score'] ?? '',
    );
  }

  // 기존 호환성을 위해 fromMap 메소드 유지
  static Certificate fromMap(Map<String, dynamic> map) => fromJson(map);
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

  // Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
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

  // 기존 호환성을 위해 toMap 메소드 유지
  Map<String, dynamic> toMap() => toJson();

  // Map에서 객체 생성 (JSON 역직렬화)
  static Education fromJson(Map<String, dynamic> json) {
    return Education(
      school: json['school'] ?? '',
      major: json['major'] ?? '',
      degree: json['degree'] ?? '학사',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      gpa: json['gpa'] ?? '',
      totalGpa: json['totalGpa'] ?? '4.5',
    );
  }

  // 기존 호환성을 위해 fromMap 메소드 유지
  static Education fromMap(Map<String, dynamic> map) => fromJson(map);
}

class SelfIntroduction {
  String? motivation;
  String? strength;

  SelfIntroduction({
    this.motivation,
    this.strength,
  });

  // Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
    return {
      'motivation': motivation,
      'strength': strength,
    };
  }

  // 기존 호환성을 위해 toMap 메소드 유지
  Map<String, dynamic> toMap() => toJson();

  // Map에서 객체 생성 (JSON 역직렬화)
  factory SelfIntroduction.fromJson(Map<String, dynamic> json) {
    return SelfIntroduction(
      motivation: json['motivation'],
      strength: json['strength'],
    );
  }

  // 기존 호환성을 위해 fromMap 메소드 유지
  factory SelfIntroduction.fromMap(Map<String, dynamic> map) {
    return SelfIntroduction.fromJson(map);
  }
}
