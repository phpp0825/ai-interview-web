import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../common/section_title.dart';
import '../common/custom_text_field.dart';

class CertificateForm extends StatelessWidget {
  final ResumeController controller;

  const CertificateForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle(title: '자격증 정보'),
            ElevatedButton.icon(
              onPressed: controller.addCertificate,
              icon: const Icon(Icons.add),
              label: const Text('자격증 추가'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (controller.certificates.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              '자격증 정보가 없습니다. "자격증 추가" 버튼을 클릭하여 자격증을 추가하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          )
        else
          ...controller.certificates.asMap().entries.map((entry) {
            final index = entry.key;
            final certificate = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '자격증 #${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => controller.removeCertificate(index),
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: '자격증명',
                      hint: '자격증 이름을 입력하세요',
                      initialValue: certificate.name,
                      onChanged: (value) =>
                          controller.updateCertificate(index, 'name', value),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '발급기관',
                      hint: '발급기관을 입력하세요',
                      initialValue: certificate.issuer,
                      onChanged: (value) =>
                          controller.updateCertificate(index, 'issuer', value),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '취득일',
                      hint: 'YYYY-MM-DD',
                      initialValue: certificate.date,
                      onChanged: (value) =>
                          controller.updateCertificate(index, 'date', value),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '점수/등급',
                      hint: '점수 또는 등급을 입력하세요',
                      initialValue: certificate.score,
                      onChanged: (value) =>
                          controller.updateCertificate(index, 'score', value),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}
