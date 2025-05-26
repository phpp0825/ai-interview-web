import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 면접 질문 시작 전 카운트다운 위젯
/// 5초 카운트다운을 크고 시각적으로 표시합니다
class CountdownWidget extends StatelessWidget {
  final int countdownValue;
  final String currentQuestion;
  final VoidCallback? onCountdownComplete;

  const CountdownWidget({
    Key? key,
    required this.countdownValue,
    required this.currentQuestion,
    this.onCountdownComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 질문 표시
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz,
                  size: 48,
                  color: Colors.blue.shade600,
                ),
                SizedBox(height: 16),
                Text(
                  '다음 질문',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  currentQuestion,
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 48),

          // 카운트다운 원형 표시
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 진행률 원형 바
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: (6 - countdownValue) / 5, // 5초에서 시작해서 0으로
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCountdownColor(countdownValue),
                    ),
                  ),
                ),

                // 카운트다운 숫자
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      countdownValue > 0 ? '$countdownValue' : '시작!',
                      style: GoogleFonts.notoSans(
                        fontSize: countdownValue > 0 ? 72 : 36,
                        fontWeight: FontWeight.w900,
                        color: _getCountdownColor(countdownValue),
                      ),
                    ),
                    if (countdownValue > 0) ...[
                      SizedBox(height: 8),
                      Text(
                        '초 후 녹화 시작',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 48),

          // 안내 메시지
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '카운트다운이 끝나면 자동으로 녹화가 시작됩니다.\n편안한 자세로 준비해주세요!',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 카운트다운 값에 따른 색상 반환
  Color _getCountdownColor(int value) {
    switch (value) {
      case 5:
      case 4:
        return Colors.green.shade500;
      case 3:
      case 2:
        return Colors.orange.shade500;
      case 1:
        return Colors.red.shade500;
      case 0:
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade400;
    }
  }
}

/// 녹화 중 표시 위젯
class RecordingIndicatorWidget extends StatefulWidget {
  final String currentQuestion;
  final int questionNumber;
  final int totalQuestions;
  final VoidCallback? onStopRecording;
  final VoidCallback? onNextQuestion;

  const RecordingIndicatorWidget({
    Key? key,
    required this.currentQuestion,
    required this.questionNumber,
    required this.totalQuestions,
    this.onStopRecording,
    this.onNextQuestion,
  }) : super(key: key);

  @override
  State<RecordingIndicatorWidget> createState() =>
      _RecordingIndicatorWidgetState();
}

class _RecordingIndicatorWidgetState extends State<RecordingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade50,
            Colors.red.shade100,
          ],
        ),
      ),
      child: Column(
        children: [
          // 상단 녹화 상태 바
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _blinkAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _blinkAnimation.value,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 12),
                Text(
                  'REC',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Text(
                  '질문 ${widget.questionNumber}/${widget.totalQuestions}',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 질문 표시
          Expanded(
            child: Center(
              child: Container(
                margin: EdgeInsets.all(32),
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 64,
                      color: Colors.red.shade600,
                    ),
                    SizedBox(height: 24),
                    Text(
                      widget.currentQuestion,
                      style: GoogleFonts.notoSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    Text(
                      '답변을 자유롭게 해주세요',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 버튼들
          Container(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onStopRecording,
                    icon: Icon(Icons.stop, size: 20),
                    label: Text('녹화 중지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onNextQuestion,
                    icon: Icon(Icons.arrow_forward, size: 20),
                    label: Text('다음 질문'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
