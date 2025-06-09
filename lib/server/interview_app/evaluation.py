# evaluation.py
# Evaluate candidate responses via LLM and save evaluation results to a text file

import json
import logging
from typing import List

from .llm_client import LLMClient
from .config import LlamaConfig
from .stt import STTClient, calculate_silence_duration, calculate_audio_duration

logger = logging.getLogger(__name__)

def evaluate_and_save_responses(
    questions: List[str],
    answers: List[str],
    audio_files: List[str],
    output_file: str = "interview_evaluation.txt"
) -> list:
    """
    Evaluate user responses using an LLM and save structured results to a TXT file.
    빈 답변 및 '그만하겠습니다' 트리거를 건너뛰고,
    모든 출력은 한국어로만 제공하도록 프롬프트를 조정합니다.
    각 평가 항목에 대해 점수를 계산하여 총점을 제공합니다.
    """
    llm_config = LlamaConfig()
    llm_client = LLMClient(llm_config)
    stt_client = STTClient()

    evaluations = []

    for idx, (question, answer, audio_path) in enumerate(zip(questions, answers, audio_files), start=1):
        # 1) '그만하겠습니다' 면접 종료 트리거 건너뛰기
        if answer.strip().lower() == "그만하겠습니다":
            logger.info(f"Skipping evaluation for exit trigger at Q{idx}")
            break

        # 2) 빈 답변에 대해서는 LLM 호출 없이 낮은 평가 처리
        if not answer.strip():
            try:
                total_time = calculate_audio_duration(audio_path)
                # 빈 답변의 경우 전체가 침묵으로 간주
                silence = total_time
            except Exception as e:
                logger.warning(f"Audio duration calculation failed for {audio_path}: {e}")
                total_time = 0.0
                silence = 0.0
                
            evaluations.append({
                "question": question,
                "user_answer": "",
                "evaluation": {
                    "relevance":      {"rating": "낮음", "comment": "응답이 제공되지 않았습니다."},
                    "completeness":   {"rating": "낮음", "comment": "응답이 제공되지 않았습니다."},
                    "correctness":    {"rating": "낮음", "comment": "응답이 제공되지 않았습니다."},
                    "clarity":        {"rating": "낮음", "comment": "응답이 제공되지 않았습니다."},
                    "professionalism":{"rating": "낮음", "comment": "응답이 제공되지 않았습니다."},
                },
                "recommended_answer": "",
                "total_response_time": total_time,
                "silence_duration":    silence,
                "total_score": 0  # 빈 답변은 0점
            })
            continue

        # 3) LLM 프롬프트: 한국어 강제, JSON 예시도 한글화 (엄격한 평가 기준)
        prompt = (
            "모든 출력은 *오직 한국어*로만 작성하십시오.\n"
            "당신은 까다로운 IT 회사의 숙련된 면접관이자 평가 전문가입니다.\n"
            "높은 수준의 답변만을 인정하며, 엄격한 기준으로 평가합니다.\n"
            "아래 면접 질문과 지원자의 답변을 기반으로 다음 다섯 가지 기준에 따라 **엄격하게** 평가하고,"
            "추천 답변을 제공해주세요.\n\n"
            "**평가 기준 (매우 엄격하게 적용):**\n"
            "1. 관련성: 답변이 질문의 핵심을 정확히 다루었는가? (애매한 답변은 낮음)\n"
            "2. 완전성: 답변에 필요한 모든 요소가 구체적으로 포함되었는가? (일반적인 답변은 낮음)\n"
            "3. 정확성: 정확한 사실과 논리에 기반한 내용인가? (추상적인 답변은 낮음)\n"
            "4. 명확성: 명료하고 논리적으로 구성되었는가? (어색한 표현은 낮음)\n"
            "5. 전문성: 면접에 적합한 전문적인 어조와 표현을 사용했는가? (반복이나 문법 오류는 낮음)\n\n"
            "**평가 등급 가이드:**\n"
            "- 높음: 탁월한 답변, 구체적이고 완벽한 내용\n"
            "- 보통: 기본적인 요구사항을 충족하는 평균적인 답변\n"
            "- 낮음: 부족하거나 개선이 필요한 답변\n\n"
            "**중요**: 대부분의 일반적인 답변은 '보통' 또는 '낮음'으로 평가하세요.\n"
            "'높음' 평가는 정말 우수한 답변에만 부여하세요.\n\n"
            f"Question:\n{question}\n\n"
            f"Candidate's Answer:\n{answer}\n\n"
            "출력 예시(모든 키는 영어, 평가는 한글로 작성):\n"
            "{\n"
            '  "evaluation": {\n'
            '    "relevance":      {"rating": "높음",   "comment": "..."},\n'
            '    "completeness":   {"rating": "보통",   "comment": "..."},\n'
            '    "correctness":    {"rating": "높음",   "comment": "..."},\n'
            '    "clarity":        {"rating": "낮음",   "comment": "..."},\n'
            '    "professionalism":{"rating": "높음",   "comment": "..."}\n'
            "  },\n"
            '  "recommended_answer": "..." \n'
            "}\n"
        )

        # 4) LLM 호출 및 JSON 파싱
        try:
            raw = llm_client.call(prompt)
            print(f"🔍 LLM 원시 응답: {raw[:200]}...")
            data = json.loads(raw)
            eval_obj = data.get("evaluation", {})
            rec_answer = data.get("recommended_answer", "")
            print(f"✅ JSON 파싱 성공, evaluation 타입: {type(eval_obj)}")
        except Exception as e:
            logger.error(f"LLM evaluation failed for question {idx}: {e}")
            print(f"❌ LLM/JSON 파싱 오류: {e}")
            # 기본 평가 구조 제공
            eval_obj = {
                "relevance":      {"rating": "분석불가", "comment": "AI 분석 오류로 평가할 수 없습니다."},
                "completeness":   {"rating": "분석불가", "comment": "AI 분석 오류로 평가할 수 없습니다."},
                "correctness":    {"rating": "분석불가", "comment": "AI 분석 오류로 평가할 수 없습니다."},
                "clarity":        {"rating": "분석불가", "comment": "AI 분석 오류로 평가할 수 없습니다."},
                "professionalism":{"rating": "분석불가", "comment": "AI 분석 오류로 평가할 수 없습니다."},
            }
            rec_answer = "AI 분석 오류로 추천 답변을 제공할 수 없습니다."

        # === 점수 계산 추가 ===
        total_score = calculate_score_from_evaluation(eval_obj)
        print(f"📊 계산된 점수: {total_score}점")

        # 5) 오디오 지표 계산
        try:
            # STT 결과에서 침묵 시간 계산 (단어 타임스탬프 필요)
            stt_timestamps = stt_client.transcribe(audio_path)
            if stt_timestamps:
                silence = calculate_silence_duration(stt_timestamps)
            else:
                silence = 0.0
        except Exception as e:
            logger.warning(f"Silence calculation failed for {audio_path}: {e}")
            silence = 0.0

        try:
            total_time = calculate_audio_duration(audio_path)
        except Exception as e:
            logger.warning(f"Audio duration calculation failed for {audio_path}: {e}")
            total_time = 0.0

        evaluations.append({
            "question": question,
            "user_answer": answer,
            "evaluation": eval_obj,
            "recommended_answer": rec_answer,
            "total_response_time": total_time,
            "silence_duration": silence,
            "total_score": total_score  # 총점 추가
        })

    # 6) 파일로 출력
    try:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("면접 평가 결과\n")
            f.write("=" * 50 + "\n\n")
            for i, item in enumerate(evaluations, start=1):
                # 안전한 데이터 추출
                question = item.get('question', '질문 정보 없음')
                user_answer = item.get('user_answer', '답변 정보 없음')
                recommended_answer = item.get('recommended_answer', '추천 답변 없음')
                total_time = item.get('total_response_time', 0)
                silence = item.get('silence_duration', 0)
                total_score = item.get('total_score', 0)  # 총점 가져오기
                
                f.write(f"질문 {i}:\n{question}\n\n")
                f.write(f"사용자 답변:\n{user_answer}\n\n")
                f.write("평가 결과:\n")
                
                # 평가 데이터 안전 처리
                evaluation_data = item.get("evaluation", {})
                try:
                    if isinstance(evaluation_data, dict):
                        for crit, res in evaluation_data.items():
                            try:
                                if isinstance(res, dict):
                                    rating = res.get('rating', '정보없음')
                                    comment = res.get('comment', '평가 정보가 없습니다.')
                                    f.write(f"  {crit}: {rating} - {comment}\n")
                                elif isinstance(res, str):
                                    f.write(f"  {crit}: {res}\n")
                                else:
                                    f.write(f"  {crit}: {str(res)}\n")
                            except Exception as e:
                                f.write(f"  {crit}: 평가 데이터 처리 오류 - {str(e)}\n")
                    else:
                        f.write(f"  평가 데이터 형식 오류: {type(evaluation_data)} - {str(evaluation_data)}\n")
                except Exception as e:
                    f.write(f"  평가 데이터 전체 처리 오류: {str(e)}\n")
                
                f.write("\n")
                f.write(f"총점: {total_score}점\n")  # 총점 표시 추가
                
                # 점수에 따른 등급 표시 (더 엄격한 기준)
                if total_score >= 95:
                    grade = "A+ (탁월)"
                elif total_score >= 90:
                    grade = "A (우수)"
                elif total_score >= 85:
                    grade = "A- (좋음)"
                elif total_score >= 80:
                    grade = "B+ (양호)"
                elif total_score >= 75:
                    grade = "B (평균)"
                elif total_score >= 70:
                    grade = "B- (평균 이하)"
                elif total_score >= 65:
                    grade = "C+ (부족)"
                elif total_score >= 60:
                    grade = "C (개선 필요)"
                else:
                    grade = "F (미흡)"
                
                f.write(f"등급: {grade}\n\n")
                f.write(f"추천 답변:\n{recommended_answer}\n\n")
                f.write(f"답변 시간: {total_time} 초\n")
                f.write(f"침묵 시간: {silence} 초\n")
                f.write("\n" + "=" * 50 + "\n")
        logger.info(f"Evaluation results saved to {output_file}")
    except Exception as e:
        logger.error(f"Failed to write evaluation file {output_file}: {e}")
        print(f"❌ 파일 출력 중 오류: {e}")
        # 오류가 발생해도 빈 파일이라도 생성하여 후속 처리가 가능하도록 함
        try:
            with open(output_file, "w", encoding="utf-8") as f:
                f.write("면접 평가 결과\n")
                f.write("=" * 50 + "\n\n")
                f.write("평가 중 오류가 발생했습니다.\n")
                f.write(f"오류 내용: {str(e)}\n")
        except:
            pass
        # 여전히 오류를 발생시키지만 더 안전한 형태로
        raise Exception(f"평가 파일 생성 실패: {str(e)}")

    # 7) GUI/다른 호출자를 위해 평가 결과 반환
    return evaluations

def calculate_score_from_evaluation(evaluation_obj):
    """
    평가 결과에서 숫자 점수를 계산합니다.
    각 평가 항목의 rating을 점수로 변환하여 총점을 계산합니다.
    더 엄격한 기준을 적용하여 정확한 평가를 제공합니다.
    """
    try:
        if not isinstance(evaluation_obj, dict):
            return 0
        
        # 각 평가 항목별 점수 매핑 (더 엄격한 기준 적용)
        rating_scores = {
            "매우 높음": 18,    # 탁월한 평가 (거의 완벽)
            "높음": 14,         # 우수한 평가 (좋은 수준)
            "보통": 10,         # 평균적인 평가 (기본 수준)
            "낮음": 6,          # 부족한 평가 (개선 필요)
            "매우 낮음": 2,     # 매우 부족한 평가 (심각한 문제)
            "분석불가": 0       # 분석 오류 (점수 없음)
        }
        
        # 기존 3단계 평가도 지원 (하위 호환성)
        if any(rating in ["높음", "보통", "낮음"] for rating in 
               [evaluation_obj.get(k, {}).get('rating', '') for k in evaluation_obj.keys()]):
            rating_scores.update({
                "높음": 12,     # 기존 "높음"을 더 엄격하게
                "보통": 8,      # 기존 "보통"을 더 엄격하게  
                "낮음": 4,      # 기존 "낮음"을 더 엄격하게
            })
        
        total_score = 0
        evaluated_items = 0
        
        # 5개 평가 항목별 가중치 적용
        evaluation_criteria = {
            "relevance": 1.2,      # 관련성 (가장 중요)
            "completeness": 1.1,   # 완전성 (중요)
            "correctness": 1.1,    # 정확성 (중요)
            "clarity": 1.0,        # 명확성 (기본)
            "professionalism": 0.8 # 전문성 (기본보다 낮음)
        }
        
        for criterion, weight in evaluation_criteria.items():
            if criterion in evaluation_obj:
                criterion_data = evaluation_obj[criterion]
                if isinstance(criterion_data, dict):
                    rating = criterion_data.get('rating', '낮음')
                    base_score = rating_scores.get(rating, 4)  # 기본값을 더 낮게
                    weighted_score = base_score * weight
                    total_score += weighted_score
                    evaluated_items += 1
                    print(f"  - {criterion}: {rating} ({base_score}점 × {weight} = {weighted_score:.1f}점)")
        
        # 최종 점수 계산 (100점 만점으로 변환)
        if evaluated_items > 0:
            # 최대 가능 점수 계산 (매우 높음 18점 기준)
            max_possible_score = sum(18 * weight for weight in evaluation_criteria.values())
            # 100점 만점으로 환산
            final_score = int((total_score / max_possible_score) * 100)
            final_score = max(0, min(100, final_score))  # 0-100 범위 제한
        else:
            final_score = 0
            
        print(f"📊 최종 계산: {total_score:.1f}점 → {final_score}점 (100점 만점)")
        return final_score
        
    except Exception as e:
        print(f"⚠️ 점수 계산 중 오류: {e}")
        return 0
