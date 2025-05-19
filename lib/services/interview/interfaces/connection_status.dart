/// 연결 상태를 나타내는 열거형
///
/// 서버 연결 상태를 나타냅니다.
enum ConnectionStatus {
  /// 연결되지 않음
  disconnected,

  /// 연결 중
  connecting,

  /// 연결됨
  connected,

  /// 연결 실패
  failed,

  /// 연결 끊김
  disconnecting
}
