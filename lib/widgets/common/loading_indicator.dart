import 'package:flutter/material.dart';

/// 로딩 중 표시를 위한 인디케이터 위젯
class LoadingIndicator extends StatelessWidget {
  final String message;
  final bool useScaffold;

  const LoadingIndicator({
    Key? key,
    this.message = '로딩 중...',
    this.useScaffold = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (useScaffold) {
      return Scaffold(
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
