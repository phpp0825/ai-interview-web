import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SpeechSpeedChart extends StatelessWidget {
  final List<FlSpot> speechData;
  final Function(int) formatDuration;

  const SpeechSpeedChart({
    Key? key,
    required this.speechData,
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
              const Icon(Icons.speed, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                '말하기 속도 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      '단위: 단어/분',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '면접 중 말하기 속도의 변화를 보여줍니다. 적정 말하기 속도(120-150 단어/분)를 유지하는 것이 좋습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(_buildSpeechSpeedLineChart()),
          )
        ],
      ),
    );
  }

  // 말하기 속도 차트 생성
  LineChartData _buildSpeechSpeedLineChart() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 30,
        verticalInterval: 30,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
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
            interval: 30,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  formatDuration(value.toInt()),
                  style: const TextStyle(
                    color: Colors.black87,
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
            interval: 30,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8,
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      minX: 0,
      maxX: 150,
      minY: 80,
      maxY: 230,
      lineBarsData: [
        // 말하기 속도 데이터
        LineChartBarData(
          spots: speechData,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade600,
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade300.withOpacity(0.3),
                Colors.blue.shade600.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${formatDuration(spot.x.toInt())}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '${spot.y.toInt()} 단어/분',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // 적정 속도 하한선
          HorizontalLine(
            y: 120,
            color: Colors.green.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, bottom: 5),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              labelResolver: (line) => '적정 속도 하한',
            ),
          ),
          // 적정 속도 상한선
          HorizontalLine(
            y: 150,
            color: Colors.green.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, bottom: 5),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              labelResolver: (line) => '적정 속도 상한',
            ),
          ),
          // 조금 빠른 속도 상한선
          HorizontalLine(
            y: 180,
            color: Colors.orange.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, bottom: 5),
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              labelResolver: (line) => '빠른 속도 상한',
            ),
          ),
          // 매우 빠른 속도 상한선
          HorizontalLine(
            y: 200,
            color: Colors.red.withOpacity(0.8),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, bottom: 5),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              labelResolver: (line) => '너무 빠름',
            ),
          ),
        ],
      ),
    );
  }
}
