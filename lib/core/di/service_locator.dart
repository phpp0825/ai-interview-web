import 'package:get_it/get_it.dart';

import '../../repositories/report/firebase_report_repository.dart';
import '../../repositories/report/report_repository_interface.dart';
import '../../repositories/resume/firebase_resume_repository.dart';
import '../../repositories/resume/resume_repository_interface.dart';
import '../../services/common/video_recording_service.dart';

import '../../services/resume/resume_service.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';

/// 전역 서비스 로케이터 인스턴스
final GetIt serviceLocator = GetIt.instance;

/// 모든 서비스 및 의존성 등록
///
/// 초보 개발자를 위한 설명:
/// VideoRecordingService 하나로 비디오+음성을 모두 처리하므로 AudioService는 제거했어요!
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

  // 로컬 비디오 저장 서비스

  // Report Service는 제거됨 - Repository를 직접 사용

  // Resume Service
  serviceLocator.registerLazySingleton<IResumeService>(
      () => ResumeService(serviceLocator<IResumeRepository>()));
}
