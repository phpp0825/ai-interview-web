import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/resume_controller.dart';
import '../widgets/common/error_banner.dart';
import '../widgets/resume/resume_header.dart';
import '../widgets/resume/resume_form_card.dart';
import '../widgets/resume/resume_dialogs.dart';

/// 이력서 작성 화면
class ResumeView extends StatelessWidget {
  const ResumeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 항상 생성 모드만 사용
    return ChangeNotifierProvider(
      create: (_) => ResumeController(),
      child: const _ResumeViewContent(),
    );
  }
}

class _ResumeViewContent extends StatelessWidget {
  static const double maxContentWidth = 1200.0;
  static const EdgeInsets contentMargin = EdgeInsets.all(20.0);
  static const Color backgroundColor = Colors.white;

  const _ResumeViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ResumeController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
        colorScheme: colorScheme.copyWith(
          background: backgroundColor,
          surface: backgroundColor,
          surfaceTint: const Color(0x00FFFFFF),
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(context, controller),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context, controller),
      ),
    );
  }

  /// 앱바 구성
  PreferredSizeWidget _buildAppBar(
      BuildContext context, ResumeController controller) {
    return AppBar(
      title: const Text('이력서 작성'),
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      foregroundColor: Colors.white,
    );
  }

  /// 본문 화면 구성
  Widget _buildBody(BuildContext context, ResumeController controller) {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Center(
          child: Container(
            margin: contentMargin,
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽 여백 (화면의 1/6)
                _buildSideMargin(),

                // 중앙 내용 (화면의 2/3)
                Expanded(
                  flex: 4,
                  child: _buildContent(context, controller),
                ),

                // 오른쪽 여백 (화면의 1/6)
                _buildSideMargin(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 좌우 여백 위젯
  Widget _buildSideMargin() {
    return Expanded(flex: 1, child: Container(color: backgroundColor));
  }

  /// 메인 콘텐츠 위젯
  Widget _buildContent(BuildContext context, ResumeController controller) {
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          // 헤더 섹션
          const ResumeHeader(),

          // 오류 메시지 (있는 경우)
          if (controller.error != null)
            ErrorBanner(errorMessage: controller.error!),

          // 통합 입력 폼
          ResumeFormCard(controller: controller),

          // 제출 버튼
          _buildSubmitButton(context, controller),
        ],
      ),
    );
  }

  /// 제출 버튼 위젯
  Widget _buildSubmitButton(BuildContext context, ResumeController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
      child: ElevatedButton(
        onPressed: () => _validateAndSubmit(context, controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '제출하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 유효성 검사 후 제출 다이얼로그 표시
  void _validateAndSubmit(BuildContext context, ResumeController controller) {
    // 필수 항목 검증
    if (!_validateRequiredFields(controller)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 필수 항목을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 제출 다이얼로그 표시
    ResumeDialogs.showSubmitDialog(context, controller);
  }

  /// 필수 필드 유효성 검사
  bool _validateRequiredFields(ResumeController controller) {
    return controller.field.isNotEmpty &&
        controller.position.isNotEmpty &&
        controller.experience.isNotEmpty &&
        controller.interviewTypes.isNotEmpty &&
        controller.education.school.isNotEmpty &&
        controller.education.major.isNotEmpty;
  }
}
