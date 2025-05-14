import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP 연결 상태를 나타내는 열거형
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// HTTP를 통한 기본 스트리밍 서비스
/// 연결 관리 및 기본 데이터 전송 기능을 제공합니다.
class HttpStreamingService {
  // 상태 관리 스트림 컨트롤러
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  // 타이머
  Timer? _heartbeatTimer;

  // 서버 URL 정보
  String? _serverUrl;
  String? _sessionId;

  // 현재 연결 상태
  ConnectionStatus _status = ConnectionStatus.disconnected;

  // 컨트롤러에서 받을 콜백 함수
  final Function(String) onError;
  final Function()? onStateChanged;

  // 외부에서 접근 가능한 스트림
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  // 상태 getter
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;
  String? get serverUrl => _serverUrl;

  HttpStreamingService({
    required this.onError,
    this.onStateChanged,
  });

  // HTTP 클라이언트
  final http.Client _httpClient = http.Client();

  /// 서버에 연결
  Future<bool> connect(String url) async {
    print('HTTP 서버 연결 시도: $url');

    if (_status == ConnectionStatus.connected) {
      print('이미 연결되어 있음');
      return true;
    }

    try {
      // 연결 중 상태로 변경
      _updateConnectionStatus(ConnectionStatus.connecting);

      _serverUrl = url;

      // 서버 연결 확인 (테스트 요청)
      final response = await _httpClient
          .get(
            Uri.parse('$url/ping'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // 연결 성공
        _updateConnectionStatus(ConnectionStatus.connected);

        // 하트비트 시작 (10초마다 서버에 신호 보내기)
        _startHeartbeat();

        // 상태 변경 알림
        onStateChanged?.call();

        return true;
      } else {
        // 연결 실패
        _updateConnectionStatus(ConnectionStatus.disconnected);
        return false;
      }
    } catch (e) {
      print('HTTP 서버 연결 오류: $e');
      _updateConnectionStatus(ConnectionStatus.disconnected);
      onError('서버 연결 실패: $e');
      return false;
    }
  }

  /// 하트비트 타이머 시작 (연결 상태 유지)
  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!isConnected || _serverUrl == null) {
        _stopHeartbeat();
        return;
      }

      try {
        final response = await _httpClient
            .get(
              Uri.parse('$_serverUrl/ping'),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode != 200) {
          _updateConnectionStatus(ConnectionStatus.disconnected);
          _stopHeartbeat();
        }
      } catch (e) {
        print('하트비트 오류: $e');
        _updateConnectionStatus(ConnectionStatus.disconnected);
        _stopHeartbeat();
      }
    });
  }

  /// 연결 상태 업데이트
  void _updateConnectionStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _connectionStatusController.add(newStatus);

      print('HTTP 연결 상태 변경: $_status');

      // 상태 변경 알림
      onStateChanged?.call();
    }
  }

  /// HTTP POST 요청 전송 (범용 메서드)
  Future<http.Response?> post(String path, dynamic body,
      {Map<String, String>? headers}) async {
    if (!isConnected || _serverUrl == null) {
      onError('서버에 연결되지 않아 요청을 전송할 수 없습니다');
      return null;
    }

    try {
      final fullUrl = Uri.parse('$_serverUrl/$path');
      final defaultHeaders = {'Content-Type': 'application/json'};
      final mergedHeaders = {...defaultHeaders, ...?headers};

      final encodedBody = body is String
          ? body
          : (body is Uint8List)
              ? body
              : jsonEncode(body);

      return await _httpClient
          .post(
            fullUrl,
            headers: mergedHeaders,
            body: encodedBody,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('HTTP POST 요청 오류: $e');
      onError('요청 전송 실패: $e');
      return null;
    }
  }

  /// HTTP GET 요청 전송 (범용 메서드)
  Future<http.Response?> get(String path,
      {Map<String, String>? headers}) async {
    if (!isConnected || _serverUrl == null) {
      onError('서버에 연결되지 않아 요청을 전송할 수 없습니다');
      return null;
    }

    try {
      final fullUrl = Uri.parse('$_serverUrl/$path');
      return await _httpClient
          .get(
            fullUrl,
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('HTTP GET 요청 오류: $e');
      onError('요청 전송 실패: $e');
      return null;
    }
  }

  /// 서버 연결 종료
  void disconnect() {
    print('HTTP 서버 연결 종료');

    // 하트비트 중지
    _stopHeartbeat();

    // 연결 상태 업데이트
    _updateConnectionStatus(ConnectionStatus.disconnected);
  }

  /// 하트비트 중지
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 리소스 해제
  void dispose() {
    disconnect();
    _httpClient.close();
    _connectionStatusController.close();
  }
}
