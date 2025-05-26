import 'dart:async';
import 'connection_status.dart';

/// 목업 스트리밍 서비스 인터페이스
/// 실제 서버 통신 없이 앱의 흐름을 테스트하기 위한 간단한 목업 인터페이스입니다
abstract class IStreamingService {
  /// 서버 연결 상태
  Stream<ConnectionStatus> get connectionStatus;

  /// 서버에 연결되어 있는지 여부
  bool get isConnected;

  /// 서버에 연결
  ///
  /// [serverUrl]에 연결합니다.
  Future<bool> connect(String serverUrl);

  /// 서버 연결 해제
  Future<void> disconnect();

  /// GET 요청 전송
  ///
  /// [endpoint]에 GET 요청을 보냅니다.
  Future<dynamic> get(String endpoint, {Map<String, String>? headers});

  /// POST 요청 전송
  ///
  /// [endpoint]에 [data]를 담아 POST 요청을 보냅니다.
  Future<dynamic> post(String endpoint, dynamic data,
      {Map<String, String>? headers});

  /// PUT 요청 전송
  ///
  /// [endpoint]에 [data]를 담아 PUT 요청을 보냅니다.
  Future<dynamic> put(String endpoint, dynamic data,
      {Map<String, String>? headers});

  /// DELETE 요청 전송
  ///
  /// [endpoint]에 DELETE 요청을 보냅니다.
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers});

  /// 파일 업로드
  ///
  /// [endpoint]에 [file]을 업로드합니다.
  Future<dynamic> uploadFile(String endpoint, List<int> file,
      {Map<String, String>? headers});
}
