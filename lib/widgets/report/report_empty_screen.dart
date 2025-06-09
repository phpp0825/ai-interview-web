import 'package:flutter/material.dart';

/// 리포트 데이터 없음 화면 위젯
class ReportEmptyScreen extends StatelessWidget {
  const ReportEmptyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('면접 보고서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('데이터를 찾을 수 없습니다'),
      ),
    );
  }
}
