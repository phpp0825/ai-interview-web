import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../../widgets/resume/job_info_form.dart';
import '../../widgets/resume/education_form.dart';
import '../../widgets/resume/certificate_form.dart';
import '../../widgets/resume/self_introduction_form.dart';

/// 이력서 입력 폼 카드 위젯
class ResumeFormCard extends StatelessWidget {
  final ResumeController controller;

  const ResumeFormCard({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 직무 정보 섹션
              JobInfoForm(controller: controller),
              const SizedBox(height: 32),

              // 학력 정보 섹션
              EducationForm(controller: controller),
              const SizedBox(height: 32),

              // 자격증 섹션
              CertificateForm(controller: controller),
              const SizedBox(height: 32),

              // 인성면접 선택 시에만 자기소개서 섹션 표시
              SelfIntroductionForm(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
