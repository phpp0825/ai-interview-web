import 'dart:convert';
import 'dart:typed_data';

/// WebSocket 메시지 타입
enum MessageType {
  text,
  video,
  unknown,
}

/// WebSocket 메시지 모델
class WebSocketMessage {
  final MessageType type;
  final dynamic content;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.content,
    DateTime? timestamp, 
  }) : timestamp = timestamp ?? DateTime.now();

  /// String 메시지에서 WebSocketMessage 객체 생성
  factory WebSocketMessage.fromString(String message) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(message);

      if (decoded.containsKey('type')) {
        final String typeStr = decoded['type'];
        final dynamic content = decoded['content'];

        if (typeStr == 'text') {
          return WebSocketMessage(
            type: MessageType.text,
            content: content.toString(),
          );
        } else if (typeStr == 'video') {
          // Base64 인코딩된 비디오 데이터 디코딩
          if (content is String) {
            return WebSocketMessage(
              type: MessageType.video,
              content: base64Decode(content),
            );
          }
        }
      }

      // 타입이 명시되지 않은 경우 일반 텍스트로 처리
      return WebSocketMessage(
        type: MessageType.text,
        content: message,
      );
    } catch (e) {
      // JSON 파싱 오류 시 일반 텍스트로 처리
      return WebSocketMessage(
        type: MessageType.text,
        content: message,
      );
    }
  }

  /// 바이너리 데이터에서 WebSocketMessage 객체 생성
  factory WebSocketMessage.fromBinary(List<int> data) {
    return WebSocketMessage(
      type: MessageType.video,
      content: Uint8List.fromList(data),
    );
  }

  /// JSON 문자열로 변환
  String toJson() {
    Map<String, dynamic> jsonMap = {
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };

    if (type == MessageType.text) {
      jsonMap['content'] = content.toString();
    } else if (type == MessageType.video && content is Uint8List) {
      jsonMap['content'] = base64Encode(content);
    }

    return jsonEncode(jsonMap);
  }
}
