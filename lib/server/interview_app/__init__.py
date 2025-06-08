# __init__.py
# Interview application package initializer

"""
Package entry point for the interview_app modules.
Expose core classes and functions for easy import.
"""

from .config import (
    LlamaConfig,
    AudioConfig,
    VideoConfig,
    STTConfig,
    CLIConfig,
)
from .prompts import PARSER_PROMPT, QUESTION_PROMPT
from .pdf_utils import extract_text, cleanup_text
from .llm_client import LLMClient, clean_llm_response
from .resume_parser import ResumeJsonParser
from .question_maker import InterviewQuestionMaker
from .video_recorder import VideoRecorder
# from .audio_recorder import AudioRecorder  # 오디오 패키지 의존성 문제로 임시 비활성화
from .stt import STTClient, calculate_silence_duration, calculate_audio_duration
from .evaluation import evaluate_and_save_responses
# from .interview_flow import (  # 실시간 면접용이라 영상 평가에는 불필요
#     start_full_interview,
#     display_questions_with_tts_and_evaluation,
# )

__all__ = [
    # Configs
    "LlamaConfig", "AudioConfig", "VideoConfig", "STTConfig", "CLIConfig",
    # Prompts
    "PARSER_PROMPT", "QUESTION_PROMPT",
    # PDF Utils
    "extract_text", "cleanup_text",
    # LLM Client
    "LLMClient", "clean_llm_response",
    # Parsers
    "ResumeJsonParser",
    # Question Maker
    "InterviewQuestionMaker",
    # Recorders
    "VideoRecorder", # "AudioRecorder",  # 임시 비활성화
    # STT
    "STTClient", "calculate_silence_duration", "calculate_audio_duration",
    # Evaluation
    "evaluate_and_save_responses",
    # Flow (현재 사용 안함)
    # "start_full_interview", "display_questions_with_tts_and_evaluation",
]
