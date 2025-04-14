import 'package:http/http.dart' as http;
import '../models/resume_model.dart';

class ResumeService {
  // API 엔드포인트 (실제 서버 주소로 변경 필요)
  static const String baseUrl = 'https://your-api-server.com/api';

  // 이력서 저장
  Future<bool> saveResume(ResumeModel resume) async {
    try {
      // 실제 API 연동 시에는 아래 주석 해제
      // final response = await http.post(
      //   Uri.parse('$baseUrl/resumes'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(resume.toMap()),
      // );

      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   return true;
      // } else {
      //   throw Exception('Failed to save resume: ${response.statusCode}');
      // }

      // 테스트용 모의 데이터 - 저장 성공 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 800));
      print('서버에 저장된 이력서 데이터: ${resume.toMap()}');
      return true;
    } catch (e) {
      print('이력서 저장 중 오류 발생: $e');
      throw Exception('이력서를 저장하는데 실패했습니다: $e');
    }
  }

  // 이력서 조회
  Future<ResumeModel?> getResume(String userId) async {
    try {
      // 실제 API 연동 시에는 아래 주석 해제
      // final response = await http.get(Uri.parse('$baseUrl/resumes/$userId'));

      // if (response.statusCode == 200) {
      //   return ResumeModel.fromMap(json.decode(response.body));
      // } else if (response.statusCode == 404) {
      //   return null; // 이력서가 없는 경우
      // } else {
      //   throw Exception('Failed to load resume: ${response.statusCode}');
      // }

      // 테스트용 모의 데이터
      await Future.delayed(const Duration(milliseconds: 800));

      // 사용자 ID가 'test-user'일 경우 모의 데이터 반환
      if (userId == 'test-user') {
        return _getMockResume();
      }

      // 없는 경우 null 반환
      return null;
    } catch (e) {
      throw Exception('이력서를 불러오는데 실패했습니다: $e');
    }
  }

  // 모의 이력서 데이터 생성 (테스트용)
  ResumeModel _getMockResume() {
    return ResumeModel(
      field: '웹 개발',
      position: '백엔드 개발자',
      experience: '1~3년',
      interviewTypes: ['직무면접', '인성면접'],
      certificates: [
        Certificate(
          name: 'AWS 솔루션스 아키텍트 어소시에이트',
          issuer: 'Amazon Web Services',
          date: '2023-05-15',
          score: '합격',
        ),
        Certificate(
          name: '정보처리기사',
          issuer: '한국산업인력공단',
          date: '2022-08-20',
          score: '합격',
        ),
      ],
      education: Education(
        school: '서울대학교',
        major: '컴퓨터공학과',
        degree: '학사',
        startDate: '2018-03',
        endDate: '2022-02',
        gpa: '3.8',
        totalGpa: '4.5',
      ),
      selfIntroduction: SelfIntroduction(
        motivation: '어릴 때부터 프로그래밍에 관심이 많았고...',
        strength: '문제 해결 능력이 뛰어나며...',
      ),
    );
  }
}
