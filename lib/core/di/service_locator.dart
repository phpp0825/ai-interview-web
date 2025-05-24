import 'package:get_it/get_it.dart';

import '../../repositories/report/firebase_report_repository.dart';
import '../../repositories/report/report_repository_interface.dart';
import '../../repositories/resume/firebase_resume_repository.dart';
import '../../repositories/resume/resume_repository_interface.dart';
import '../../services/common/audio_service.dart';

import '../../services/common/video_recording_service.dart';
import '../../services/interview/interview_service.dart';
import '../../services/interview/media_service.dart';
import '../../services/interview/streaming_service.dart';
import '../../services/interview/interfaces/interview_service_interface.dart';
import '../../services/interview/interfaces/media_service_interface.dart';
import '../../services/interview/interfaces/streaming_service_interface.dart';
import '../../services/report/report_service.dart';
import '../../services/report/interfaces/report_service_interface.dart';
import '../../services/resume/resume_service.dart';
import '../../services/resume/interfaces/resume_service_interface.dart';

/// 전역 서비스 로케이터 인스턴스
final GetIt serviceLocator = GetIt.instance;

/// 모든 서비스 및 의존성 등록
Future<void> setupServiceLocator() async {
  // Repositories
  serviceLocator.registerLazySingleton<IResumeRepository>(
    () => FirebaseResumeRepository(),
  );

  serviceLocator.registerLazySingleton<IReportRepository>(
    () => FirebaseReportRepository(),
  );

  // 기본 서비스들
  serviceLocator.registerLazySingleton(() => VideoRecordingService());

  serviceLocator.registerLazySingleton(() => AudioService());

  // 인터뷰 서비스 등록
  // 스트리밍 서비스는 에러 콜백을 받아야 하므로 팩토리로 등록
  serviceLocator.registerFactory<IStreamingService>(() {
    return StreamingService(
      onError: (msg) => print('스트리밍 오류: $msg'),
    );
  });

  // 미디어 서비스도 팩토리로 등록
  serviceLocator.registerFactory<IMediaService>(() {
    return MediaService(
      httpService: serviceLocator<IStreamingService>(),
      cameraService: serviceLocator<VideoRecordingService>(),
      onError: (msg) => print('미디어 오류: $msg'),
    );
  });

  // 인터뷰 서비스도 팩토리로 등록
  serviceLocator.registerFactory<IInterviewService>(() {
    return InterviewService(
      httpService: serviceLocator<IStreamingService>(),
      mediaService: serviceLocator<IMediaService>(),
      onError: (msg) => print('인터뷰 오류: $msg'),
    );
  });

  // Report Service
  serviceLocator.registerLazySingleton<IReportService>(
      () => ReportService(serviceLocator<IReportRepository>()));

  // Resume Service
  serviceLocator.registerLazySingleton<IResumeService>(
      () => ResumeService(serviceLocator<IResumeRepository>()));
}
