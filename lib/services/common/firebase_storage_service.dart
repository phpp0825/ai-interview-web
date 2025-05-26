import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage를 사용한 파일 업로드 서비스
/// 면접 비디오/오디오 파일을 Firebase Storage에 저장하고 보고서에서 참조할 수 있도록 합니다
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 면접 비디오 파일 업로드
  /// [videoData] - 비디오 파일 바이트 데이터
  /// [userId] - 사용자 ID (폴더 구분용)
  /// [interviewId] - 면접 세션 ID
  /// [fileName] - 파일명 (기본값: interview_video.webm)
  Future<String?> uploadInterviewVideo({
    required Uint8List videoData,
    required String userId,
    required String interviewId,
    String fileName = 'interview_video.webm',
  }) async {
    try {
      print('🔥 Firebase Storage: 비디오 업로드 시작');
      print('📁 경로: interviews/$userId/$interviewId/$fileName');
      print(
          '📦 파일 크기: ${(videoData.length / 1024 / 1024).toStringAsFixed(2)} MB');

      // 파일 경로 설정: interviews/userId/interviewId/video_filename
      final String filePath = 'interviews/$userId/$interviewId/$fileName';
      final Reference ref = _storage.ref().child(filePath);

      // 메타데이터 설정
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'video/webm',
        customMetadata: {
          'uploadedBy': userId,
          'interviewId': interviewId,
          'uploadTime': DateTime.now().toIso8601String(),
          'fileType': 'interview_video',
        },
      );

      // 파일 업로드
      final UploadTask uploadTask = ref.putData(videoData, metadata);

      // 업로드 진행률 모니터링
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 업로드 진행률: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 업로드 완료 대기
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // 다운로드 URL 획득
        final String downloadUrl = await ref.getDownloadURL();
        print('✅ 비디오 업로드 성공!');
        print('🔗 다운로드 URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('❌ 비디오 업로드 실패: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      print('💥 비디오 업로드 오류: $e');
      return null;
    }
  }

  /// 면접 오디오 파일 업로드
  /// [audioData] - 오디오 파일 바이트 데이터
  /// [userId] - 사용자 ID
  /// [interviewId] - 면접 세션 ID
  /// [fileName] - 파일명 (기본값: interview_audio.webm)
  Future<String?> uploadInterviewAudio({
    required Uint8List audioData,
    required String userId,
    required String interviewId,
    String fileName = 'interview_audio.webm',
  }) async {
    try {
      print('🔥 Firebase Storage: 오디오 업로드 시작');
      print('📁 경로: interviews/$userId/$interviewId/$fileName');
      print('📦 파일 크기: ${(audioData.length / 1024).toStringAsFixed(2)} KB');

      // 파일 경로 설정
      final String filePath = 'interviews/$userId/$interviewId/$fileName';
      final Reference ref = _storage.ref().child(filePath);

      // 메타데이터 설정
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'audio/webm',
        customMetadata: {
          'uploadedBy': userId,
          'interviewId': interviewId,
          'uploadTime': DateTime.now().toIso8601String(),
          'fileType': 'interview_audio',
        },
      );

      // 파일 업로드
      final UploadTask uploadTask = ref.putData(audioData, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await ref.getDownloadURL();
        print('✅ 오디오 업로드 성공!');
        print('🔗 다운로드 URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('❌ 오디오 업로드 실패: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      print('💥 오디오 업로드 오류: $e');
      return null;
    }
  }

  /// 면접 전체 세션 데이터 업로드 (비디오 + 오디오 + 메타데이터)
  /// [videoData] - 비디오 파일 데이터
  /// [audioData] - 오디오 파일 데이터 (선택사항)
  /// [userId] - 사용자 ID
  /// [interviewId] - 면접 세션 ID
  /// [metadata] - 추가 메타데이터 (질문, 답변 등)
  Future<Map<String, String?>> uploadInterviewSession({
    required Uint8List videoData,
    Uint8List? audioData,
    required String userId,
    required String interviewId,
    Map<String, dynamic>? metadata,
  }) async {
    print('🚀 면접 세션 전체 업로드 시작: $interviewId');

    final Map<String, String?> results = {
      'videoUrl': null,
      'audioUrl': null,
      'status': 'uploading',
    };

    try {
      // 1. 비디오 업로드
      final String? videoUrl = await uploadInterviewVideo(
        videoData: videoData,
        userId: userId,
        interviewId: interviewId,
      );
      results['videoUrl'] = videoUrl;

      // 2. 오디오 업로드 (있는 경우)
      if (audioData != null) {
        final String? audioUrl = await uploadInterviewAudio(
          audioData: audioData,
          userId: userId,
          interviewId: interviewId,
        );
        results['audioUrl'] = audioUrl;
      }

      // 3. 메타데이터 JSON 파일 업로드 (있는 경우)
      if (metadata != null) {
        await _uploadMetadata(
          metadata: metadata,
          userId: userId,
          interviewId: interviewId,
        );
      }

      results['status'] = 'completed';
      print('🎉 면접 세션 업로드 완료!');
    } catch (e) {
      results['status'] = 'failed';
      print('💥 면접 세션 업로드 실패: $e');
    }

    return results;
  }

  /// 메타데이터 JSON 파일 업로드
  Future<String?> _uploadMetadata({
    required Map<String, dynamic> metadata,
    required String userId,
    required String interviewId,
  }) async {
    try {
      // JSON 문자열로 변환
      final String jsonString = '''
{
  "interviewId": "$interviewId",
  "userId": "$userId",
  "uploadTime": "${DateTime.now().toIso8601String()}",
  "questions": ${metadata['questions'] ?? '[]'},
  "answers": ${metadata['answers'] ?? '[]'},
  "scores": ${metadata['scores'] ?? '{}'},
  "feedback": ${metadata['feedback'] ?? '[]'}
}''';

      final Uint8List jsonData = Uint8List.fromList(jsonString.codeUnits);

      // 메타데이터 파일 업로드
      final String filePath = 'interviews/$userId/$interviewId/metadata.json';
      final Reference ref = _storage.ref().child(filePath);

      final SettableMetadata fileMetadata = SettableMetadata(
        contentType: 'application/json',
        customMetadata: {
          'uploadedBy': userId,
          'interviewId': interviewId,
          'uploadTime': DateTime.now().toIso8601String(),
          'fileType': 'interview_metadata',
        },
      );

      final UploadTask uploadTask = ref.putData(jsonData, fileMetadata);
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await ref.getDownloadURL();
        print('✅ 메타데이터 업로드 성공: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      print('💥 메타데이터 업로드 오류: $e');
    }
    return null;
  }

  /// 특정 면접 세션의 파일들 삭제
  Future<bool> deleteInterviewSession({
    required String userId,
    required String interviewId,
  }) async {
    try {
      print('🗑️ 면접 세션 삭제: interviews/$userId/$interviewId/');

      final Reference folderRef =
          _storage.ref().child('interviews/$userId/$interviewId/');
      final ListResult result = await folderRef.listAll();

      // 폴더 내 모든 파일 삭제
      for (Reference file in result.items) {
        await file.delete();
        print('✅ 파일 삭제됨: ${file.name}');
      }

      print('🎉 면접 세션 삭제 완료!');
      return true;
    } catch (e) {
      print('💥 면접 세션 삭제 실패: $e');
      return false;
    }
  }

  /// 사용자의 모든 면접 세션 목록 조회
  Future<List<String>> getUserInterviewSessions(String userId) async {
    try {
      final Reference userRef = _storage.ref().child('interviews/$userId/');
      final ListResult result = await userRef.listAll();

      final List<String> sessionIds =
          result.prefixes.map((prefix) => prefix.name).toList();

      print('📋 사용자 $userId의 면접 세션: $sessionIds');
      return sessionIds;
    } catch (e) {
      print('💥 면접 세션 목록 조회 실패: $e');
      return [];
    }
  }
}
