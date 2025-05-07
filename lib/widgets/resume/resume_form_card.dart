import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../../widgets/resume/job_info_form.dart';
import '../../widgets/resume/education_form.dart';
import '../../widgets/resume/certificate_form.dart';
import '../../widgets/resume/self_introduction_form.dart';
import '../resume/resume_dialogs.dart';

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

              const SizedBox(height: 32),

              // 제출 버튼
              Center(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ResumeDialogs.showSubmitDialog(context, controller),
                  icon: const Icon(Icons.send),
                  label: const Text('제출하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    elevation: 1,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
