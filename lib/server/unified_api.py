# unified_api.py - 통합 면접 평가 API

import os
import uuid
import shutil
import subprocess
import wave
from typing import List, Optional

from fastapi import FastAPI, APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware

# === numpy import 처리 ===
try:
    import numpy as np
    NUMPY_AVAILABLE = True
except ImportError:
    NUMPY_AVAILABLE = False
    print("⚠️ numpy가 설치되지 않음. 오디오 처리 기능이 제한될 수 있습니다.")

# === 영상 처리를 위한 라이브러리 ===
try:
    import moviepy.editor as mp
    MOVIEPY_AVAILABLE = True
except ImportError:
    MOVIEPY_AVAILABLE = False
    print("⚠️ moviepy 라이브러리가 설치되지 않았습니다. 영상 처리 기능이 제한됩니다.")
    print("설치: pip install moviepy")

# 면접 기능 모듈
from interview_app import (
    evaluate_and_save_responses,
    VideoRecorder,
    VideoConfig,
)

# 포즈 분석 기능
from pose_detection import analyze_video

# 디렉토리 생성
TMP_DIR    = "./tmp"
UPLOAD_DIR = "./uploads"
LOG_DIR    = "./logs"
os.makedirs(TMP_DIR,    exist_ok=True)
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(LOG_DIR,    exist_ok=True)

# === 유틸리티 함수 ===

def extract_audio_from_video(video_path: str, output_audio_path: str = None) -> str:
    """영상 파일에서 오디오를 추출합니다 (WebM/Chrome 녹화 파일 지원)."""
    try:
        if output_audio_path is None:
            base_name = os.path.splitext(video_path)[0]
            output_audio_path = f"{base_name}_audio.wav"
        
        print(f"🎬 영상에서 오디오 추출 시작: {video_path}")
        
        # 1차 시도: FFmpeg 직접 사용 (WebM/Chrome 녹화 파일에 최적화)
        try:
            # FFmpeg 실행 파일 찾기
            ffmpeg_exe = 'ffmpeg'
            
            # Windows에서 ffmpeg 경로 확인
            if os.name == 'nt':  # Windows
                # 일반적인 ffmpeg 설치 경로들 확인
                possible_paths = [
                    'ffmpeg',
                    'ffmpeg.exe',
                    r'C:\ffmpeg\bin\ffmpeg.exe',
                    r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
                    # MoviePy에 포함된 ffmpeg 사용 시도
                ]
                
                ffmpeg_found = False
                for path in possible_paths:
                    try:
                        result = subprocess.run([path, '-version'], capture_output=True, timeout=5)
                        if result.returncode == 0:
                            ffmpeg_exe = path
                            ffmpeg_found = True
                            print(f"✅ FFmpeg 발견: {path}")
                            break
                    except (FileNotFoundError, subprocess.TimeoutExpired):
                        continue
                
                if not ffmpeg_found:
                    print("⚠️ FFmpeg를 찾을 수 없습니다. MoviePy의 ffmpeg 사용을 시도합니다...")
                    if MOVIEPY_AVAILABLE:
                        try:
                            from moviepy.config import FFMPEG_BINARY
                            ffmpeg_exe = FFMPEG_BINARY
                            print(f"✅ MoviePy FFmpeg 발견: {ffmpeg_exe}")
                        except:
                            raise Exception("FFmpeg를 찾을 수 없습니다.")
                    else:
                        raise Exception("FFmpeg를 찾을 수 없습니다.")
            
            # FFmpeg 명령어로 직접 오디오 추출 (duration 문제 우회)
            ffmpeg_cmd = [
                ffmpeg_exe, 
                '-i', video_path,
                '-vn',  # 비디오 스트림 제외
                '-acodec', 'pcm_s16le',  # PCM 16bit로 변환
                '-ar', '44100',  # 44.1kHz 샘플링
                '-ac', '2',  # 스테레오
                '-y',  # 덮어쓰기
                output_audio_path
            ]
            
            print(f"🔧 FFmpeg 직접 실행: {' '.join(ffmpeg_cmd[:5])}...")
            result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0 and os.path.exists(output_audio_path):
                print(f"✅ FFmpeg 오디오 추출 성공: {output_audio_path}")
                return output_audio_path
            else:
                print(f"⚠️ FFmpeg 실행 결과: {result.stderr[:200]}...")
                raise Exception("FFmpeg 직접 실행 실패")
                
        except Exception as ffmpeg_error:
            print(f"⚠️ FFmpeg 직접 실행 실패: {ffmpeg_error}")
            
            # 2차 시도: MoviePy 사용 (duration 무시)
            if MOVIEPY_AVAILABLE:
                print(f"🔄 MoviePy로 재시도...")
                
                try:
                    # duration 문제를 우회하기 위해 end 시간 지정
                    video = mp.VideoFileClip(video_path)
                    
                    if video.audio is None:
                        raise Exception("영상에 오디오 트랙이 없습니다.")
                    
                    # duration이 None이면 임의로 60초로 제한
                    max_duration = 60  # 최대 60초
                    if video.duration is None or video.duration <= 0:
                        print(f"⚠️ Duration 정보 없음, 최대 {max_duration}초로 제한")
                        audio_clip = video.audio.subclip(0, max_duration)
                    else:
                        audio_clip = video.audio
                    
                    audio_clip.write_audiofile(output_audio_path, verbose=False, logger=None)
                    audio_clip.close()
                    video.close()
                    
                    print(f"✅ MoviePy 오디오 추출 완료: {output_audio_path}")
                    return output_audio_path
                    
                except Exception as moviepy_error:
                    print(f"❌ MoviePy도 실패: {moviepy_error}")
                    raise Exception(f"모든 오디오 추출 방법 실패. 마지막 오류: {moviepy_error}")
            else:
                raise Exception("MoviePy 라이브러리가 설치되지 않았고 FFmpeg도 실패했습니다.")
        
    except Exception as e:
        print(f"❌ 오디오 추출 최종 실패: {e}")
        
        # 최후의 수단: 빈 오디오 파일 생성 (분석을 계속 진행하기 위해)
        print(f"🔄 빈 오디오 파일 생성으로 대체...")
        try:
            if not NUMPY_AVAILABLE:
                raise Exception("numpy가 설치되지 않아 빈 오디오 파일을 생성할 수 없습니다.")
            
            # 5초 길이의 무음 오디오 파일 생성
            sample_rate = 44100
            duration = 5  # 5초
            frames = duration * sample_rate
            
            # 무음 데이터 생성
            audio_data = np.zeros(frames, dtype=np.int16)
            
            # WAV 파일로 저장
            with wave.open(output_audio_path, 'w') as wav_file:
                wav_file.setnchannels(1)  # 모노
                wav_file.setsampwidth(2)  # 16bit
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(audio_data.tobytes())
            
            print(f"✅ 빈 오디오 파일 생성 완료: {output_audio_path}")
            return output_audio_path
            
        except Exception as fallback_error:
            print(f"❌ 빈 오디오 파일 생성도 실패: {fallback_error}")
            raise Exception(f"모든 오디오 처리 방법 실패: {e}")

# === FastAPI 앱 설정 ===
app = FastAPI(title="통합 면접 평가 API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

ia_router = APIRouter(prefix="", tags=["InterviewCore"])
pose_router = APIRouter(prefix="/pose", tags=["PoseAnalysis"])

# === 🎯 메인 통합 면접 평가 API ===
@ia_router.post("/evaluate_interview")
async def evaluate_interview(
    # 입력 방식 (택 1)
    video_files: Optional[List[UploadFile]] = File(None),  # 다중 파일 업로드 방식
    video_file: Optional[UploadFile] = File(None),         # 단일 파일 업로드 방식
    video_urls: Optional[List[str]] = Form(None),          # URL 방식
    
    # 필수 파라미터 (JSON 문자열로 받아서 파싱)
    questions: str = Form(...),            # 면접 질문들 (JSON 문자열)
    
    # 선택 파라미터
    include_pose_analysis: bool = Form(False),   # 포즈 분석 포함 여부
    output_file: str = Form("interview_evaluation.txt")
):
    """
    🎯 통합 면접 평가 API - 모든 영상 면접 평가 기능을 하나로 통합
    
    지원 기능:
    1️⃣ 파일 업로드 방식: video_files 사용
    2️⃣ URL 방식: video_urls 사용  
    3️⃣ 단일/다중 영상 모두 지원
    4️⃣ 포즈 분석 옵션 (include_pose_analysis=true)
    5️⃣ 질문-영상 1:1 매핑 또는 전체 통합 평가
    
    사용 예시:
    - 단일 URL: video_urls=["url1"], questions=["질문1", "질문2"]
    - 다중 URL: video_urls=["url1", "url2"], questions=["질문1", "질문2"] 
    - 파일 업로드: video_files=[file1, file2], questions=["질문1", "질문2"]
    - 포즈 분석 포함: include_pose_analysis=true
    """
    video_paths = []
    audio_paths = []
    pose_results = []
    
    try:
        # 1️⃣ 입력 검증
        if not video_files and not video_file and not video_urls:
            raise HTTPException(400, "video_files, video_file 또는 video_urls 중 하나는 필수입니다.")
        
        input_count = sum([1 for x in [video_files, video_file, video_urls] if x])
        if input_count > 1:
            raise HTTPException(400, "video_files, video_file, video_urls 중 하나만 사용할 수 있습니다.")
        
        # 단일 파일을 리스트로 변환
        if video_file:
            video_files = [video_file]
        
        # 질문 JSON 문자열 파싱
        try:
            import json
            questions_list = json.loads(questions)
            if not isinstance(questions_list, list):
                raise ValueError("questions는 리스트 형태여야 합니다.")
        except (json.JSONDecodeError, ValueError) as e:
            raise HTTPException(400, f"질문 데이터 형식 오류: {e}")
        
        # 영상 개수와 질문 개수 체크
        video_count = len(video_files) if video_files else len(video_urls) if video_urls else 0
        question_count = len(questions_list)
        
        print(f"🎬 통합 면접 평가 시작...")
        print(f"  - 영상 개수: {video_count}개")
        print(f"  - 질문 개수: {question_count}개")
        print(f"  - 포즈 분석: {'포함' if include_pose_analysis else '제외'}")
        
        # 2️⃣ 영상 처리 (파일 업로드 방식)
        if video_files:
            print(f"📁 파일 업로드 방식으로 처리...")
            
            for i, video_file in enumerate(video_files):
                print(f"📹 {i+1}번째 파일 처리: {video_file.filename}")
                
                # 파일 저장
                video_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{video_file.filename}")
                with open(video_path, "wb") as f:
                    shutil.copyfileobj(video_file.file, f)
                video_paths.append(video_path)
                
                # 오디오 추출
                audio_path = extract_audio_from_video(video_path)
                audio_paths.append(audio_path)
                
                # 포즈 분석 (옵션)
                if include_pose_analysis:
                    pose_log_path = os.path.join(LOG_DIR, f"{uuid.uuid4()}_pose.txt")
                    analyze_video(video_path, pose_log_path)
                    with open(pose_log_path, "r", encoding="utf-8") as f:
                        pose_results.append(f.read())
                
                print(f"✅ {i+1}번째 파일 처리 완료")
        
        # 3️⃣ 영상 처리 (URL 방식)
        elif video_urls:
            print(f"🌐 URL 방식으로 처리...")
            import requests
            
            for i, video_url in enumerate(video_urls):
                print(f"📹 {i+1}번째 URL 처리: {video_url}")
                
                try:
                    # URL에서 영상 다운로드 (타임아웃 없음)
                    response = requests.get(video_url)
                    if response.status_code != 200:
                        raise Exception(f"HTTP {response.status_code}")
        
                    # 임시 파일 저장
                    video_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_video_{i+1}.mp4")
                    with open(video_path, "wb") as f:
                        f.write(response.content)
                    video_paths.append(video_path)
        
                    print(f"✅ 다운로드 완료: {len(response.content) / 1024 / 1024:.2f} MB")
        
                    # 오디오 추출
                    audio_path = extract_audio_from_video(video_path)
                    audio_paths.append(audio_path)
                    
                    # 포즈 분석 (옵션)
                    if include_pose_analysis:
                        pose_log_path = os.path.join(LOG_DIR, f"{uuid.uuid4()}_pose.txt")
                        analyze_video(video_path, pose_log_path)
                        with open(pose_log_path, "r", encoding="utf-8") as f:
                            pose_results.append(f.read())
                    
                    print(f"✅ {i+1}번째 URL 처리 완료")
                    
                except Exception as e:
                    print(f"❌ {i+1}번째 URL 처리 실패: {e}")
                    continue
        
        if not audio_paths:
            raise HTTPException(500, "모든 영상 처리가 실패했습니다.")
        
        # 4️⃣ STT를 통한 음성 인식 수행
        print(f"\n🎤 음성 인식(STT) 시작...")
        print(f"  - 처리할 오디오 파일: {len(audio_paths)}개")
        
        # STT 클라이언트 초기화
        from interview_app.stt import STTClient
        from interview_app.config import STTConfig
        stt_client = STTClient(STTConfig())
        
        # 각 오디오 파일에서 텍스트 추출
        answers = []
        for i, audio_path in enumerate(audio_paths):
            try:
                print(f"🔍 {i+1}번째 오디오 STT 처리 중...")
                text = stt_client.get_text(audio_path)
                answers.append(text if text.strip() else "음성을 인식할 수 없습니다.")
                print(f"✅ STT 완료: {text[:50]}...")
                    
            except Exception as e:
                print(f"⚠️ {i+1}번째 STT 실패: {e}")
                answers.append("음성 인식 실패")
        
        # 5️⃣ AI 면접 평가 수행
        print(f"\n🧠 AI 면접 평가 시작...")
        print(f"  - 인식된 답변: {len(answers)}개")
        
        # 평가 수행 (실제 STT 결과 사용)
        evaluate_and_save_responses(questions_list, answers, audio_paths, output_file)
        
        # 6️⃣ 결과 파일 읽기
        with open(output_file, "r", encoding="utf-8") as f:
            evaluation_result = f.read()
        
        print(f"✅ 통합 면접 평가 완료!")
        print(f"📄 평가 결과 길이: {len(evaluation_result)}자")
        
        # 6️⃣ 최종 결과 반환
        if include_pose_analysis and pose_results:
            # 포즈 분석 포함된 통합 결과
            combined_result = {
                "success": True,
                "evaluation_result": evaluation_result,
                "pose_analysis": pose_results,
                "video_count": len(audio_paths),
                "question_count": len(questions),
                "message": "면접 평가 및 포즈 분석이 완료되었습니다."
            }
            return JSONResponse(content=combined_result)
        else:
            # 면접 평가 결과만
            return PlainTextResponse(evaluation_result, media_type="text/plain; charset=utf-8")
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 통합 면접 평가 실패: {e}")
        raise HTTPException(500, f"통합 면접 평가 실패: {e}")
    
    finally:
        # 7️⃣ 임시 파일들 정리
        cleanup_files = video_paths + audio_paths
        try:
            for file_path in cleanup_files:
                if file_path and os.path.exists(file_path):
                    os.remove(file_path)
                    print(f"🗑️ 임시 파일 삭제: {os.path.basename(file_path)}")
        except Exception as cleanup_error:
            print(f"⚠️ 파일 정리 중 오류: {cleanup_error}")

# === 🌐 URL 기반 통합 분석 API (새로 추가) ===
@ia_router.post("/analyze_complete_url")
async def analyze_complete_url(
    video_url: str = Form(...),                  # Firebase Storage URL
    questions: str = Form(...),            # 면접 질문들 (JSON 문자열)
    include_pose_analysis: bool = Form(True),    # 포즈 분석 포함 여부
):
    """
    🌐 URL 기반 통합 분석 API - Firebase Storage URL로 분석
    
    클라이언트에서 영상 다운로드가 실패했을 때 URL을 직접 서버로 전달하여 분석
    """
    video_paths = []
    audio_paths = []
    pose_results = []
    
    try:
        # 질문 JSON 문자열 파싱
        try:
            import json
            questions_list = json.loads(questions)
            if not isinstance(questions_list, list):
                raise ValueError("questions는 리스트 형태여야 합니다.")
        except (json.JSONDecodeError, ValueError) as e:
            raise HTTPException(400, f"질문 데이터 형식 오류: {e}")
            
        print(f"🌐 URL 기반 통합 분석 시작...")
        print(f"  - 영상 URL: {video_url[:100]}...")
        print(f"  - 질문 개수: {len(questions_list)}개")
        print(f"  - 포즈 분석: {'포함' if include_pose_analysis else '제외'}")
        
        # URL에서 영상 다운로드
        import requests
        print(f"📥 서버에서 영상 다운로드 시작...")
        
        response = requests.get(video_url)  # 타임아웃 없음
        if response.status_code != 200:
            raise HTTPException(400, f"영상 다운로드 실패: HTTP {response.status_code}")

        # 임시 파일 저장
        video_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_url_video.mp4")
        with open(video_path, "wb") as f:
            f.write(response.content)
        video_paths.append(video_path)

        print(f"✅ 서버 다운로드 완료: {len(response.content) / 1024 / 1024:.2f} MB")

        # 오디오 추출
        audio_path = extract_audio_from_video(video_path)
        audio_paths.append(audio_path)
        
        # 포즈 분석 (옵션)
        pose_analysis_result = ""
        if include_pose_analysis:
            pose_log_path = os.path.join(LOG_DIR, f"{uuid.uuid4()}_url_pose.txt")
            analyze_video(video_path, pose_log_path)
            with open(pose_log_path, "r", encoding="utf-8") as f:
                pose_analysis_result = f.read()
            pose_results.append(pose_analysis_result)

        # STT를 통한 음성 인식 수행
        print(f"🎤 음성 인식(STT) 시작...")
        
        # STT 클라이언트 초기화
        from interview_app.stt import STTClient
        from interview_app.config import STTConfig
        stt_client = STTClient(STTConfig())
        
        # 각 오디오 파일에서 텍스트 추출
        answers = []
        for i, audio_path in enumerate(audio_paths):
            try:
                print(f"🔍 {i+1}번째 오디오 STT 처리 중...")
                text = stt_client.get_text(audio_path)
                answers.append(text if text.strip() else "음성을 인식할 수 없습니다.")
                print(f"✅ STT 완료: {text[:50]}...")
                    
            except Exception as e:
                print(f"⚠️ {i+1}번째 STT 실패: {e}")
                answers.append("음성 인식 실패")

        # AI 면접 평가 수행
        print(f"🧠 AI 면접 평가 시작...")
        output_file = f"url_interview_evaluation_{uuid.uuid4().hex}.txt"
        evaluate_and_save_responses(questions_list, answers, audio_paths, output_file)
        
        # 평가 결과 읽기
        with open(output_file, "r", encoding="utf-8") as f:
            evaluation_result = f.read()

        print(f"✅ URL 기반 통합 분석 완료!")
        
        # JSON 형태로 결과 반환
        return JSONResponse(content={
            "success": True,
            "poseAnalysis": pose_analysis_result if include_pose_analysis else None,
            "evaluationResult": evaluation_result,
            "message": "URL 기반 통합 분석이 완료되었습니다.",
            "videoSize": f"{len(response.content) / 1024 / 1024:.2f} MB"
        })
        
    except Exception as e:
        print(f"❌ URL 기반 분석 실패: {e}")
        raise HTTPException(500, f"URL 기반 분석 실패: {e}")
    
    finally:
        # 임시 파일들 정리
        cleanup_files = video_paths + audio_paths
        for file_path in cleanup_files:
            try:
                if file_path and os.path.exists(file_path):
                    os.remove(file_path)
                    print(f"🗑️ 임시 파일 삭제: {os.path.basename(file_path)}")
            except Exception as cleanup_error:
                print(f"⚠️ 파일 정리 중 오류: {cleanup_error}")

# === 포즈 분석 전용 API ===
@pose_router.post("/analyze")
async def pose_analyze(file: UploadFile = File(...)):
    """포즈 분석만 수행하는 간단한 API"""
    vid_id = uuid.uuid4().hex
    fname  = f"{vid_id}_{file.filename}"
    vpath  = os.path.join(UPLOAD_DIR, fname)
    with open(vpath, "wb") as f:
        shutil.copyfileobj(file.file, f)
    logp = os.path.join(LOG_DIR, f"{vid_id}.txt")
    try:
        analyze_video(vpath, logp)
    except Exception as e:
        raise HTTPException(500, f"분석 오류: {e}")
    return PlainTextResponse(open(logp, "r", encoding="utf-8").read(), media_type="text/plain; charset=utf-8")

# === 라우터 등록 ===
app.include_router(ia_router)
app.include_router(pose_router)

# === 서버 실행 ===
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("unified_api:app", host="0.0.0.0", port=8000, reload=True)