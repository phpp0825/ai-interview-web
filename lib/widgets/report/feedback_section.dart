import 'package:flutter/material.dart';

class FeedbackSection extends StatelessWidget {
  const FeedbackSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.feedback,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '면접 종합 피드백',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 종합 평가
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '종합 평가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '전반적으로 준비가 잘 된 면접이었습니다. 기술적 역량과 경험을 잘 전달했으며, 자신감 있는 태도가 돋보였습니다. '
                  '면접 초반의 긴장감으로 인한 빠른 말하기 속도와 불안정한 시선 처리가 있었지만, 면접이 진행됨에 따라 점차 안정되었습니다. '
                  '구체적인 사례와 수치를 더 활용하고, 일관된 말하기 속도를 유지한다면 더욱 효과적인 면접이 될 것입니다.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '추천 사항',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. 면접 전 심호흡을 통해 초반 긴장감을 완화하세요.\n'
                  '2. 주요 답변에 대한 구체적인 수치와 사례를 미리 준비하세요.\n'
                  '3. 말하기 속도 조절을 위해 중요 포인트에서 의도적으로 속도를 늦추세요.\n'
                  '4. 면접 중 시선은 면접관의 눈과 이마 사이에 고정하는 연습을 하세요.\n'
                  '5. 모의 면접을 통해 피드백을 받고 개선하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
