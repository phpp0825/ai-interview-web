import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/resume_model.dart';
import '../controllers/resume_controller.dart';
import '../widgets/resume/job_info_form.dart';
import '../widgets/resume/education_form.dart';
import '../widgets/resume/certificate_form.dart';
import '../widgets/resume/self_introduction_form.dart';
import '../widgets/common/section_title.dart';
import 'interview_view.dart';

class ResumeView extends StatelessWidget {
  const ResumeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResumeController(),
      child: const _ResumeViewContent(),
    );
  }
}

class _ResumeViewContent extends StatelessWidget {
  const _ResumeViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ResumeController>(context);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              background: Colors.white,
              surface: Colors.white,
              surfaceTint: const Color(0x00FFFFFF),
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('이력서 작성'),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            if (controller.isLoadingFromServer)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ResumeController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              margin: EdgeInsets.all(20),
              constraints: const BoxConstraints(
                  maxWidth: 1200), // 중앙 위치 고정 및 최대 너비 설정(1200px로 확장)
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 여백 (화면의 1/6)
                  Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.white,
                      )),

                  // 중앙 내용 (화면의 2/3)
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // 헤더 섹션
                          _buildHeaderSection(context),

                          // 오류 메시지 (있는 경우)
                          if (controller.error != null)
                            _buildErrorBanner(context, controller.error!),

                          // 통합 입력 폼
                          _buildResumeFormCard(context, controller),
                        ],
                      ),
                    ),
                  ),

                  // 오른쪽 여백 (화면의 1/6)
                  Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 오류 메시지 배너
  Widget _buildErrorBanner(BuildContext context, String errorMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // 헤더 섹션 (제목과 설명)
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.description,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          '이력서 작성',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '이력서 작성을 통해 맞춤형 면접 준비를 시작하세요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // 메인 입력 폼 카드
  Widget _buildResumeFormCard(
      BuildContext context, ResumeController controller) {
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
                  onPressed: () => _showSubmitDialog(context, controller),
                  icon: const Icon(Icons.send),
                  label: const Text('제출하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    elevation: 1,
                    side: BorderSide(color: Colors.deepPurple),
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

  // 제출 다이얼로그 표시
  void _showSubmitDialog(BuildContext context, ResumeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              const Text(
                '입력 내용 확인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '다음 내용으로 제출하시겠습니까?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('지원 분야:', controller.field),
                _buildInfoRow('희망 직무:', controller.position),
                _buildInfoRow('경력 여부:', controller.experience),
                _buildInfoRow('면접 유형:', controller.interviewTypes.join(', ')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processSubmission(context, controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: BorderSide(color: Colors.deepPurple),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 정보 행 위젯 빌더
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // 드롭다운 필드 위젯 빌더
  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            underline: Container(),
            icon: Icon(icon, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // 실제 제출 처리
  void _processSubmission(
      BuildContext context, ResumeController controller) async {
    try {
      final success = await controller.submitForm();
      if (success) {
        // 면접 시작 여부 확인 다이얼로그
        _showInterviewStartDialog(context, controller);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이력서 제출에 실패했습니다.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 면접 시작 다이얼로그
  void _showInterviewStartDialog(
      BuildContext context, ResumeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.videocam,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              const Text('면접 시작하기'),
            ],
          ),
          content: const Text(
            '이력서 정보가 성공적으로 저장되었습니다. 지금 면접을 시작하시겠습니까?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // 면접 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InterviewView(
                        resumeData: controller.getCurrentResume()),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('면접 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                elevation: 1,
                side: BorderSide(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }
}
