import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GazeAnalysisChart extends StatelessWidget {
  final List<ScatterSpot> gazeData;
  final Function(int) formatDuration;

  const GazeAnalysisChart({
    Key? key,
    required this.gazeData,
    required this.formatDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                '시선 처리 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.purple),
                    SizedBox(width: 4),
                    Text(
                      '점 크기 = 지속 시간',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '면접 중 시선 처리 패턴을 보여줍니다. 적절한 시선 접촉은 자신감을 나타내며, 중앙에 시선을 유지하는 것이 좋습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: ScatterChart(_buildGazeScatterChart()),
          ),
          const SizedBox(height: 16),

          // 그래프 방향 가이드
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionGuide(Icons.arrow_upward, '위'),
              const SizedBox(width: 16),
              _buildDirectionGuide(Icons.arrow_downward, '아래'),
              const SizedBox(width: 16),
              _buildDirectionGuide(Icons.arrow_back, '왼쪽'),
              const SizedBox(width: 16),
              _buildDirectionGuide(Icons.arrow_forward, '오른쪽'),
              const SizedBox(width: 16),
              _buildDirectionGuide(Icons.center_focus_strong, '중앙'),
            ],
          ),
          const SizedBox(height: 12)
        ],
      ),
    );
  }

  // 시선 처리 스캐터 차트 생성
  ScatterChartData _buildGazeScatterChart() {
    return ScatterChartData(
      scatterSpots: gazeData,
      minX: -1.2,
      maxX: 1.2,
      minY: -1.2,
      maxY: 1.2,
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        horizontalInterval: 0.5,
        verticalInterval: 0.5,
        getDrawingHorizontalLine: (value) {
          if (value == 0) {
            return FlLine(
              color: Colors.grey.shade500,
              strokeWidth: 1,
            );
          }
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 0.5,
          );
        },
        getDrawingVerticalLine: (value) {
          if (value == 0) {
            return FlLine(
              color: Colors.grey.shade500,
              strokeWidth: 1,
            );
          }
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 0.5,
            getTitlesWidget: (double value, TitleMeta meta) {
              String text = '';
              if (value >= -1.1 && value <= -0.9) {
                text = '왼쪽';
              } else if (value >= -0.1 && value <= 0.1) {
                text = '중앙';
              } else if (value >= 0.9 && value <= 1.1) {
                text = '오른쪽';
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 0.5,
            getTitlesWidget: (double value, TitleMeta meta) {
              String text = '';
              if (value >= -1.1 && value <= -0.9) {
                text = '아래';
              } else if (value >= -0.1 && value <= 0.1) {
                text = '중앙';
              } else if (value >= 0.9 && value <= 1.1) {
                text = '위';
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      scatterTouchData: ScatterTouchData(
        enabled: true,
        touchTooltipData: ScatterTouchTooltipData(
          tooltipBgColor: Colors.purple.withOpacity(0.8),
          getTooltipItems: (ScatterSpot touchedSpot) {
            // 시선 위치를 한국어로 설명
            String position =
                _getGazePositionDescription(touchedSpot.x, touchedSpot.y);
            return ScatterTooltipItem(
              '시선: $position\n위치: (${touchedSpot.x.toStringAsFixed(1)}, ${touchedSpot.y.toStringAsFixed(1)})',
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              bottomMargin: 10,
            );
          },
        ),
      ),
    );
  }

  // 방향 가이드 위젯
  Widget _buildDirectionGuide(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // 시선 위치를 한국어로 설명하는 함수
  String _getGazePositionDescription(double x, double y) {
    String horizontal = '';
    String vertical = '';

    // 수평 위치 결정
    if (x >= -1.1 && x <= -0.4) {
      horizontal = '왼쪽';
    } else if (x >= -0.3 && x <= 0.3) {
      horizontal = '중앙';
    } else if (x >= 0.4 && x <= 1.1) {
      horizontal = '오른쪽';
    }

    // 수직 위치 결정
    if (y >= -1.1 && y <= -0.4) {
      vertical = '아래';
    } else if (y >= -0.3 && y <= 0.3) {
      vertical = '중앙';
    } else if (y >= 0.4 && y <= 1.1) {
      vertical = '위';
    }

    // 위치 조합
    if (horizontal == '중앙' && vertical == '중앙') {
      return '정중앙'; // 가장 이상적인 시선
    } else if (horizontal == '중앙') {
      return '$vertical 중앙';
    } else if (vertical == '중앙') {
      return '$horizontal 중앙';
    } else {
      return '$vertical $horizontal';
    }
  }
}
