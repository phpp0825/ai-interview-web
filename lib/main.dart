import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth/auth_service.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/landing_view.dart';
import 'views/report_list_view.dart';
import 'views/http_interview_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyB58WK9lj3Y06KKq-0fEu-WVtnkcsk-KbA",
        authDomain: "job-interview-46c64.firebaseapp.com",
        projectId: "job-interview-46c64",
        storageBucket: "job-interview-46c64.firebasestorage.app",
        messagingSenderId: "97108639991",
        appId: "1:97108639991:web:b33a18a8d68c15572f53f2",
        measurementId: "G-P32GX0SPH5"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => Provider.of<AuthService>(
            context,
            listen: false,
          ).authStateChanges,
          initialData: null,
        ),
      ],
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: MaterialApp(
          title: 'Flutter 웹 애플리케이션',
          debugShowCheckedModeBanner: false,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  child!,
                ],
              ),
            ),
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
              surfaceTint: Color(0x00FFFFFF),
              surfaceContainerLow: Colors.white,
              surfaceContainer: Colors.white,
              surfaceContainerHigh: Colors.white,
              surfaceContainerHighest: Colors.white,
              inverseSurface: Colors.white,
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
            useMaterial3: true,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              bodyLarge: TextStyle(color: Colors.black),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
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
