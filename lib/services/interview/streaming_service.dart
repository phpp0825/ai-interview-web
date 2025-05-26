import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'interfaces/streaming_service_interface.dart';
import 'interfaces/connection_status.dart';

/// 목업 스트리밍 서비스
/// 실제 서버 통신 없이 앱의 흐름을 테스트하기 위한 간단한 목업 클래스입니다
class StreamingService implements IStreamingService {
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final Function(String) onError;

  StreamingService({required this.onError});

  @override
  bool get isConnected => true; // 목업에서는 항상 연결됨

  @override
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  @override
  Future<bool> connect(String serverUrl) async {
    print('목업: 스트리밍 서버 연결 - $serverUrl');
    await Future.delayed(Duration(seconds: 1));
    _connectionStatusController.add(ConnectionStatus.connected);
    return true;
  }

  @override
  Future<void> disconnect() async {
    print('목업: 스트리밍 서버 연결 해제');
    await Future.delayed(Duration(milliseconds: 500));
    _connectionStatusController.add(ConnectionStatus.disconnected);
  }

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    print('목업: GET 요청 - $endpoint');
    await Future.delayed(Duration(milliseconds: 300));
    return MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({'status': 'success', 'endpoint': endpoint}),
    );
  }

  @override
  Future<dynamic> post(String endpoint, dynamic data,
      {Map<String, String>? headers}) async {
    print('목업: POST 요청 - $endpoint');
    await Future.delayed(Duration(milliseconds: 500));
    return MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({'status': 'success', 'endpoint': endpoint}),
    );
  }

  @override
  Future<dynamic> put(String endpoint, dynamic data,
      {Map<String, String>? headers}) async {
    print('목업: PUT 요청 - $endpoint');
    await Future.delayed(Duration(milliseconds: 400));
    return MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({'status': 'updated', 'endpoint': endpoint}),
    );
  }

  @override
  Future<dynamic> delete(String endpoint,
      {Map<String, String>? headers}) async {
    print('목업: DELETE 요청 - $endpoint');
    await Future.delayed(Duration(milliseconds: 300));
    return MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({'status': 'deleted', 'endpoint': endpoint}),
    );
  }

  @override
  Future<dynamic> uploadFile(String endpoint, List<int> file,
      {Map<String, String>? headers}) async {
    print('목업: 파일 업로드 - $endpoint, ${file.length} bytes');
    await Future.delayed(Duration(seconds: 1));
    return MockHttpResponse(
      statusCode: 200,
      body: jsonEncode({'status': 'uploaded', 'file_size': file.length}),
    );
  }
}

/// 목업 HTTP 응답 클래스
class MockHttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  MockHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });
}
