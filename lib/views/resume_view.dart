import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/resume_controller.dart';
import '../widgets/common/error_banner.dart';
import '../widgets/resume/resume_header.dart';
import '../widgets/resume/resume_form_card.dart';

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
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 1200), // 최대 너비 설정
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽 여백 (화면의 1/6)
                Expanded(flex: 1, child: Container(color: Colors.white)),

                // 중앙 내용 (화면의 2/3)
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // 헤더 섹션
                        const ResumeHeader(),

                        // 오류 메시지 (있는 경우)
                        if (controller.error != null)
                          ErrorBanner(errorMessage: controller.error!),

                        // 통합 입력 폼
                        ResumeFormCard(controller: controller),
                      ],
                    ),
                  ),
                ),

                // 오른쪽 여백 (화면의 1/6)
                Expanded(flex: 1, child: Container(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
