import 'package:flutter/material.dart';
import '../../controllers/resume_controller.dart';
import '../common/section_title.dart';

class SelfIntroductionForm extends StatefulWidget {
  final ResumeController controller;

  const SelfIntroductionForm({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<SelfIntroductionForm> createState() => _SelfIntroductionFormState();
}

class _SelfIntroductionFormState extends State<SelfIntroductionForm> {
  // TextEditingController 객체 생성
  late TextEditingController _motivationController;
  late TextEditingController _strengthController;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _motivationController = TextEditingController(
        text: widget.controller.selfIntroductionMotivation ?? '');
    _strengthController = TextEditingController(
        text: widget.controller.selfIntroductionStrength ?? '');
  }

  @override
  void didUpdateWidget(SelfIntroductionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때 컨트롤러 업데이트 (필요한 경우만)
    if (oldWidget.controller.selfIntroductionMotivation !=
        widget.controller.selfIntroductionMotivation) {
      _motivationController.text =
          widget.controller.selfIntroductionMotivation ?? '';
    }
    if (oldWidget.controller.selfIntroductionStrength !=
        widget.controller.selfIntroductionStrength) {
      _strengthController.text =
          widget.controller.selfIntroductionStrength ?? '';
    }
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _motivationController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 인성 면접이 선택된 경우에만 자기소개서 양식 표시
    if (!widget.controller.isPersonalityInterviewSelected) {
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
                    controller: _motivationController,
                    onChanged: (value) => widget.controller
                        .updateSelfIntroductionMotivation(value),
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                  // 직무 관련 역량
                  _buildTextArea(
                    label: '직무 관련 역량 (선택사항, 500자 이내)',
                    hint: '지원 직무에 필요한 역량과 관련된 본인의 경험을 작성해주세요.',
                    controller: _strengthController,
                    onChanged: (value) =>
                        widget.controller.updateSelfIntroductionStrength(value),
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
    required TextEditingController controller,
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
          controller: controller,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: 5,
          textDirection: null,
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
