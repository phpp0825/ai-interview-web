import 'dart:async';
import 'package:http/http.dart' as http;
import 'connection_status.dart';

/// 스트리밍 서비스 인터페이스
///
/// 서버와의 HTTP 통신 기능을 제공하는 서비스의 인터페이스입니다.
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
  Future<http.Response?> get(String endpoint, {Map<String, String>? headers});

  /// POST 요청 전송
  ///
  /// [endpoint]에 [data]를 담아 POST 요청을 보냅니다.
  Future<http.Response?> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  });

  /// PUT 요청 전송
  ///
  /// [endpoint]에 [data]를 담아 PUT 요청을 보냅니다.
  Future<http.Response?> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  });

  /// DELETE 요청 전송
  ///
  /// [endpoint]에 DELETE 요청을 보냅니다.
  Future<http.Response?> delete(
    String endpoint, {
    Map<String, String>? headers,
  });

  /// 파일 업로드
  ///
  /// [endpoint]에 [file]을 업로드합니다.
  Future<http.Response?> uploadFile(
    String endpoint,
    List<int> file, {
    Map<String, String>? headers,
  });
}
