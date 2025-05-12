import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/report_controller.dart';
import '../views/report_view.dart';

class ReportListView extends StatelessWidget {
  const ReportListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportController(),
      child: const _ReportListViewContent(),
    );
  }
}

class _ReportListViewContent extends StatelessWidget {
  const _ReportListViewContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReportController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('면접 보고서 목록'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '목록 새로고침',
            onPressed: () => controller.refreshReportList(),
          ),
        ],
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, ReportController controller) {
    if (controller.isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              controller.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refreshReportList(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (controller.reportList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 생성된 리포트가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이력서를 작성하고 면접을 진행하여 리포트를 생성해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.navigateToResumeView(context),
              icon: const Icon(Icons.add),
              label: const Text('이력서 작성하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 면접 보고서',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '총 ${controller.reportList.length}개의 보고서가 있습니다.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildReportList(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportList(BuildContext context, ReportController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.reportList.length,
      itemBuilder: (context, index) {
        final report = controller.reportList[index];
        final statusColor = _getStatusColor(report['status'] as String);
        final score = report['score'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportView(reportId: report['id']),
                ),
              ).then((_) => controller.refreshReportList());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        report['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 상태 표시
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _getStatusText(report['status'] as String),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 직무 및 분야 정보
                            Text(
                              '${report['position']} | ${report['field']}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // 면접 유형 및 날짜 정보
                            Text(
                              '${report['interviewType']} | ${controller.formatDate(report['createdAt'])}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 점수 표시
                      if (report['status'] == 'completed')
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getScoreColor(score).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getScoreColor(score),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: TextStyle(
                                color: _getScoreColor(score),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 버튼 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 삭제 버튼
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmDialog(
                          context,
                          controller,
                          report['id'] as String,
                          report['title'] as String,
                        ),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('삭제'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 보기 버튼
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportView(reportId: report['id']),
                            ),
                          ).then((_) => controller.refreshReportList());
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('보기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(
    BuildContext context,
    ReportController controller,
    String reportId,
    String reportTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리포트 삭제'),
        content: Text('정말 "$reportTitle" 리포트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // 삭제 중 로딩 다이얼로그
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('삭제 중...'),
                    ],
                  ),
                ),
              );

              final result = await controller.deleteReport(reportId);

              if (context.mounted) {
                Navigator.pop(context); // 로딩 다이얼로그 닫기

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result ? '리포트가 삭제되었습니다.' : '리포트 삭제에 실패했습니다.',
                    ),
                    backgroundColor: result ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 상태에 따른 색상
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 상태에 따른 텍스트
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'processing':
        return '처리 중';
      case 'pending':
        return '대기 중';
      case 'failed':
        return '실패';
      default:
        return '알 수 없음';
    }
  }

  // 점수에 따른 색상
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
