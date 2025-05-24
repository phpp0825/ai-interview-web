import 'package:flutter/material.dart';
import '../../views/interview_view.dart';
import '../../views/resume_view.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';
import '../../core/di/service_locator.dart';

/// 이력서 선택 다이얼로그
/// 면접 시작 전에 이력서를 선택하거나 새로 작성할 수 있는 다이얼로그입니다.
class ResumeSelectionDialog extends StatefulWidget {
  final Color color;
  final Function(String resumeId)? onResumeSelected;

  const ResumeSelectionDialog({
    Key? key,
    required this.color,
    this.onResumeSelected,
  }) : super(key: key);

  /// 다이얼로그를 표시하는 정적 메서드
  static void show(BuildContext context, {required Color color}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResumeSelectionDialog(color: color),
    );
  }

  @override
  State<ResumeSelectionDialog> createState() => _ResumeSelectionDialogState();
}

class _ResumeSelectionDialogState extends State<ResumeSelectionDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _resumeList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResumeList();
  }

  /// 이력서 목록 로드
  Future<void> _loadResumeList() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final resumeService = serviceLocator<IResumeService>();
      final resumeList = await resumeService.getCurrentUserResumeList();

      setState(() {
        _resumeList = resumeList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '이력서 정보를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 면접 시작
  void _startInterview(String resumeId) {
    Navigator.of(context).pop(); // 다이얼로그 닫기

    if (widget.onResumeSelected != null) {
      widget.onResumeSelected!(resumeId);
    } else {
      // 기본 동작: 면접 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewView(selectedResumeId: resumeId),
        ),
      );
    }
  }

  /// 이력서 작성 화면으로 이동
  void _navigateToResumeView() {
    Navigator.of(context).pop(); // 다이얼로그 닫기
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeView()),
    ).then((_) {
      // 이력서 작성 후 돌아왔을 때 다이얼로그 다시 표시
      ResumeSelectionDialog.show(context, color: widget.color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.5;
    final dialogHeight = screenSize.height * 0.7;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (screenSize.width - dialogWidth) / 2,
        vertical: (screenSize.height - dialogHeight) / 3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 헤더
            _buildHeader(),
            const SizedBox(height: 16),

            // 내용
            if (_isLoading)
              _buildLoadingContent()
            else if (_errorMessage != null)
              _buildErrorContent()
            else if (_resumeList.isEmpty)
              _buildEmptyContent()
            else
              _buildResumeListContent(),

            // 버튼 영역
            const SizedBox(height: 16),
            _buildButtonArea(),
          ],
        ),
      ),
    );
  }

  /// 헤더 빌드
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: widget.color),
          const SizedBox(width: 8),
          const Text(
            '이력서 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 내용 빌드
  Widget _buildLoadingContent() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('이력서 정보를 확인하는 중...'),
          ],
        ),
      ),
    );
  }

  /// 에러 내용 빌드
  Widget _buildErrorContent() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadResumeList,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 내용 빌드
  Widget _buildEmptyContent() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '저장된 이력서가 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '면접을 시작하려면 먼저 이력서를 작성해주세요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 이력서 목록 내용 빌드
  Widget _buildResumeListContent() {
    return Expanded(
      child: Column(
        children: [
          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '면접을 시작하기 전에 먼저 이력서를 선택해주세요.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 이력서 목록
          Expanded(
            child: ListView.builder(
              itemCount: _resumeList.length,
              itemBuilder: (context, index) {
                final resume = _resumeList[index];
                return _buildResumeCard(resume);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 이력서 카드 빌드
  Widget _buildResumeCard(Map<String, dynamic> resume) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: widget.color.withOpacity(0.2),
          child: Icon(Icons.business_center, color: widget.color),
        ),
        title: Text(
          resume['position'] ?? '직무 정보 없음',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(resume['field'] ?? '분야 정보 없음'),
            Text(
              resume['experience'] ?? '경력 정보 없음',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startInterview(resume['id']),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('선택'),
        ),
        onTap: () => _startInterview(resume['id']),
      ),
    );
  }

  /// 버튼 영역 빌드
  Widget _buildButtonArea() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('새 이력서'),
            onPressed: _navigateToResumeView,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.color,
              side: BorderSide(color: widget.color),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
