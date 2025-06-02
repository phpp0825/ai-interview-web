import 'dart:convert';
import 'package:http/http.dart' as http;

/// 면접 완료 후 서버로 영상을 전송하는 서비스
/// 리포트에 저장된 면접 영상들을 서버에 보냅니다
class InterviewSubmissionService {
  // 서버 주소 (실제 서버 주소로 변경해주세요)
  static const String _baseUrl = 'https://your-api-server.com/api';

  /// 면접 영상들을 서버로 전송
  /// 간단하게 영상 URL들만 보냅니다
  Future<InterviewSubmissionResult> submitInterviewVideos({
    required List<String> videoUrls,
    required String userId,
    required String interviewId,
  }) async {
    try {
      print('📤 서버로 면접 영상 전송 시작...');
      print('  - 영상 개수: ${videoUrls.length}개');
      print('  - 면접 ID: $interviewId');

      // 서버로 보낼 데이터 준비 (간단하게)
      final requestData = {
        'interview_id': interviewId,
        'user_id': userId,
        'video_urls': videoUrls,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // HTTP 요청 전송
      final response = await http
          .post(
            Uri.parse('$_baseUrl/interview/videos'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer your-auth-token', // 실제 인증 토큰으로 변경
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(minutes: 3)); // 3분 타임아웃

      print('📡 서버 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        print('✅ 영상 전송 성공!');
        print('  - 처리 ID: ${responseData['process_id'] ?? 'N/A'}');

        return InterviewSubmissionResult(
          success: true,
          processId: responseData['process_id'],
          message: '면접 영상이 성공적으로 전송되었습니다.',
        );
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('  응답: ${response.body}');

        return InterviewSubmissionResult(
          success: false,
          errorMessage: '서버 전송 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ 영상 전송 중 오류: $e');

      return InterviewSubmissionResult(
        success: false,
        errorMessage: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }
}

/// 면접 영상 전송 결과
class InterviewSubmissionResult {
  final bool success;
  final String? processId;
  final String? message;
  final String? errorMessage;

  InterviewSubmissionResult({
    required this.success,
    this.processId,
    this.message,
    this.errorMessage,
  });
}
