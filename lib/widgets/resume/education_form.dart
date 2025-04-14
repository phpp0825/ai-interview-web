import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../common/section_title.dart';
import '../common/custom_text_field.dart';

class EducationForm extends StatelessWidget {
  final ResumeController controller;

  const EducationForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '학력 정보'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 학교명
              CustomTextField(
                label: '학교명',
                hint: '학교 이름을 입력하세요',
                icon: Icons.school,
                initialValue: controller.education.school,
                onChanged: (value) =>
                    controller.updateEducation('school', value),
              ),
              const SizedBox(height: 16),

              // 전공
              CustomTextField(
                label: '전공',
                hint: '전공을 입력하세요',
                icon: Icons.book,
                initialValue: controller.education.major,
                onChanged: (value) =>
                    controller.updateEducation('major', value),
              ),
              const SizedBox(height: 16),

              // 학위
              CustomDropdown<String>(
                label: '학위',
                value: controller.education.degree,
                items: controller.degrees
                    .map((degree) => DropdownMenuItem(
                          value: degree,
                          child: Text(degree),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updateEducation('degree', value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 입학일/졸업일
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '입학년월',
                      hint: 'YYYY-MM',
                      initialValue: controller.education.startDate,
                      onChanged: (value) =>
                          controller.updateEducation('startDate', value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: '졸업년월',
                      hint: 'YYYY-MM',
                      initialValue: controller.education.endDate,
                      onChanged: (value) =>
                          controller.updateEducation('endDate', value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 학점
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '학점',
                      keyboardType: TextInputType.number,
                      initialValue: controller.education.gpa,
                      onChanged: (value) =>
                          controller.updateEducation('gpa', value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: '만점',
                      value: controller.education.totalGpa,
                      items: controller.totalGpas
                          .map((gpa) => DropdownMenuItem(
                                value: gpa,
                                child: Text(gpa),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateEducation('totalGpa', value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
