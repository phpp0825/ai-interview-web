import 'package:get_it/get_it.dart';

import '../../repositories/report/firebase_report_repository.dart';
import '../../repositories/report/report_repository_interface.dart';
import '../../repositories/resume/firebase_resume_repository.dart';
import '../../repositories/resume/resume_repository_interface.dart';
import '../../services/common/video_recording_service.dart';

import '../../services/resume/resume_service.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';
import '../../services/report/report_service.dart';
import '../../services/report/video_player_service.dart';
import '../../services/interview/interview_state_service.dart';
import '../../services/interview/interview_video_service.dart';
import '../../services/interview/interview_analysis_service.dart';

/// 전역 서비스 로케이터 인스턴스
final GetIt serviceLocator = GetIt.instance;

/// 모든 서비스 및 의존성 등록
///
/// 초보 개발자를 위한 설명:
/// - VideoRecordingService: 비디오+음성 녹화 통합 처리
/// - ReportService: 리포트 비즈니스 로직 처리
/// - VideoPlayerService: 비디오 플레이어 관리
Future<void> setupServiceLocator() async {
  // Repositories
  serviceLocator.registerLazySingleton<IResumeRepository>(
    () => FirebaseResumeRepository(),
  );

  serviceLocator.registerLazySingleton<IReportRepository>(
    () => FirebaseReportRepository(),
  );

  // 기본 서비스 (비디오+음성 통합)
  serviceLocator.registerLazySingleton(() => VideoRecordingService());

  // Report 관련 서비스들
  serviceLocator.registerLazySingleton(() => ReportService());
  serviceLocator.registerLazySingleton(() => VideoPlayerService());

  // Interview 관련 서비스들
  serviceLocator.registerLazySingleton(() => InterviewStateService());
  serviceLocator.registerLazySingleton(() => InterviewVideoService());
  serviceLocator.registerLazySingleton(() => InterviewAnalysisService());

  // Resume Service
  serviceLocator.registerLazySingleton<IResumeService>(
      () => ResumeService(serviceLocator<IResumeRepository>()));
}
