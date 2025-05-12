import 'package:flutter/material.dart';
import '../models/resume_model.dart';
import '../services/resume_service.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeController extends ChangeNotifier {
  // 의존성
  final ResumeService _resumeService = ResumeService();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 모델
  final ResumeModel _model = ResumeModel();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // 상태 변수
  bool _isLoading = false;
  String? _error;
  bool _isLoadingFromServer = false;
  bool _resumeExistsOnServer = false;

  // Getters
  String get field => _model.field;
  String get position => _model.position;
  String get experience => _model.experience;
  List<String> get interviewTypes => _model.interviewTypes;
  List<Certificate> get certificates => _model.certificates;
  Education get education => _model.education;
  SelfIntroduction get selfIntroduction => _model.selfIntroduction;
  bool get hasPersonalityInterview => _model.hasPersonalityInterview;
  bool get isPersonalityInterviewSelected =>
      _model.interviewTypes.contains('인성면접');
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingFromServer => _isLoadingFromServer;
  bool get resumeExistsOnServer => _resumeExistsOnServer;

  // 자기소개서 필드 getter
  String? get selfIntroductionMotivation => _model.selfIntroduction.motivation;
  String? get selfIntroductionStrength => _model.selfIntroduction.strength;

  // 필드 데이터 목록
  final List<String> fields = [
    '웹 개발',
    '모바일 앱 개발',
    '게임 개발',
    '클라우드/인프라',
    '시스템 소프트웨어',
    '데이터 엔지니어링',
    'AI/ML',
    '보안',
    'DevOps',
    '임베디드 시스템',
    '블록체인',
    'AR/VR 개발',
    '기타'
  ];

  // 직무 목록
  final List<String> positions = [
    '프론트엔드 개발자',
    '백엔드 개발자',
    '풀스택 개발자',
    '모바일 앱 개발자',
    '게임 개발자',
    '시스템 프로그래머',
    'DevOps/SRE 엔지니어',
    '클라우드 엔지니어',
    '데이터 엔지니어/사이언티스트',
    'AI/ML 엔지니어',
    '보안 엔지니어',
    '임베디드 개발자',
    '블록체인 개발자',
    'AR/VR 개발자',
    'QA/테스트 엔지니어',
    '기타'
  ];

  // 경력 목록
  final List<String> experiences = ['신입', '1~3년', '4~7년', '8~10년', '10년 이상'];

  // 면접 유형 목록
  final List<String> interviewTypeOptions = ['직무면접', '인성면접'];

  // 학위 목록
  final List<String> degrees = ['학사', '석사', '박사'];

  // 학점 만점 목록
  final List<String> totalGpas = ['4.0', '4.3', '4.5'];

  // 초기화
  ResumeController() {
    // 이력서 생성 모드만 사용하므로 초기화 시 기존 데이터를 로드하지 않음
  }

  // 이력서 초기화 - 서버에서 데이터 조회 시도 (사용하지 않음)
  Future<void> _initializeResume() async {
    // 사용하지 않음
  }

  // 서버에서 이력서 불러오기 (사용하지 않음)
  Future<void> loadResumeFromServer(String userId) async {
    // 사용하지 않음
  }

  // 필드 값 업데이트
  void updateField(String value) {
    _model.field = value;
    notifyListeners();
  }

  // 직무 값 업데이트
  void updatePosition(String value) {
    _model.position = value;
    notifyListeners();
  }

  // 경력 값 업데이트
  void updateExperience(String value) {
    _model.experience = value;
    notifyListeners();
  }

  // 면접 유형 업데이트
  void updateInterviewType(String type, bool? isSelected) {
    if (isSelected == true) {
      if (!_model.interviewTypes.contains(type)) {
        _model.interviewTypes.add(type);
      }
    } else {
      _model.interviewTypes.remove(type);
    }
    notifyListeners();
  }

  // 학력 정보 업데이트
  void updateEducation(String field, String value) {
    switch (field) {
      case 'school':
        _model.education.school = value;
        break;
      case 'major':
        _model.education.major = value;
        break;
      case 'degree':
        _model.education.degree = value;
        break;
      case 'startDate':
        _model.education.startDate = value;
        break;
      case 'endDate':
        _model.education.endDate = value;
        break;
      case 'gpa':
        _model.education.gpa = value;
        break;
      case 'totalGpa':
        _model.education.totalGpa = value;
        break;
    }
    notifyListeners();
  }

  // 자격증 추가
  void addCertificate() {
    _model.certificates.add(Certificate());
    notifyListeners();
  }

  // 자격증 제거
  void removeCertificate(int index) {
    if (index >= 0 && index < _model.certificates.length) {
      _model.certificates.removeAt(index);
      notifyListeners();
    }
  }

  // 자격증 정보 업데이트
  void updateCertificate(int index, String field, String value) {
    if (index >= 0 && index < _model.certificates.length) {
      final certificate = _model.certificates[index];
      switch (field) {
        case 'name':
          certificate.name = value;
          break;
        case 'issuer':
          certificate.issuer = value;
          break;
        case 'date':
          certificate.date = value;
          break;
        case 'score':
          certificate.score = value;
          break;
      }
      notifyListeners();
    }
  }

  // 자기소개서 업데이트
  void updateSelfIntroduction(String field, String value) {
    switch (field) {
      case 'motivation':
        _model.selfIntroduction = SelfIntroduction(
          motivation: value,
          strength: _model.selfIntroduction.strength,
        );
        break;
      case 'strength':
        _model.selfIntroduction = SelfIntroduction(
          motivation: _model.selfIntroduction.motivation,
          strength: value,
        );
        break;
    }
    notifyListeners();
  }

  // 자기소개서 개별 필드 업데이트 메서드
  void updateSelfIntroductionMotivation(String value) {
    _model.selfIntroduction = SelfIntroduction(
      motivation: value,
      strength: _model.selfIntroduction.strength,
    );
    notifyListeners();
  }

  void updateSelfIntroductionStrength(String value) {
    _model.selfIntroduction = SelfIntroduction(
      motivation: _model.selfIntroduction.motivation,
      strength: value,
    );
    notifyListeners();
  }

  // 이력서 저장
  Future<bool> saveResume() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      // 이력서 데이터를 Firestore에 저장하는 서비스 메서드 호출
      return await _resumeService.saveResumeToFirestore(_model);
    } catch (e) {
      print('이력서 저장 중 오류 발생: $e');
      return false;
    }
  }

  // 이력서 정보로 리포트 생성
  Future<String?> createReportWithResume() async {
    try {
      setLoading(true);

      // ResumeService를 통해 이력서 정보로 리포트 생성
      final String reportId =
          await _resumeService.createReportWithResume(_model);

      setLoading(false);
      return reportId;
    } catch (e) {
      _setError('리포트를 생성하는데 실패했습니다: $e');
      setLoading(false);
      return null;
    }
  }

  // 폼 검증 및 저장 처리
  Future<bool> submitForm() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      // Firestore에 저장
      return await saveResume();
    }
    return false;
  }

  // 리셋 메서드
  void resetForm() {
    _model.field = '웹 개발';
    _model.position = '백엔드 개발자';
    _model.experience = '신입';
    _model.interviewTypes = ['직무면접'];
    _model.certificates = [];
    _model.education = Education();
    _model.selfIntroduction = SelfIntroduction();
    notifyListeners();
  }

  // 로딩 상태 설정
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 오류 상태 설정
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // 현재 이력서 모델 조회
  ResumeModel getCurrentResume() {
    return ResumeModel(
      field: field,
      position: position,
      experience: experience,
      interviewTypes: interviewTypes,
      certificates: certificates,
      education: education,
      selfIntroduction: hasPersonalityInterview
          ? SelfIntroduction(
              motivation: selfIntroduction.motivation,
              strength: selfIntroduction.strength,
            )
          : null,
    );
  }
}
