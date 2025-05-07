import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../widgets/dashboard/resume_widget.dart';
import '../widgets/dashboard/interview_widget.dart';
import '../widgets/dashboard/report_widget.dart';
import 'resume_view.dart';
import 'interview_view.dart';
import 'report_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );
    final user = Provider.of<User?>(context);

    // 테마 색상
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(background: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('홈'),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            _buildNavMenu(context),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  // 로그아웃 진행
                  await firebaseService.signOut();

                  // 로그아웃 후 상태 확인 및 디버깅
                  print(
                      '로그아웃 완료됨: ${FirebaseAuth.instance.currentUser == null ? "성공" : "실패"}');

                  // 로그인 화면으로 강제 이동 (AuthWrapper를 거치지 않고 직접 이동)
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                } catch (e) {
                  // 로그아웃 실패 시 오류 처리
                  print('로그아웃 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
                  );
                }
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to the Ainterview !',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 이력서 작성 위젯
                        ResumeWidget(color: primaryColor),

                        // 면접 연습 위젯
                        InterviewWidget(color: primaryColor),

                        // 면접 보고서 위젯
                        ReportWidget(color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavMenu(BuildContext context) {
    // primaryColor 가져오기
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ResumeView()),
            );
          },
          child: const Text(
            '이력서 작성',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('면접 시작하기'),
                  content: const Text(
                    '면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서를 작성하시겠습니까?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InterviewView(),
                          ),
                        );
                      },
                      child: const Text('이력서 없이 진행'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResumeView(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        elevation: 1,
                        side: BorderSide(color: primaryColor),
                      ),
                      child: const Text('이력서 작성하기'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text(
            '면접 실행',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportView()),
            );
          },
          child: const Text(
            '면접 보고서',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
