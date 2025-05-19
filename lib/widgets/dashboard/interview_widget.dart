import 'package:flutter/material.dart';
import '../../views/http_interview_view.dart';
import '../../views/resume_view.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';
import '../../core/di/service_locator.dart';

class InterviewWidget extends StatelessWidget {
  final Color color;

  const InterviewWidget({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildCard(
      context,
      title: '면접 시작',
      description: 'AI 면접관과 실시간 면접을 진행하고 피드백을 받아보세요.',
      imagePath: 'assets/images/interview_image.png',
      color: color,
      onTap: () => _onInterviewCardTap(context),
    );
  }

  // 면접 카드 탭 처리
  void _onInterviewCardTap(BuildContext context) async {
    try {
      print('면접 시작 카드 탭됨');

      // 바로 이력서 선택 화면 표시
      _showResumeSelectionDialog(context);
    } catch (e) {
      print('면접 시작 처리 중 오류 발생: $e');

      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이력서 정보 확인 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 이력서 선택 다이얼로그
  void _showResumeSelectionDialog(BuildContext context) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('이력서 정보를 확인하는 중...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // 서비스 로케이터를 통해 ResumeService 인스턴스 가져오기
      print('IResumeService 가져오는 중...');
      final resumeService = serviceLocator<IResumeService>();

      if (resumeService == null) {
        throw Exception('이력서 서비스를 찾을 수 없습니다');
      }

      print('이력서 목록 요청 중...');

      // 이력서 목록 가져오기
      final resumeList = await resumeService.getCurrentUserResumeList();

      print('이력서 목록 응답 받음: ${resumeList.length}개 항목');

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      if (resumeList.isEmpty) {
        print('이력서가 없어 이력서 안내 다이얼로그 표시');
        _showNoResumeDialog(context);
        return;
      }

      // 이력서 선택 다이얼로그 표시
      final screenSize = MediaQuery.of(context).size;
      final dialogWidth = screenSize.width * 0.5;
      final dialogHeight = screenSize.height * 0.7;

      print('이력서 선택 다이얼로그 표시 (${resumeList.length}개 항목)');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더 영역
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: color),
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
                ),

                const SizedBox(height: 16),

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
                          '면접을 시작하기 전에 먼저 이력서를 선택해주세요. 이력서는 면접 질문과 분석에 사용됩니다.',
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
                    shrinkWrap: true,
                    itemCount: resumeList.length,
                    itemBuilder: (context, index) {
                      final resume = resumeList[index];
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
                            backgroundColor: color.withOpacity(0.2),
                            child: Icon(Icons.business_center, color: color),
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
                              Text(resume['experience'] ?? '경력 정보 없음',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  )),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              print('이력서 선택됨 - ${resume['id']}');
                              _startInterview(context, resume['id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('선택'),
                          ),
                          onTap: () {
                            print('이력서 선택됨 - ${resume['id']}');
                            _startInterview(context, resume['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),

                // 버튼 영역
                const SizedBox(height: 16),
                Container(
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
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToResumeView(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('이력서 목록 로드 중 오류 발생: $e');

      // 로딩 다이얼로그가 열려있으면 닫기
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {
          // 이미 닫혀 있을 수 있음
        }

        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이력서 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 면접 시작
  void _startInterview(BuildContext context, String resumeId) {
    Navigator.of(context).pop(); // 다이얼로그 닫기

    // 선택된 이력서 ID를 전달하며 면접 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HttpInterviewView(selectedResumeId: resumeId),
      ),
    );
  }

  // 이력서 작성 화면으로 이동
  void _navigateToResumeView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeView()),
    ).then((_) {
      // 이력서 작성 후 돌아왔을 때 이력서 선택 다이얼로그 다시 표시
      _showResumeSelectionDialog(context);
    });
  }

  // 이력서가 필요하다는 다이얼로그
  void _showNoResumeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이력서 필요'),
        content: const Text('면접을 시작하려면 먼저 이력서를 작성해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToResumeView(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('이력서 작성하기'),
          ),
        ],
      ),
    );
  }

  // 카드 위젯 생성
  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    // 화면 너비에 따라 스타일 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // 반응형 스타일 설정
    final double cardHeight = isSmallScreen ? 180 : 220;
    final double imageHeight = isSmallScreen ? 140 : 200;
    final double fontSize = isSmallScreen ? 18 : 22;
    final double descFontSize = isSmallScreen ? 12 : 14;
    final int maxLines = isSmallScreen ? 2 : 3;
    final double titleSpace = isSmallScreen ? 8 : 12;
    final double buttonSpace = isSmallScreen ? 12 : 20;
    final double padding = isSmallScreen ? 12 : 20;
    final double buttonPadding = isSmallScreen ? 8 : 12;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 왼쪽: 이미지 부분
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding / 2),
                      child: Container(
                        width: double.infinity, // 컨테이너 너비를 최대로 설정
                        height: imageHeight,
                        alignment: Alignment.center,
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),

                // 오른쪽: 텍스트 부분
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 제목
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        SizedBox(height: titleSpace),
                        // 설명
                        Text(
                          description,
                          maxLines: maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: descFontSize,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: buttonSpace),
                        // 버튼
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPadding * 2,
                              vertical: buttonPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            '시작하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
