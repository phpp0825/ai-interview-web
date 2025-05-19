import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 미디어 서비스 인터페이스
///
/// 비디오 및 오디오 스트리밍 관련 기능을 제공하는 서비스의 인터페이스입니다.
abstract class IMediaService {
  /// 마지막으로 캡처된 비디오 프레임
  Uint8List? get lastCapturedVideoFrame;

  /// 마지막으로 캡처된 오디오 데이터
  Uint8List? get lastCapturedAudioData;

  /// 서버 연결
  ///
  /// [serverUrl]에 연결합니다.
  Future<bool> connect(String serverUrl);

  /// 서버 연결 해제
  Future<void> disconnect();

  /// 비디오 스트리밍 시작
  Future<bool> startVideoStreaming();

  /// 비디오 스트리밍 중지
  void stopVideoStreaming();

  /// 오디오 스트리밍 시작
  Future<bool> startAudioStreaming();

  /// 오디오 스트리밍 중지
  void stopAudioStreaming();

  /// 비디오 프레임 콜백 설정
  ///
  /// 비디오 프레임을 캡처하는 함수를 설정합니다.
  void setVideoFrameCallback(Future<Uint8List?> Function() callback);

  /// 오디오 데이터 콜백 설정
  ///
  /// 오디오 데이터를 캡처하는 함수를 설정합니다.
  void setAudioDataCallback(Future<Uint8List?> Function() callback);

  /// 비디오 전송
  ///
  /// 비디오 데이터를 서버로 전송합니다.
  Future<http.Response?> sendVideoFrame();

  /// 오디오 전송
  ///
  /// 오디오 데이터를 서버로 전송합니다.
  Future<http.Response?> sendAudioData();

  /// 리소스 해제
  void dispose();
}
