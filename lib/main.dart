import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'controllers/home_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/resume_controller.dart';
import 'firebase_options.dart';
import 'core/di/service_locator.dart';
import 'services/auth/auth_service.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/landing_view.dart';
import 'views/report_list_view.dart';
import 'views/http_interview_view.dart';
import 'views/resume_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 서비스 로케이터 초기화
  await setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        // 먼저 AuthService 등록
        Provider<AuthService>(create: (_) => AuthService()),
        // 그 다음 HomeController에 AuthService 주입
        ChangeNotifierProvider(
            create: (context) => HomeController(context.read<AuthService>())),
        ChangeNotifierProvider(create: (_) => ResumeController()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        // User 스트림 등록
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// 커스텀 페이지 트랜지션
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 즉시 페이지 전환
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ainterview',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomePage(),
        '/landing': (context) => const LandingView(),
        '/report-list': (context) => const ReportListView(),
        '/livestream': (context) => const HttpInterviewView(),
        '/resume': (context) => const ResumeView(),
      },
      initialRoute: '/',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple,
          onPrimary: Colors.white,
          secondary: Colors.deepPurple,
          onSecondary: Colors.white,
          surface: Colors.white,
          background: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 1,
            side: const BorderSide(color: Colors.deepPurple),
          ),
        ),
        // 페이지 트랜지션 설정
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.fuchsia: NoAnimationPageTransitionsBuilder(),
          },
        ),
        useMaterial3: false, // Material 3 대신 Material 2 사용
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    print('AuthWrapper: 현재 유저 상태 - ${user != null ? "로그인됨" : "로그인되지 않음"}');

    // 사용자가 로그인되어 있으면 홈페이지로, 그렇지 않으면 랜딩 페이지로 이동
    if (user != null) {
      return const HomePage();
    }

    return const LandingView();
  }
}
