import 'package:flutter/material.dart';

/// 포즈 분석 섹션 위젯
/// 면접 중 자세와 움직임을 분석한 결과를 표시합니다
class PoseAnalysisSection extends StatelessWidget {
  final String? poseAnalysis;

  const PoseAnalysisSection({
    Key? key,
    this.poseAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.accessibility_new,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '포즈 분석',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'AI 자세 분석',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 설명
          Text(
            '면접 중 자세, 몸짓, 움직임 등을 AI가 분석한 결과입니다. 자연스럽고 자신감 있는 자세는 좋은 인상을 줄 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // 포즈 분석 내용
          _buildPoseAnalysisContent(),
        ],
      ),
    );
  }

  Widget _buildPoseAnalysisContent() {
    if (poseAnalysis == null || poseAnalysis!.isEmpty) {
      return _buildNoPoseAnalysis();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI 분석 결과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poseAnalysis!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPoseAnalysis() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.accessibility_new_outlined,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '포즈 분석 결과가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '면접 영상에서 포즈 데이터를 추출할 수 없거나\n아직 분석이 완료되지 않았습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
