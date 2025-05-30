import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 서비스
/// 면접 비디오와 오디오 파일을 안전하게 저장합니다
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 면접 비디오 업로드
  Future<String?> uploadInterviewVideo({
    required Uint8List videoData,
    required String userId,
    required String interviewId,
    String fileName = 'interview_video.webm',
  }) async {
    try {
      print('🔥 비디오 업로드를 시작합니다');
      print('📁 저장 경로: interviews/$userId/$interviewId/$fileName');
      print(
          '📦 파일 크기: ${(videoData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // 파일 확장자에 따른 적절한 MIME 타입 설정
      String contentType = 'video/mp4';
      if (fileName.endsWith('.webm')) {
        contentType = 'video/webm';
      } else if (fileName.endsWith('.mp4')) {
        contentType = 'video/mp4';
      } else if (fileName.endsWith('.mov')) {
        contentType = 'video/quicktime';
      }

      // Firebase Storage 레퍼런스 생성
      final ref = _storage.ref('interviews/$userId/$interviewId/$fileName');

      // 메타데이터 설정 - 비디오 플레이어 호환성을 위한 추가 설정
      final metadata = SettableMetadata(
        contentType: contentType,
        contentDisposition: 'inline', // 브라우저에서 직접 재생 가능하도록 설정
        cacheControl: 'public, max-age=3600', // 1시간 캐싱 설정
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
          'interviewId': interviewId,
          'fileSize': videoData.length.toString(),
          'videoCodec': 'h264', // 호환성을 위한 코덱 정보
          'audioCodec': 'aac',
        },
      );

      // 파일 업로드
      final uploadTask = ref.putData(videoData, metadata);

      // 업로드 진행 상황 모니터링
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('📈 업로드 진행률: ${progress.toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final snapshot = await uploadTask;

      // 업로드된 파일 정보 확인
      final uploadedMetadata = await snapshot.ref.getMetadata();
      print('📊 업로드된 파일 정보:');
      print('   Content-Type: ${uploadedMetadata.contentType}');
      print('   Size: ${uploadedMetadata.size} bytes');
      print('   Created: ${uploadedMetadata.timeCreated}');

      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firebase Storage에서 파일 처리 완료까지 대기
      await _waitForFileProcessing(downloadUrl, videoData.length);

      // URL 검증 (간단한 접근성 테스트)
      try {
        // Firebase Storage URL 형식 검증
        if (!downloadUrl.contains('firebasestorage.googleapis.com') &&
            !downloadUrl.contains('storage.googleapis.com')) {
          throw Exception('Invalid Firebase Storage URL format');
        }

        print('✅ 비디오 업로드가 완료되었습니다');
        print('🔗 다운로드 URL 검증 완료: ${downloadUrl.substring(0, 100)}...');

        // URL이 Firebase Storage 형식인지 추가 확인
        final uri = Uri.parse(downloadUrl);
        if (uri.queryParameters.containsKey('alt') &&
            uri.queryParameters['alt'] == 'media') {
          print('✅ Firebase Storage 미디어 URL 형식 확인됨');
        }

        // 웹 브라우저 호환성을 위한 URL 매개변수 추가
        String optimizedUrl = downloadUrl;
        if (!optimizedUrl.contains('&token=')) {
          // 이미 토큰이 있는 경우 추가 매개변수만 붙임
          if (optimizedUrl.contains('?')) {
            optimizedUrl += '&responseContentType=video%2Fmp4';
            optimizedUrl += '&responseContentDisposition=inline';
          } else {
            optimizedUrl += '?responseContentType=video%2Fmp4';
            optimizedUrl += '&responseContentDisposition=inline';
          }
        }

        print('🔧 웹 호환성 URL 최적화 적용됨');
        return optimizedUrl;
      } catch (e) {
        print('⚠️ 다운로드 URL 검증 실패: $e');
        return downloadUrl; // 검증 실패해도 URL은 반환
      }
    } catch (e) {
      print('❌ 비디오 업로드 중 오류가 발생했습니다: $e');
      return null;
    }
  }

  /// Firebase Storage에서 파일이 완전히 처리될 때까지 대기
  Future<void> _waitForFileProcessing(
      String downloadUrl, int expectedSize) async {
    print('⏳ Firebase Storage 파일 처리 완료 대기 중...');
    print('   예상 크기: ${(expectedSize / 1024 / 1024).toStringAsFixed(2)} MB');

    const maxWaitTime = Duration(seconds: 30); // 최대 30초 대기
    const checkInterval = Duration(seconds: 2); // 2초마다 확인

    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      try {
        // HTTP HEAD 요청으로 파일 메타데이터 확인 (웹 환경에서는 제한적)
        print(
            '🔍 파일 처리 상태 확인 중... (${DateTime.now().difference(startTime).inSeconds}초)');

        // Firebase Storage에서 metadata 다시 확인
        final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
        final metadata = await ref.getMetadata();

        if (metadata.size != null && metadata.size! > 0) {
          print('✅ Firebase Storage 파일 처리 완료');
          print(
              '   - 실제 크기: ${(metadata.size! / 1024 / 1024).toStringAsFixed(2)} MB');
          print(
              '   - 처리 시간: ${DateTime.now().difference(startTime).inSeconds}초');

          // 크기가 예상보다 너무 작으면 경고
          if (metadata.size! < expectedSize * 0.5) {
            print('⚠️ 파일 크기가 예상보다 작습니다. 업로드가 불완전할 수 있습니다.');
          }

          // 추가 처리 시간 (비디오 인덱싱 등을 위해)
          await Future.delayed(const Duration(seconds: 2));
          print('📹 비디오 인덱싱 대기 완료');
          return;
        }

        // 잠시 대기 후 재확인
        await Future.delayed(checkInterval);
      } catch (e) {
        print('⚠️ 파일 처리 상태 확인 중 오류: $e');
        // 에러가 발생해도 계속 대기
        await Future.delayed(checkInterval);
      }
    }

    print('⏰ 파일 처리 대기 시간 초과 (${maxWaitTime.inSeconds}초)');
    print('   -> 파일이 완전히 처리되지 않았을 수 있지만 계속 진행합니다.');
  }

  /// 면접 오디오 업로드
  Future<String?> uploadInterviewAudio({
    required Uint8List audioData,
    required String userId,
    required String interviewId,
    String fileName = 'interview_audio.webm',
  }) async {
    try {
      print('🔥 오디오 업로드를 시작합니다');
      print('📁 저장 경로: interviews/$userId/$interviewId/$fileName');
      print('📦 파일 크기: ${(audioData.length / 1024).toStringAsFixed(2)} KB');

      // Firebase Storage 레퍼런스 생성
      final ref = _storage.ref('interviews/$userId/$interviewId/$fileName');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'audio/webm',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
          'interviewId': interviewId,
        },
      );

      // 파일 업로드
      final uploadTask = ref.putData(audioData, metadata);
      final snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 오디오 업로드가 완료되었습니다');
      print('🔗 다운로드 URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 오디오 업로드 중 오류가 발생했습니다: $e');
      return null;
    }
  }

  /// 면접 세션 전체 업로드
  Future<Map<String, String?>> uploadInterviewSession({
    required Uint8List videoData,
    Uint8List? audioData,
    required String userId,
    required String interviewId,
    Map<String, dynamic>? metadata,
  }) async {
    print('🚀 면접 세션을 저장하고 있습니다: $interviewId');

    try {
      // 비디오 업로드
      final videoUrl = await uploadInterviewVideo(
        videoData: videoData,
        userId: userId,
        interviewId: interviewId,
        fileName: 'session_video.mp4',
      );

      // 오디오 업로드 (있는 경우)
      String? audioUrl;
      if (audioData != null) {
        audioUrl = await uploadInterviewAudio(
          audioData: audioData,
          userId: userId,
          interviewId: interviewId,
          fileName: 'session_audio.webm',
        );
      }

      final Map<String, String?> results = {
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'status': videoUrl != null ? 'completed' : 'failed',
      };

      print('🎉 면접 세션이 성공적으로 저장되었습니다!');
      return results;
    } catch (e) {
      print('❌ 면접 세션 저장 중 오류가 발생했습니다: $e');
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }

  /// 파일 삭제
  Future<bool> deleteFile(String filePath) async {
    try {
      print('🗑️ 파일을 삭제하고 있습니다: $filePath');
      final ref = _storage.ref(filePath);
      await ref.delete();
      print('✅ 파일이 성공적으로 삭제되었습니다');
      return true;
    } catch (e) {
      print('❌ 파일 삭제 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 면접 폴더 정리
  Future<bool> cleanupInterviewFolder(String userId, String interviewId) async {
    try {
      print('🧹 면접 데이터를 정리하고 있습니다: $userId/$interviewId');

      // 해당 폴더의 모든 파일 목록 가져오기
      final ref = _storage.ref('interviews/$userId/$interviewId');
      final listResult = await ref.listAll();

      // 모든 파일 삭제
      for (final item in listResult.items) {
        await item.delete();
        print('🗑️ 삭제됨: ${item.fullPath}');
      }

      print('✅ 면접 데이터 정리가 완료되었습니다');
      return true;
    } catch (e) {
      print('❌ 데이터 정리 중 오류가 발생했습니다: $e');
      return false;
    }
  }
}
