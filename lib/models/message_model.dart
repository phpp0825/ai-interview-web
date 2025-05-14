/// 메시지 모델 클래스
class Message {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  // JSON 역직렬화
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: _messageTypeFromString(json['type']),
    );
  }

  // 문자열에서 MessageType 열거형으로 변환
  static MessageType _messageTypeFromString(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'command':
        return MessageType.command;
      case 'notification':
        return MessageType.notification;
      case 'error':
        return MessageType.error;
      default:
        return MessageType.text;
    }
  }
}

/// 메시지 타입 열거형
enum MessageType {
  text,
  command,
  notification,
  error,
}
