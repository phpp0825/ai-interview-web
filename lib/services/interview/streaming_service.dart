import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'interfaces/streaming_service_interface.dart';
import 'interfaces/connection_status.dart';

/// HTTP 통신을 통한 스트리밍 서비스 구현
class StreamingService implements IStreamingService {
  // 서버 URL
  String? _serverUrl;

  // HTTP 클라이언트
  final http.Client _client = http.Client();

  // 연결 상태
  bool _isConnected = false;
  final StreamController<ConnectionStatus> _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  // 에러 콜백
  final Function(String) onError;

  StreamingService({
    required this.onError,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  @override
  Future<bool> connect(String serverUrl) async {
    if (_isConnected && _serverUrl == serverUrl) {
      return true;
    }

    _connectionStatusController.add(ConnectionStatus.connecting);

    try {
      // 테스트 요청으로 서버 연결 확인
      final response = await _client
          .get(Uri.parse('$serverUrl/ping'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _serverUrl = serverUrl;
        _isConnected = true;
        _connectionStatusController.add(ConnectionStatus.connected);
        return true;
      } else {
        _connectionStatusController.add(ConnectionStatus.failed);
        onError('서버 연결 실패: 상태 코드 ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _connectionStatusController.add(ConnectionStatus.failed);
      onError('서버 연결 실패: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;

    _connectionStatusController.add(ConnectionStatus.disconnecting);

    try {
      // 서버에 연결 종료 요청 (필요하다면)
      if (_serverUrl != null) {
        await _client
            .get(Uri.parse('$_serverUrl/disconnect'))
            .timeout(const Duration(seconds: 3))
            .catchError((e) {
          // 오류는 무시하고 로그만 남김
          print('연결 해제 요청 오류: $e');
        });
      }
    } finally {
      // 상태 업데이트
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.disconnected);
    }
  }

  @override
  Future<http.Response?> get(String endpoint,
      {Map<String, String>? headers}) async {
    if (!_isConnected || _serverUrl == null) {
      onError('서버에 연결되어 있지 않습니다');
      return null;
    }

    try {
      final uri = Uri.parse('$_serverUrl/$endpoint');
      return await _client.get(uri, headers: headers);
    } catch (e) {
      onError('GET 요청 실패: $e');
      return null;
    }
  }

  @override
  Future<http.Response?> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      onError('서버에 연결되어 있지 않습니다');
      return null;
    }

    try {
      final uri = Uri.parse('$_serverUrl/$endpoint');

      // 요청 본문 준비 (JSON 또는 바이너리)
      if (data is List<int>) {
        // 바이너리 데이터
        return await _client.post(
          uri,
          headers: headers,
          body: data,
        );
      } else {
        // JSON 데이터
        final jsonHeaders = {
          'Content-Type': 'application/json',
          ...?headers,
        };

        return await _client.post(
          uri,
          headers: jsonHeaders,
          body: jsonEncode(data),
        );
      }
    } catch (e) {
      onError('POST 요청 실패: $e');
      return null;
    }
  }

  @override
  Future<http.Response?> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      onError('서버에 연결되어 있지 않습니다');
      return null;
    }

    try {
      final uri = Uri.parse('$_serverUrl/$endpoint');

      // 요청 본문 준비 (JSON 또는 바이너리)
      if (data is List<int>) {
        // 바이너리 데이터
        return await _client.put(
          uri,
          headers: headers,
          body: data,
        );
      } else {
        // JSON 데이터
        final jsonHeaders = {
          'Content-Type': 'application/json',
          ...?headers,
        };

        return await _client.put(
          uri,
          headers: jsonHeaders,
          body: jsonEncode(data),
        );
      }
    } catch (e) {
      onError('PUT 요청 실패: $e');
      return null;
    }
  }

  @override
  Future<http.Response?> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      onError('서버에 연결되어 있지 않습니다');
      return null;
    }

    try {
      final uri = Uri.parse('$_serverUrl/$endpoint');
      return await _client.delete(uri, headers: headers);
    } catch (e) {
      onError('DELETE 요청 실패: $e');
      return null;
    }
  }

  @override
  Future<http.Response?> uploadFile(
    String endpoint,
    List<int> file, {
    Map<String, String>? headers,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      onError('서버에 연결되어 있지 않습니다');
      return null;
    }

    try {
      final uri = Uri.parse('$_serverUrl/$endpoint');

      // 파일 업로드를 위한 헤더 설정
      final uploadHeaders = {
        'Content-Type': 'application/octet-stream',
        ...?headers,
      };

      return await _client.post(
        uri,
        headers: uploadHeaders,
        body: file,
      );
    } catch (e) {
      onError('파일 업로드 실패: $e');
      return null;
    }
  }

  @override
  void dispose() {
    if (_isConnected) {
      disconnect();
    }
    _client.close();
    _connectionStatusController.close();
  }
}
