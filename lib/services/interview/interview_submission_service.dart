import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 면접 완료 후 서버로 영상을 전송하는 서비스
/// 영상 분석과 피드백을 받기 위해 서버에 보냅니다
class InterviewSubmissionService {
  // === 서버 주소 설정 ===
  // 로컬 개발 환경에서 테스트할 때는 'http://localhost:8000' 사용
  // 실제 배포 시에는 실제 서버 주소로 변경해주세요
  static const String _baseUrl = 'http://localhost:8000'; // 로컬 서버 기준

  // 예시: 실제 서버 주소
  // static const String _baseUrl = 'https://your-server-domain.com';

  /// === 서버 연결 테스트 ===
  /// 서버가 정상적으로 동작하는지 확인합니다
  Future<bool> testServerConnection() async {
    try {
      print('🔌 서버 연결 테스트 시작: $_baseUrl');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/docs'), // FastAPI docs 페이지 확인
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ 서버 연결 성공');
        return true;
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      print('💡 서버가 실행 중인지 확인해주세요: $_baseUrl');
      return false;
    }
  }

  /// === 포즈 분석 기능 ===
  /// 면접 영상을 서버로 보내서 포즈 분석 결과를 받습니다
  Future<PoseAnalysisResult> analyzePose({
    required Uint8List videoData,
    String fileName = 'interview_video.mp4',
  }) async {
    try {
      print('🎭 서버로 포즈 분석 요청 시작...');
      print(
          '  - 영상 파일 크기: ${(videoData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // === Multipart 요청 준비 ===
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/pose/analyze'),
      );

      // 영상 파일 추가
      final videoFile = http.MultipartFile.fromBytes(
        'file',
        videoData,
        filename: fileName,
      );
      request.files.add(videoFile);

      print('📡 서버로 포즈 분석 요청 전송 중...');

      // 요청 전송 (타임아웃 없음)
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('📡 서버 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ 포즈 분석 성공!');

        // 서버에서 텍스트 형태로 분석 결과를 반환 (안전한 UTF-8 인코딩 처리)
        final analysisText = _safeUtf8Decode(response.bodyBytes);

        print('📄 받은 분석 결과 길이: ${analysisText.length}자');

        return PoseAnalysisResult(
          success: true,
          analysisText: analysisText,
          message: '포즈 분석이 성공적으로 완료되었습니다.',
        );
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('  응답: ${response.body}');

        return PoseAnalysisResult(
          success: false,
          errorMessage: '포즈 분석 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ 포즈 분석 중 오류: $e');

      return PoseAnalysisResult(
        success: false,
        errorMessage: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// === 영상 기반 면접 평가 기능 ===
  /// 영상을 서버로 보내서 AI 평가를 받습니다
  Future<VideoEvaluationResult> evaluateVideoInterview({
    required Uint8List videoData,
    required List<String> questions, // 질문 목록
    String fileName = 'interview_video.mp4',
    String outputFileName = 'interview_evaluation.txt',
  }) async {
    try {
      print('🧠 서버로 영상 평가 요청 시작...');
      print(
          '  - 영상 파일 크기: ${(videoData.length / 1024 / 1024).toStringAsFixed(2)} MB');
      print('  - 질문 개수: ${questions.length}개');

      // === Multipart 요청 준비 ===
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/evaluate_interview'), // 올바른 엔드포인트 사용
      );

      // 질문들 추가 (FastAPI List[str] 형태로 전송)
      // HTTP spec에 따라 같은 이름의 필드를 여러 번 전송하여 배열 생성
      // 하지만 Flutter의 MultipartRequest는 Map 기반이라 마지막 값만 남음
      // 따라서 JSON 문자열로 변환하여 전송
      request.fields['questions'] = json.encode(questions);

      // 출력 파일명 추가
      request.fields['output_file'] = outputFileName;

      // 영상 파일 추가 (단일 파일용 파라미터명 사용)
      final videoFile = http.MultipartFile.fromBytes(
        'video_file', // 단일 파일용 파라미터명 (서버의 video_file: UploadFile)
        videoData,
        filename: fileName,
      );
      request.files.add(videoFile);

      print('📡 서버로 평가 요청 전송 중...');

      // 요청 전송 (타임아웃 없음)
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('📡 서버 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ 영상 평가 성공!');

        // 서버에서 텍스트 형태로 평가 결과를 반환 (안전한 UTF-8 인코딩 처리)
        final evaluationText = _safeUtf8Decode(response.bodyBytes);

        print('📄 받은 평가 결과 길이: ${evaluationText.length}자');

        return VideoEvaluationResult(
          success: true,
          evaluationText: evaluationText,
          message: 'AI 영상 평가가 성공적으로 완료되었습니다.',
        );
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('  응답: ${response.body}');

        return VideoEvaluationResult(
          success: false,
          errorMessage: '영상 평가 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ 영상 평가 중 오류: $e');

      return VideoEvaluationResult(
        success: false,
        errorMessage: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// === 통합 분석 기능 (포즈 + 평가) ===
  /// 하나의 영상으로 포즈 분석과 면접 평가를 모두 받습니다
  Future<CompleteAnalysisResult> getCompleteAnalysis({
    required Uint8List videoData,
    required List<String> questions,
    String fileName = 'interview_video.mp4',
  }) async {
    try {
      print('🔍 통합 분석 시작...');

      // 1. 포즈 분석
      final poseResult = await analyzePose(
        videoData: videoData,
        fileName: fileName,
      );

      // 2. 영상 평가
      final evaluationResult = await evaluateVideoInterview(
        videoData: videoData,
        questions: questions,
        fileName: fileName,
      );

      return CompleteAnalysisResult(
        success: poseResult.success && evaluationResult.success,
        poseAnalysis: poseResult.analysisText,
        evaluationResult: evaluationResult.evaluationText,
        poseError: poseResult.errorMessage,
        evaluationError: evaluationResult.errorMessage,
        message: '통합 분석이 완료되었습니다.',
      );
    } catch (e) {
      print('❌ 통합 분석 중 오류: $e');

      return CompleteAnalysisResult(
        success: false,
        errorMessage: '통합 분석 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// === URL 기반 통합 분석 ===
  /// Firebase Storage URL을 서버로 보내서 분석 결과를 받습니다
  Future<CompleteAnalysisResult> analyzeVideoFromUrl({
    required String videoUrl,
    required List<String> questions,
  }) async {
    try {
      print('🌐 URL 기반 통합 분석 시작...');
      print('  - 영상 URL: $videoUrl');
      print('  - 질문 개수: ${questions.length}개');

      // === Form 데이터 준비 ===
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze_complete_url'), // 새로운 URL 기반 엔드포인트
      );

      // 영상 URL 추가
      request.fields['video_url'] = videoUrl;

      // 질문들 추가 (JSON 문자열로 변환하여 전송)
      request.fields['questions'] = json.encode(questions);

      print('📡 서버로 URL 기반 분석 요청 전송 중...');

      // 요청 전송 (타임아웃 없음)
      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('📡 서버 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ URL 기반 통합 분석 성공!');

        // JSON 응답 파싱 (안전한 UTF-8 인코딩 처리)
        final responseText = _safeUtf8Decode(response.bodyBytes);
        final jsonResponse = json.decode(responseText);

        final rawPoseAnalysis = jsonResponse['poseAnalysis'] as String?;
        final evaluationResult = jsonResponse['evaluationResult'] as String?;

        print('📄 포즈 분석 원본 길이: ${rawPoseAnalysis?.length ?? 0}자');
        print('📄 평가 결과 길이: ${evaluationResult?.length ?? 0}자');

        // 포즈 분석 결과 정리
        final cleanedPoseAnalysis = _cleanPoseAnalysis(rawPoseAnalysis);
        print('📄 포즈 분석 정리 후 길이: ${cleanedPoseAnalysis.length}자');

        return CompleteAnalysisResult(
          success: true,
          poseAnalysis: cleanedPoseAnalysis,
          evaluationResult: evaluationResult,
          message: '통합 분석이 성공적으로 완료되었습니다.',
        );
      } else {
        print('❌ 서버 오류: ${response.statusCode}');
        print('  응답: ${response.body}');

        return CompleteAnalysisResult(
          success: false,
          errorMessage: 'URL 기반 분석 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ URL 기반 분석 중 오류: $e');

      return CompleteAnalysisResult(
        success: false,
        errorMessage: '네트워크 오류가 발생했습니다: $e',
      );
    }
  }

  /// === getCompleteAnalysisFromUrl 별칭 (하위 호환성) ===
  Future<CompleteAnalysisResult> getCompleteAnalysisFromUrl({
    required String videoUrl,
    required List<String> questions,
  }) async {
    return analyzeVideoFromUrl(videoUrl: videoUrl, questions: questions);
  }

  /// 안전한 UTF-8 디코딩 (잘못된 문자 처리)
  String _safeUtf8Decode(List<int> bytes) {
    try {
      // 기본 UTF-8 디코딩 시도
      final decoded = utf8.decode(bytes, allowMalformed: true);

      // 잘못된 문자들 정리
      return _cleanServerResponse(decoded);
    } catch (e) {
      print('⚠️ UTF-8 디코딩 실패, 대안 처리: $e');

      // 대안: Latin-1로 디코딩 후 UTF-8로 재변환 시도
      try {
        final latin1Decoded = latin1.decode(bytes);
        return _cleanServerResponse(latin1Decoded);
      } catch (e2) {
        print('⚠️ 모든 디코딩 실패: $e2');
        return '서버 응답 인코딩 오류';
      }
    }
  }

  /// 서버 응답 문자열 정리
  String _cleanServerResponse(String input) {
    try {
      // 1. Replacement character (�) 제거
      String cleaned = input.replaceAll('�', '');

      // 2. 제어 문자 제거 (개행과 탭은 유지)
      cleaned =
          cleaned.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

      // 3. 다양한 점 문자들을 공백으로 변경
      cleaned = cleaned.replaceAll(RegExp(r'[·․‧∙•]'), ' ');

      // 4. 연속된 공백 정리 (개행은 유지)
      cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

      // 5. 반복되는 "테스트입니다" 패턴 제거
      cleaned = _removeRepeatedTestPatterns(cleaned);

      // 6. 빈 문자열 체크
      return cleaned.trim().isEmpty ? '빈 응답' : cleaned;
    } catch (e) {
      print('⚠️ 서버 응답 정리 중 오류: $e');
      return '응답 처리 오류';
    }
  }

  /// 포즈 분석 결과를 더 읽기 쉽게 정리
  String _cleanPoseAnalysis(String? poseAnalysis) {
    if (poseAnalysis == null || poseAnalysis.isEmpty) {
      return '포즈 분석 데이터가 없습니다.';
    }

    try {
      final lines = poseAnalysis.split('\n');
      final cleanedLines = <String>[];
      bool inSummarySection = false;

      for (final line in lines) {
        final trimmed = line.trim();

        // 빈 줄 건너뛰기
        if (trimmed.isEmpty) continue;

        // 요약 섹션 시작 감지
        if (trimmed.contains('--- 분석 결과 요약 ---')) {
          inSummarySection = true;
          cleanedLines.add('📊 포즈 분석 요약');
          cleanedLines.add('');
          continue;
        }

        // 요약 섹션에서 내용 정리
        if (inSummarySection) {
          if (trimmed.startsWith('[자세 문제점별')) {
            cleanedLines.add('🚨 자세 문제점:');
          } else if (trimmed.startsWith('- ') && trimmed.contains('회')) {
            // "- 고개가 옆으로 기울어져 있습니다.: 77회 (5.13초)" 형태 정리
            final problemText = trimmed.substring(2);
            cleanedLines.add('  • $problemText');
          } else if (trimmed.startsWith('[시선 분석]')) {
            cleanedLines.add('');
            cleanedLines.add('👁️ 시선 분석:');
          } else if (trimmed.startsWith('- 시선:')) {
            // "- 시선: 아래쪽: 74프레임 (100.0%)" 형태 정리
            final gazeText = trimmed.substring(2);
            cleanedLines.add('  • $gazeText');
          } else if (trimmed.startsWith('[총 영상 길이]')) {
            cleanedLines.add('');
            cleanedLines.add('⏱️ $trimmed');
          } else if (trimmed.contains('분석된 총 프레임:')) {
            cleanedLines.add('  • $trimmed');
          } else if (trimmed.startsWith('주요 시선 방향:')) {
            cleanedLines.add('  • $trimmed');
          } else if (trimmed.startsWith('- 총 프레임') ||
              trimmed.startsWith('- 유효 분석') ||
              trimmed.startsWith('- 분석 성공률') ||
              trimmed.startsWith('- FPS:') ||
              trimmed.startsWith('- 해상도:')) {
            cleanedLines.add('  • $trimmed');
          }
        } else {
          // 세부 분석 로그는 개수만 요약
          if (trimmed.contains('sec:')) {
            // 세부 로그가 있다는 것을 표시하지만 모든 내용을 저장하지는 않음
            if (!cleanedLines.contains('📝 세부 분석 로그 기록됨 (프레임별 문제점 감지)')) {
              cleanedLines.insert(0, '📝 세부 분석 로그 기록됨 (프레임별 문제점 감지)');
              cleanedLines.insert(1, '');
            }
          }
        }
      }

      // 분석 결과가 너무 빈약한 경우 안내 메시지 추가
      if (cleanedLines.length < 5) {
        cleanedLines.clear();
        cleanedLines.addAll([
          '⚠️ 포즈 분석 결과가 제한적입니다.',
          '',
          '가능한 원인:',
          '• 얼굴이나 상체가 화면에 충분히 보이지 않음',
          '• 조명이 어둡거나 영상 화질이 낮음',
          '• 카메라 각도가 부적절함',
          '',
          '💡 개선 방법:',
          '• 얼굴과 상체가 잘 보이도록 카메라 위치 조정',
          '• 충분한 조명 확보',
          '• 정면을 바라보고 면접 진행',
        ]);
      }

      return cleanedLines.join('\n');
    } catch (e) {
      print('⚠️ 포즈 분석 정리 중 오류: $e');
      return '포즈 분석 결과 처리 중 오류가 발생했습니다: $poseAnalysis';
    }
  }

  /// 반복되는 "테스트입니다" 패턴 제거
  String _removeRepeatedTestPatterns(String input) {
    try {
      String result = input;

      // "테스트입니다" 반복 패턴 제거
      final patterns = [
        RegExp(r'(테스트입니다[\s]*){2,}'),
        RegExp(r'(테스트[\s]*){3,}'),
        RegExp(r'(입니다[\s]*){4,}'),
        RegExp(r'(합니다[\s]*){4,}'),
      ];

      for (final pattern in patterns) {
        result = result.replaceAll(pattern, '테스트입니다 ');
      }

      // 전체 텍스트의 90% 이상이 같은 패턴이면 한 번만 남기기
      if (result.contains('테스트입니다')) {
        final testCount = RegExp(r'테스트입니다').allMatches(result).length;
        final totalLength = result.length;
        final testLength = testCount * '테스트입니다'.length;

        if (testLength > totalLength * 0.7) {
          print('⚠️ 과도한 "테스트입니다" 반복 감지, 단순화 적용');
          result = '테스트입니다.';
        }
      }

      return result;
    } catch (e) {
      print('⚠️ 테스트 패턴 제거 중 오류: $e');
      return input;
    }
  }
}

/// === 결과 클래스들 ===

/// 포즈 분석 결과
class PoseAnalysisResult {
  final bool success;
  final String? analysisText;
  final String? message;
  final String? errorMessage;

  PoseAnalysisResult({
    required this.success,
    this.analysisText,
    this.message,
    this.errorMessage,
  });
}

/// 영상 평가 결과
class VideoEvaluationResult {
  final bool success;
  final String? evaluationText;
  final String? message;
  final String? errorMessage;

  VideoEvaluationResult({
    required this.success,
    this.evaluationText,
    this.message,
    this.errorMessage,
  });
}

/// 통합 분석 결과
class CompleteAnalysisResult {
  final bool success;
  final String? poseAnalysis;
  final String? evaluationResult;
  final String? poseError;
  final String? evaluationError;
  final String? message;
  final String? errorMessage;

  CompleteAnalysisResult({
    required this.success,
    this.poseAnalysis,
    this.evaluationResult,
    this.poseError,
    this.evaluationError,
    this.message,
    this.errorMessage,
  });
}
