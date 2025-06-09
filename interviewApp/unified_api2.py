import os
import uuid
import shutil
import subprocess
from typing import List

from fastapi import FastAPI, APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse, PlainTextResponse, FileResponse
from fastapi.staticfiles import StaticFiles

# 이미지 전처리용
from PIL import Image

# TTS용
from gtts import gTTS
from pydub import AudioSegment

# 기존 면접 기능 모듈
from interview_app import (
    ResumeJsonParser,
    InterviewQuestionMaker,
    STTClient,
    calculate_silence_duration,
    calculate_audio_duration,
    evaluate_and_save_responses,
    VideoRecorder,
    AudioRecorder,
    VideoConfig,
)

# 포즈 분석 기능
from pose_detection import analyze_video

from fastapi.middleware.cors import CORSMiddleware

TMP_DIR    = "./tmp"
UPLOAD_DIR = "./uploads"
RESULT_DIR = "./results"
LOG_DIR    = "./logs"
os.makedirs(TMP_DIR,    exist_ok=True)
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(RESULT_DIR, exist_ok=True)
os.makedirs(LOG_DIR,    exist_ok=True)

# 서버 카메라 녹화기 (비디오)
video_recorder = VideoRecorder(config=VideoConfig())

app = FastAPI(title="Unified Interview API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

ia_router = APIRouter(prefix="", tags=["InterviewCore"])

# --- 1) 이력서 파싱 ---
@ia_router.post("/parse_resume")
async def parse_resume(file: UploadFile = File(...)):
    tmp_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(tmp_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    try:
        data = ResumeJsonParser().parse_to_file(tmp_path)
    except Exception as e:
        raise HTTPException(500, f"파싱 실패: {e}")
    return JSONResponse(content=data)

# --- 2) 질문 생성 ---
@ia_router.post("/generate_questions")
async def generate_questions(file: UploadFile = File(...)):
    tmp_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(tmp_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    try:
        qs = InterviewQuestionMaker().generate_questions(tmp_path)
    except Exception as e:
        raise HTTPException(500, f"질문 생성 실패: {e}")
    return {"questions": qs}

# --- 3) STT 전용 엔드포인트 (녹음 없이 파일 업로드만 받아 텍스트 변환) ---
@ia_router.post("/audio/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    tmp_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(tmp_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    try:
        words = STTClient().transcribe(tmp_path)
    except Exception as e:
        raise HTTPException(500, f"STT 실패: {e}")
    return {"word_timestamps": words}

# --- 4) 오디오 메트릭스 (기존 그대로 유지) ---
@ia_router.post("/audio/metrics")
async def audio_metrics(file: UploadFile = File(...)):
    tmp_path = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(tmp_path, "wb") as f:
        shutil.copyfileobj(file.file, f)
    stt = STTClient()
    try:
        wts = stt.transcribe(tmp_path)
        silence = calculate_silence_duration(wts)
    except:
        silence = 0.0
    duration = calculate_audio_duration(tmp_path)
    return {"duration_sec": duration, "silence_sec": silence}

# --- 5) 평가 (기존 그대로 유지) ---
@ia_router.post("/evaluate")
async def evaluate_endpoint(
    background: BackgroundTasks,
    questions: List[str] = Form(...),
    answers:   List[str] = Form(...),
    audio_files: List[UploadFile] = File(...),
    output_file: str = Form("interview_evaluation.txt")
):
    paths = []
    for af in audio_files:
        p = os.path.join(TMP_DIR, f"{uuid.uuid4()}_{af.filename}")
        with open(p, "wb") as f:
            shutil.copyfileobj(af.file, f)
        paths.append(p)
    try:
        evaluate_and_save_responses(questions, answers, paths, output_file)
    except Exception as e:
        raise HTTPException(500, f"평가 실패: {e}")
    try:
        content = open(output_file, "r", encoding="utf-8").read()
    except Exception as e:
        raise HTTPException(500, f"결과 읽기 실패: {e}")
    return PlainTextResponse(content, media_type="text/plain")

# --- 6) 비디오 녹화 시작 ---
@ia_router.post("/video/start")
async def start_video():
    video_recorder.start_recording()
    return {"status": "video recording started"}

# --- 7) 비디오 녹화 종료 ---
@ia_router.post("/video/stop")
async def stop_video():
    video_recorder.stop_recording()
    return {"status": f"video recording stopped, saved to {video_recorder.output_file}"}

# --- 8) 오디오 녹음 전용 엔드포인트 (record_start → record_stop 순차 호출) ---
@ia_router.post("/audio/record")
async def record_audio(output_file: str = Form("response.wav")):
    """
    1) 마이크 녹음 스레드를 백그라운드에서 실행하도록 record_start()를 호출합니다.
    2) 내부 로직에서 음성이 감지되고 무음이 일정 시간 유지되면 자동으로 녹음을 멈춘 뒤,
       record_stop()이 호출되어 denoise 및 WAV 파일 저장을 수행합니다.
    3) 최종적으로 저장된 WAV 파일 경로를 반환합니다.
    """
    rec = AudioRecorder()

    # 1) 녹음 시작 (백그라운드 스레드에서 실제 음성 수집)
    rec.record_start()

    # 2) 녹음 종료 및 파일 저장
    #    denoise_value: AudioConfig에 지정된 디노이즈 강도를 사용
    denoise_value = getattr(rec.config, "noise_reduction_db", 0.0)
    wav_path = rec.record_stop(denoise_value=denoise_value, output_file=output_file)

    if not wav_path:
        raise HTTPException(504, "녹음 실패: 음성 없음")
    return {"wav_file": wav_path}

# --- 9) TTS 전용 엔드포인트 (텍스트 → 음성) ---
@ia_router.post("/audio/tts")
async def generate_tts(text: str = Form(...)):
    """
    면접관 질문 텍스트를 받아 TTS(mp3)를 생성하고 해당 파일을 반환합니다.
    :param text: TTS로 변환할 질문 텍스트
    """
    # 고유한 파일명 생성
    mp3_filename = f"{uuid.uuid4()}.mp3"
    try:
        tts = gTTS(text=text, lang='ko')
        tts.save(mp3_filename)
    except Exception as e:
        raise HTTPException(500, f"TTS 생성 실패: {e}")

    # 생성된 mp3 파일을 반환
    return FileResponse(mp3_filename, media_type="audio/mpeg", filename=os.path.basename(mp3_filename))

# --- 10) 딥페이크 생성 엔드포인트 (Talking Face Avatar 기반) ---
@ia_router.post("/deepfake")
async def generate_deepfake(
    image_file: UploadFile = File(...),
    question_text: str = Form(...)
):
    """
    1) 면접관 사진(image_file)과 질문 텍스트(question_text)를 받아 TTS 오디오를 생성합니다.
    2) 생성된 오디오(.wav)와 전처리된 얼굴 이미지를 Talking Face Avatar 모델을 호출하여 딥페이크 영상(.mp4)으로 합성합니다.
    3) 최종적으로 생성된 mp4 파일을 반환합니다.
    """
    # 1) 업로드된 이미지 저장
    if not image_file.filename.lower().endswith((".jpg", ".jpeg", ".png")):
        raise HTTPException(status_code=400, detail="이미지 파일(.jpg, .png)만 업로드 가능합니다.")
    img_suffix = os.path.splitext(image_file.filename)[1]
    img_uuid = uuid.uuid4().hex
    raw_img_path = os.path.join(UPLOAD_DIR, f"{img_uuid}{img_suffix}")
    with open(raw_img_path, "wb") as f:
        shutil.copyfileobj(image_file.file, f)

    # 2) 이미지 전처리 (512×512)
    try:
        img = Image.open(raw_img_path).convert("RGB")
        img = img.resize((512, 512))
        face_512_path = os.path.join(UPLOAD_DIR, f"{img_uuid}_512.png")
        img.save(face_512_path)
    except Exception as e:
        raise HTTPException(500, f"이미지 전처리 실패: {e}")

    # 3) TTS 생성 및 mp3 → wav 변환
    tts_mp3_path = os.path.join(UPLOAD_DIR, f"{img_uuid}.mp3")
    tts_wav_path = os.path.join(UPLOAD_DIR, f"{img_uuid}.wav")
    try:
        tts = gTTS(text=question_text, lang='ko')
        tts.save(tts_mp3_path)
        sound = AudioSegment.from_file(tts_mp3_path, format="mp3")
        sound.export(tts_wav_path, format="wav")
        os.remove(tts_mp3_path)
    except Exception as e:
        raise HTTPException(500, f"TTS 생성 및 변환 실패: {e}")

    # 4) Talking Face Avatar 모델 호출
    #    - inference.py 위치, 체크포인트 파일 경로를 실제 경로로 수정해야 합니다.
    tfa_inference_py = os.path.join(os.getcwd(), "Talking_Face_Avatar", "inference.py")
    tfa_checkpoint  = os.path.join(os.getcwd(), "Talking_Face_Avatar", "checkpoints", "vox-256.pth")
    if not os.path.exists(tfa_inference_py) or not os.path.exists(tfa_checkpoint):
        raise HTTPException(500, "TFA inference 스크립트 또는 체크포인트를 찾을 수 없습니다.")

    output_video_name = f"{img_uuid}_deepfake.mp4"
    output_video_path = os.path.join(RESULT_DIR, output_video_name)

    cmd = [
        "python", tfa_inference_py,
        "--source_image", face_512_path,
        "--driven_audio", tts_wav_path,
        "--checkpoint_path", tfa_checkpoint,
        "--result_path", output_video_path
    ]
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        raise HTTPException(500, f"딥페이크 생성 실패: {e}")

    # 5) 결과 파일 반환
    if not os.path.exists(output_video_path):
        raise HTTPException(500, "딥페이크 영상이 생성되지 않았습니다.")
    return FileResponse(output_video_path, media_type="video/mp4", filename=output_video_name)

# --- 포즈 분석 관련 라우터 (기존 그대로 유지) ---
pose_router = APIRouter(prefix="/pose", tags=["PoseAnalysis"])

@pose_router.post(
    "/analyze",
    response_class=PlainTextResponse,
    summary="면접 영상 Pose 분석 → 로그 반환"
)
async def pose_analyze(file: UploadFile = File(...)):
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
    return PlainTextResponse(open(logp, "r", encoding="utf-8").read())

@pose_router.get(
    "/log/{video_id}",
    response_class=FileResponse,
    summary="분석 로그 다운로드"
)
async def pose_get_log(video_id: str):
    fp = os.path.join(LOG_DIR, f"{video_id}.txt")
    if not os.path.exists(fp):
        raise HTTPException(404, "로그를 찾을 수 없습니다.")
    return FileResponse(fp, media_type="text/plain", filename=os.path.basename(fp))

app.include_router(ia_router)
app.include_router(pose_router)

# 정적 파일 서빙 설정 (생성된 딥페이크 영상을 /deepfake_videos 경로로 노출)
app.mount("/deepfake_videos", StaticFiles(directory=RESULT_DIR), name="deepfake_videos")

# uvicorn 으로 직접 실행할 때
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("unified_api:app", host="0.0.0.0", port=8000, reload=True)
