import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';

class ReportService {
  // API 엔드포인트 (실제 서버 주소로 변경 필요)
  static const String baseUrl = 'https://your-api-server.com/api';

  // 단일 리포트 조회
  Future<ReportModel> getReport(String reportId) async {
    try {
      // 실제 API 연동 시에는 아래 주석 해제
      // final response = await http.get(Uri.parse('$baseUrl/reports/$reportId'));

      // if (response.statusCode == 200) {
      //   return ReportModel.fromJson(json.decode(response.body));
      // } else {
      //   throw Exception('Failed to load report: ${response.statusCode}');
      // }

      // 테스트용 모의 데이터
      await Future.delayed(const Duration(milliseconds: 800)); // 네트워크 지연 시뮬레이션
      return _getMockReport(reportId);
    } catch (e) {
      // 에러 발생 시 기본 데이터 또는 예외 처리
      throw Exception('데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 모든 리포트 목록 조회
  Future<List<ReportModel>> getAllReports() async {
    try {
      // 실제 API 연동 시에는 아래 주석 해제
      // final response = await http.get(Uri.parse('$baseUrl/reports'));

      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((json) => ReportModel.fromJson(json)).toList();
      // } else {
      //   throw Exception('Failed to load reports: ${response.statusCode}');
      // }

      // 테스트용 모의 데이터
      await Future.delayed(const Duration(seconds: 1)); // 네트워크 지연 시뮬레이션

      return [
        _getMockReport('sample-report-1'),
        _getMockReport('sample-report-2'),
      ];
    } catch (e) {
      throw Exception('데이터를 가져오는데 실패했습니다: $e');
    }
  }

  // 모의 데이터 생성 (테스트용)
  ReportModel _getMockReport(String reportId) {
    // 샘플 타임스탬프 데이터
    final List<TimeStampModel> timeStamps = [
      TimeStampModel(time: 10, label: '자기소개', description: '면접자 자기소개 시작'),
      TimeStampModel(time: 30, label: '이력 설명', description: '이전 업무 경험 설명'),
      TimeStampModel(
          time: 60, label: '기술 역량', description: '기술 스택과 프로젝트 경험 설명'),
      TimeStampModel(time: 90, label: '협업 능력', description: '팀 프로젝트 경험 공유'),
      TimeStampModel(time: 120, label: '마무리', description: '면접 마무리 단계'),
    ];

    // 말하기 속도 샘플 데이터
    final List<FlSpot> speechSpeedData = [
      const FlSpot(0, 120),
      const FlSpot(15, 145),
      const FlSpot(30, 160),
      const FlSpot(45, 170),
      const FlSpot(60, 190), // 긴장으로 빨라짐
      const FlSpot(75, 175),
      const FlSpot(90, 140), // 협업 경험 설명 시 안정적
      const FlSpot(105, 150),
      const FlSpot(120, 130), // 마무리 단계에서 안정적
      const FlSpot(135, 120),
    ];

    // 시선 처리 샘플 데이터
    final List<ScatterSpot> gazeData = [
      // 면접 초반 (파란색) - 긴장으로 시선이 불안정
      ScatterSpot(-0.8, 0.7, color: Colors.blue, radius: 8),
      ScatterSpot(-0.3, 0.5, color: Colors.blue, radius: 6),
      ScatterSpot(0.1, 0.3, color: Colors.blue, radius: 4),
      ScatterSpot(0.5, 0.1, color: Colors.blue, radius: 5),
      ScatterSpot(0.7, -0.3, color: Colors.blue, radius: 7),
      ScatterSpot(-0.4, -0.6, color: Colors.blue, radius: 8),
      ScatterSpot(-0.9, -0.2, color: Colors.blue, radius: 6),

      // 면접 중반 (보라색) - 안정되기 시작하지만 여전히 불안정
      ScatterSpot(-0.5, 0.2, color: Colors.purple, radius: 10),
      ScatterSpot(-0.2, 0.1, color: Colors.purple, radius: 12),
      ScatterSpot(0.0, 0.0, color: Colors.purple, radius: 14), // 중앙에 오래 머무름
      ScatterSpot(0.3, -0.1, color: Colors.purple, radius: 9),
      ScatterSpot(0.2, -0.4, color: Colors.purple, radius: 8),

      // 면접 후반 (빨간색) - 안정적으로 중앙에 집중
      ScatterSpot(-0.1, 0.1, color: Colors.red, radius: 10),
      ScatterSpot(0.1, 0.1, color: Colors.red, radius: 15),
      ScatterSpot(0.0, 0.0, color: Colors.red, radius: 20), // 중앙에 더 오래 머무름
      ScatterSpot(-0.1, -0.1, color: Colors.red, radius: 12),
      ScatterSpot(0.1, -0.1, color: Colors.red, radius: 14),
    ];

    return ReportModel(
      id: reportId,
      title: '면접 분석 보고서 #$reportId',
      date: DateTime.now().subtract(const Duration(days: 2)),
      field: '웹 개발',
      position: '백엔드 개발자',
      interviewType: '직무면접',
      duration: 35, // 분 단위
      score: 85,
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      timestamps: timeStamps,
      speechSpeedData: speechSpeedData,
      gazeData: gazeData,
    );
  }
}
