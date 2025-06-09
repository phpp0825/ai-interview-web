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

class _ReportListViewContent extends StatefulWidget {
  const _ReportListViewContent({Key? key}) : super(key: key);

  @override
  State<_ReportListViewContent> createState() => _ReportListViewContentState();
}

class _ReportListViewContentState extends State<_ReportListViewContent> {
  Set<String> _deletingReports = {}; // 삭제 중인 리포트 ID들

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
              onPressed: () => Navigator.pushNamed(context, '/resume'),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // 리포트 상세 화면으로 이동
              Navigator.of(context).pushNamed(
                '/report',
                arguments: report['id'],
              );
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 버튼 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 삭제 버튼
                      _deletingReports.contains(report['id'])
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '삭제 중...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _handleDelete(
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

  // 상태에 따른 색상
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.green; // 기본적으로 완료 상태로 처리
    }
  }

  // 상태에 따른 텍스트
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'pending':
        return '대기 중';
      case 'failed':
        return '실패';
      default:
        return '완료'; // 기본적으로 완료 상태로 처리
    }
  }

  void _handleDelete(
    BuildContext context,
    ReportController controller,
    String reportId,
    String reportTitle,
  ) {
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false, // 외부 터치로 닫기 방지
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('리포트 삭제'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말 "$reportTitle" 리포트를 삭제하시겠습니까?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '삭제되는 데이터:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• 리포트 분석 결과'),
                  const Text('• 면접 영상 파일'),
                  const Text('• AI 피드백 데이터'),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ 이 작업은 되돌릴 수 없습니다.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 확인 다이얼로그 닫기
              _performDelete(context, controller, reportId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
  }

  void _performDelete(
    BuildContext context,
    ReportController controller,
    String reportId,
  ) {
    // 삭제 상태 시작
    setState(() {
      _deletingReports.add(reportId);
    });

    // 삭제 실행
    controller.deleteReport(reportId).then((result) {
      if (mounted) {
        // 삭제 상태 해제
        setState(() {
          _deletingReports.remove(reportId);
        });

        // 결과 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result ? '✅ 리포트와 관련 영상 파일이 모두 삭제되었습니다.' : '❌ 리포트 삭제에 실패했습니다.',
              ),
              backgroundColor: result ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
              action: result
                  ? null
                  : SnackBarAction(
                      label: '다시 시도',
                      textColor: Colors.white,
                      onPressed: () {
                        _performDelete(context, controller, reportId);
                      },
                    ),
            ),
          );
        }
      }
    }).catchError((error) {
      if (mounted) {
        // 오류 시에도 삭제 상태 해제
        setState(() {
          _deletingReports.remove(reportId);
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 삭제 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }
}
