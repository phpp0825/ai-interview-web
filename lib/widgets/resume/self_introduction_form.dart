import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../common/section_title.dart';

class SelfIntroductionForm extends StatelessWidget {
  final ResumeController controller;

  const SelfIntroductionForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 인성 면접이 선택된 경우에만 자기소개서 양식 표시
    if (!controller.isPersonalityInterviewSelected) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle(title: '자기소개서 작성'),
              const SizedBox(width: 8),
              Text(
                '(모든 항목 선택사항)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지원 동기
                  _buildTextArea(
                    label: '지원 동기 (선택사항, 500자 이내)',
                    hint: '해당 직무에 지원하게 된 이유와 관련 경험을 작성해주세요.',
                    value: controller.selfIntroductionMotivation,
                    onChanged: (value) =>
                        controller.updateSelfIntroductionMotivation(value),
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                  // 직무 관련 역량
                  _buildTextArea(
                    label: '직무 관련 역량 (선택사항, 500자 이내)',
                    hint: '지원 직무에 필요한 역량과 관련된 본인의 경험을 작성해주세요.',
                    value: controller.selfIntroductionStrength,
                    onChanged: (value) =>
                        controller.updateSelfIntroductionStrength(value),
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required String label,
    required String hint,
    required String? value,
    required Function(String) onChanged,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value?.length ?? 0),
            ),
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
