/// 앱 전체에서 사용되는 상수들
class AppConstants {
  AppConstants._(); // 인스턴스 생성 방지

  // 앱 정보
  static const String appName = 'Ainterview';
  static const String appVersion = '1.0.0';

  // 서버 URL (ngrok 터널 주소)
  // TODO: 실제 ngrok 주소로 변경하세요 (예: https://abc123.ngrok.io)
  static const String defaultServerUrl = 'https://your-ngrok-url.ngrok.io';

  // 로컬 개발용 주소 (백업)
  static const String localServerUrl = 'http://localhost:8000';

  // 화면 크기 기준
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // 스타일 상수
  static const double defaultBorderRadius = 20.0;
  static const double smallBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  static const double dialogElevation = 8.0;

  // 간격 상수
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // 폰트 사이즈
  static const double smallFontSize = 12.0;
  static const double normalFontSize = 14.0;
  static const double mediumFontSize = 16.0;
  static const double largeFontSize = 18.0;
  static const double titleFontSize = 22.0;

  // 애니메이션 지속시간
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // 네트워크 타임아웃
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 오류 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다';
  static const String serverErrorMessage = '서버 연결에 실패했습니다';
}
