import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/landing_view.dart';

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
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        StreamProvider<User?>(
          create: (context) => Provider.of<FirebaseService>(
            context,
            listen: false,
          ).authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Flutter 웹 애플리케이션',
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LandingView(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // 사용자가 로그인되어 있으면 홈페이지로, 그렇지 않으면 로그인 페이지로 이동
    if (user != null) {
      return const HomePage();
    }

    return const LoginView();
  }
}
