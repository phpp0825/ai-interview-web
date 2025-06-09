import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
import threading
import time
import os
from gtts import gTTS
from pydub import AudioSegment
from pydub.playback import play
from PIL import Image, ImageTk
import cv2

from interview_app.resume_parser import parse_resume
from interview_app.question_maker import InterviewQuestionMaker
from interview_app.audio_recorder import AudioRecorder
from interview_app.config import AudioConfig, VideoConfig, STTConfig
from interview_app.stt import STTClient
from interview_app.evaluation import evaluate_and_save_responses
from pose_detection import analyze_video
from interview_app.video_recorder import VideoRecorder

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("AI 모의 면접 시스템")
        self.geometry("900x650")
        self.resizable(False, False)

        self.resume_data = None
        self.questions = []
        self.responses = []
        self.video_path = ""
        self.audio_files = []   # 답변별 오디오 파일 리스트

        self.frames = {}
        for F in (StartPage, QuestionGenPage, InterviewPage, EvaluationPage):
            frame = F(self)
            self.frames[F] = frame
            frame.place(x=0, y=0, relwidth=1, relheight=1)
        self.show_frame(StartPage)

    def show_frame(self, page):
        frame = self.frames[page]
        frame.tkraise()

class StartPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        tk.Label(self, text="Step 1: 이력서를 첨부하세요", font=("Arial", 22, "bold")).pack(pady=35)
        self.file_label = tk.Label(self, text="첨부된 파일 없음", font=("Arial", 12))
        self.file_label.pack(pady=5)
        tk.Button(self, text="파일 선택", font=("Arial", 13), command=self.load_file).pack(pady=10)
        tk.Button(self, text="이력서 파싱", font=("Arial", 13), command=self.parse_file).pack(pady=12)
        self.status_label = tk.Label(self, text="", font=("Arial", 12), fg="blue")
        self.status_label.pack(pady=5)
        self.file_path = None

    def load_file(self):
        path = filedialog.askopenfilename(filetypes=[("PDF files", "*.pdf")])
        if path:
            self.file_path = path
            self.file_label.config(text=path.split("/")[-1])

    def parse_file(self):
        if not self.file_path:
            messagebox.showerror("오류", "먼저 이력서 파일을 첨부하세요!")
            return
        self.status_label.config(text="이력서 파싱 중입니다... 잠시만 기다려주세요.")
        def run_parse():
            self.master.resume_data = self.file_path
            self.status_label.config(text="이력서 파싱이 완료되었습니다.")
            messagebox.showinfo("파싱 완료", "이력서 파싱이 완료되었습니다.")
            self.master.show_frame(QuestionGenPage)
        threading.Thread(target=run_parse).start()

class QuestionGenPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        tk.Label(self, text="Step 2: 자동 질문 생성", font=("Arial", 22, "bold")).pack(pady=35)
        self.question_box = scrolledtext.ScrolledText(self, height=10, width=70, font=("Arial", 12))
        self.question_box.pack(pady=10)
        tk.Button(self, text="질문 생성", font=("Arial", 13), command=self.generate_questions).pack(pady=7)
        tk.Button(self, text="면접 시작", font=("Arial", 13), command=self.goto_interview).pack(pady=13)

    def generate_questions(self):
        self.question_box.delete("1.0", tk.END)
        maker = InterviewQuestionMaker()
        questions = maker.generate_questions(self.master.resume_data)
        self.master.questions = questions
        for i, q in enumerate(questions, 1):
            self.question_box.insert(tk.END, f"{i}. {q}\n")

    def goto_interview(self):
        if not self.master.questions:
            messagebox.showerror("오류", "먼저 질문을 생성하세요!")
            return
        self.master.show_frame(InterviewPage)

class InterviewPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        tk.Label(self, text="Step 3: AI 면접 진행", font=("Arial", 22, "bold")).pack(pady=25)
        self.question_label = tk.Label(self, text="", font=("Arial", 15), wraplength=850)
        self.question_label.pack(pady=15)
        self.status_label = tk.Label(self, text="", font=("Arial", 12), fg="blue")
        self.status_label.pack(pady=5)
        self.stt_result = tk.StringVar()
        self.stt_box = tk.Label(self, textvariable=self.stt_result, font=("Arial", 13), bg="#f5f7ff", width=90, height=5, anchor="nw", justify="left", wraplength=850, relief="ridge")
        self.stt_box.pack(pady=7)
        self.q_idx = 0
        self.answers = []
        self.auto_thread = None
        self.audio_files = []
        self.interview_running = False

        self.stt_client = STTClient(STTConfig())
        self.video_file = "interview_video.avi"
        self.video_recorder = None
        self.audio_recorder = None

        self.quit_btn = tk.Button(self, text="그만하겠습니다", font=("Arial", 12), command=self.force_stop, bg="#ffdddd")
        self.quit_btn.pack(pady=5)

    def tkraise(self, *args, **kwargs):
        self.q_idx = 0
        self.answers = []
        self.audio_files = []
        self.interview_running = True

        # 비디오 녹화 시작
        video_config = VideoConfig()
        video_config.output_file = self.video_file
        self.video_recorder = VideoRecorder(video_config)
        self.video_recorder.start_recording()
        self.master.video_path = self.video_file

        self.show_question()
        super().tkraise(*args, **kwargs)

    def show_question(self):
        if not self.interview_running:
            return
        if self.q_idx < len(self.master.questions):
            self.question_label.config(text=f"Q{self.q_idx+1}. {self.master.questions[self.q_idx]}")
            self.stt_result.set("")
            self.status_label.config(text="질문을 음성으로 출력 중입니다. 잠시 기다려주세요...")
            self.auto_thread = threading.Thread(target=self.tts_then_record)
            self.auto_thread.start()
        else:
            self.finish_interview()

    def tts_then_record(self):
        if not self.interview_running:
            return
        question_text = self.master.questions[self.q_idx]
        tts = gTTS(text=question_text, lang='ko')
        mp3_file = f"question_{self.q_idx+1}.mp3"
        tts.save(mp3_file)
        audio = AudioSegment.from_mp3(mp3_file)
        play(audio)
        os.remove(mp3_file)

        if not self.interview_running:
            return

        self.status_label.config(text="녹음이 곧 시작됩니다. 답변을 준비하세요.")
        self.status_label.update()
        time.sleep(0.7)
        if not self.interview_running:
            return

        self.status_label.config(text="녹음 중... 답변을 말씀하세요.")
        self.status_label.update()
        config = AudioConfig()
        config.vad_timeout_sec = 3.0
        self.audio_recorder = AudioRecorder(config)

        audio_file = f"response_{self.q_idx+1}.wav"
        self.audio_recorder.record_start()
        while self.audio_recorder.recording and self.interview_running:
            time.sleep(0.1)

        # 강제 종료 시 녹음 파일 안 남게 안전 처리
        if not self.interview_running:
            try:
                self.audio_recorder.recording = False
            except Exception:
                pass
            return

        self.audio_recorder.record_stop(denoise_value=0, output_file=audio_file)
        self.audio_files.append(audio_file)
        self.status_label.config(text="음성 인식(STT) 중...")
        self.status_label.update()
        text = self.stt_client.get_text(audio_file)
        self.stt_result.set(text)
        self.answers.append(text)
        if "그만하겠습니다" in text:
            self.interview_running = False
            if self.video_recorder:
                self.video_recorder.stop_recording()
            if self.audio_recorder and getattr(self.audio_recorder, "recording", False):
                self.audio_recorder.recording = False
            self.master.responses = self.answers
            self.master.audio_files = self.audio_files
            self.after(100, lambda: self.master.show_frame(EvaluationPage))
            return
        else:
            self.q_idx += 1
            self.after(1000, self.show_question)
        
    def force_stop(self):
        self.interview_running = False
        if self.video_recorder:
            self.video_recorder.stop_recording()
        if self.audio_recorder and getattr(self.audio_recorder, "recording", False):
            self.audio_recorder.recording = False
        if self.auto_thread and self.auto_thread.is_alive():
            if threading.current_thread() != self.auto_thread:
                self.auto_thread.join(timeout=2)
        self.master.responses = self.answers
        self.master.audio_files = self.audio_files
        self.master.show_frame(EvaluationPage)

    def finish_interview(self):
        self.interview_running = False
        if self.video_recorder:
            self.video_recorder.stop_recording()
        if self.audio_recorder and getattr(self.audio_recorder, "recording", False):
            self.audio_recorder.recording = False
        if self.auto_thread and self.auto_thread.is_alive():
            self.auto_thread.join(timeout=2)
        self.master.responses = self.answers
        self.master.audio_files = self.audio_files
        self.master.show_frame(EvaluationPage)

class EvaluationPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        tk.Label(self, text="Step 4: 면접 평가 및 피드백", font=("Arial", 22, "bold")).pack(pady=15)

        # 1) 영상/포즈 분석 영상(썸네일 및 버튼으로 영상 보기)
        self.video_thumb_label = tk.Label(self)
        self.video_thumb_label.pack(pady=5)
        tk.Button(self, text="영상 재생", command=self.open_video).pack(pady=3)
        tk.Button(self, text="자세 분석 결과 영상 재생", command=self.open_pose_video).pack(pady=3)

        # 2) 영상 분석 설명(텍스트)
        tk.Label(self, text="자세 분석 결과 설명", font=("Arial", 13, "bold")).pack(pady=4)
        self.pose_text = scrolledtext.ScrolledText(self, height=7, width=110, font=("Arial", 11))
        self.pose_text.pack(pady=4)

        # 3) 답변 평가/피드백
        tk.Label(self, text="답변 평가 및 피드백", font=("Arial", 13, "bold")).pack(pady=4)
        self.result_box = scrolledtext.ScrolledText(self, height=16, width=110, font=("Arial", 12))
        self.result_box.pack(pady=8)
        tk.Button(self, text="평가/피드백 보기", font=("Arial", 13), command=self.show_feedback).pack(pady=6)
        tk.Button(self, text="처음으로", font=("Arial", 13), command=lambda: master.show_frame(StartPage)).pack(pady=3)

    def tkraise(self, *args, **kwargs):
        self.result_box.delete("1.0", tk.END)
        self.pose_text.delete("1.0", tk.END)
        # 썸네일 생성(있으면)
        if os.path.exists(self.master.video_path):
            self.set_video_thumbnail(self.master.video_path)
        else:
            self.video_thumb_label.config(image="")
        super().tkraise(*args, **kwargs)

    def set_video_thumbnail(self, video_path):
        # OpenCV로 첫 프레임 썸네일 표시
        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        cap.release()
        if ret:
            img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(img)
            img = img.resize((240, 160))
            imgtk = ImageTk.PhotoImage(img)
            self.video_thumb_label.imgtk = imgtk
            self.video_thumb_label.config(image=imgtk)
        else:
            self.video_thumb_label.config(image="")

    def open_video(self):
        # 기본 동영상 플레이어로 실행
        if os.path.exists(self.master.video_path):
            os.startfile(self.master.video_path)
        else:
            messagebox.showinfo("동영상 없음", "녹화된 면접 영상 파일이 없습니다.")

    def open_pose_video(self):
        # 포즈 분석 영상 파일명(예시)
        pose_video = "pose_output.mp4"
        if os.path.exists(pose_video):
            os.startfile(pose_video)
        else:
            messagebox.showinfo("분석 영상 없음", "분석된 포즈 영상이 없습니다.")

    def show_feedback(self):
        self.result_box.delete("1.0", tk.END)
        self.pose_text.delete("1.0", tk.END)
        # 영상 분석 실행 (동기/비동기 처리 가능)
        video_path = self.master.video_path
        pose_log_path = "pose_feedback.txt"
        pose_video_path = "pose_output.mp4"  # 분석 영상 파일
        pose_desc = ""
        try:
            from pose_detection import analyze_video
            analyze_video(video_path, pose_log_path, output_video=pose_video_path)
            if os.path.exists(pose_log_path):
                with open(pose_log_path, "r", encoding="utf-8") as f:
                    pose_desc = f.read().strip()
                if not pose_desc:
                    pose_desc = "[분석 결과 없음] 영상에서 사람이 감지되지 않았거나, 분석 결과가 없습니다."
            else:
                pose_desc = "[분석 결과 없음] pose_feedback.txt 파일이 없습니다."
        except Exception as e:
            pose_desc = f"[자세 피드백 오류] 영상 분석 중 오류 발생: {e}\n"
        self.pose_text.insert(tk.END, pose_desc)

        # 답변 평가
        from interview_app.evaluation import evaluate_and_save_responses
        try:
            eval_results = evaluate_and_save_responses(
                self.master.questions,
                self.master.responses,
                self.master.audio_files
            )
        except Exception as e:
            self.result_box.insert(tk.END, f"[답변 평가 오류] 평가 중 오류 발생: {e}\n")
            return

        if not eval_results:
            self.result_box.insert(tk.END, "[답변 평가 실패] 평가 결과가 없습니다.\n")
            return

        self.result_box.insert(tk.END, "[답변 평가 및 추천 답변]\n")
        for i, result in enumerate(eval_results, 1):
            self.result_box.insert(tk.END, f"\nQ{i}. {result.get('question','')}\n")
            self.result_box.insert(tk.END, f"내 답변: {result.get('user_answer','')}\n")
            eval_section = result.get("evaluation", {})
            for k in ["relevance", "completeness", "correctness", "clarity", "professionalism"]:
                sec = eval_section.get(k, {})
                rating = sec.get("rating", "-")
                comment = sec.get("comment", "-")
                self.result_box.insert(tk.END, f"  [{k}] {rating} - {comment}\n")
            self.result_box.insert(tk.END, f"추천 답변: {result.get('recommended_answer','')}\n")
            self.result_box.insert(tk.END, f"총 답변 시간: {result.get('total_response_time','')}초, 침묵 시간: {result.get('silence_duration','')}초\n")


if __name__ == "__main__":
    app = App()
    app.mainloop()
