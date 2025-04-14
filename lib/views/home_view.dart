import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          _buildNavMenu(context),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await firebaseService.signOut();
            },
          ),
        ],
      ),
      body: _buildDesktopBody(context),
    );
  }

  Widget _buildNavMenu(BuildContext context) {
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
                  title: const Text('면접 시작하기'),
                  content:
                      const Text('면접을 시작하기 전에 이력서 정보가 필요합니다. 이력서를 작성하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const InterviewView()),
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
                              builder: (context) => const ResumeView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
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

  Widget _buildDesktopBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.web, size: 120, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'Flutter 웹 프로젝트에 오신 것을 환영합니다!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '이 프로젝트는 Flutter 웹 개발을 위한 기본 템플릿입니다.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
