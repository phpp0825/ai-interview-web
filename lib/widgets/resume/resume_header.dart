import 'package:flutter/material.dart';

/// 이력서 화면의 헤더 위젯
class ResumeHeader extends StatelessWidget {
  const ResumeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.description,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          '이력서 작성',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '이력서 작성을 통해 맞춤형 면접 준비를 시작하세요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
