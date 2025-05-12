import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../common/section_title.dart';
import '../common/custom_text_field.dart';

class JobInfoForm extends StatelessWidget {
  final ResumeController controller;

  const JobInfoForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  // 필수 정보 레이블 생성 함수
  Widget _buildRequiredLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '* 필수',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '직무 정보 (필수)'),
          const SizedBox(height: 16),

          // 지원 분야 선택
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 지원 분야 선택
                CustomDropdown<String>(
                  labelWidget: _buildRequiredLabel('지원 분야'),
                  icon: Icons.business,
                  value: controller.field,
                  items: controller.fields
                      .map((field) => DropdownMenuItem(
                            value: field,
                            child: Text(field),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateField(value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 희망 직무 선택
                CustomDropdown<String>(
                  labelWidget: _buildRequiredLabel('희망 직무'),
                  icon: Icons.work,
                  value: controller.position,
                  items: controller.positions
                      .map((position) => DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updatePosition(value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 경력 여부 선택
                CustomDropdown<String>(
                  labelWidget: _buildRequiredLabel('경력 여부'),
                  icon: Icons.timeline,
                  value: controller.experience,
                  items: controller.experiences
                      .map((experience) => DropdownMenuItem(
                            value: experience,
                            child: Text(experience),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateExperience(value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // 면접 유형 선택 (체크박스)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequiredLabel('면접 유형 (복수 선택 가능)'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: controller.interviewTypeOptions
                            .map((type) => Container(
                                  child: CheckboxListTile(
                                    title: Text(type),
                                    value: controller.interviewTypes
                                        .contains(type),
                                    activeColor: Colors.deepPurple,
                                    checkColor: Colors.white,
                                    fillColor:
                                        MaterialStateProperty.resolveWith<
                                            Color>((Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.selected)) {
                                        return Colors.deepPurple;
                                      }
                                      return Colors.transparent;
                                    }),
                                    tileColor: Colors.white,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    onChanged: (bool? value) {
                                      controller.updateInterviewType(
                                          type, value);
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
