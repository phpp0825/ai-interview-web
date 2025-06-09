# 🎯 AInterview

## 📋 프로젝트 소개

**AInterview**는 면접자가 실전과 같은 환경에서 면접을 연습할 수 있도록 도와주는 웹 애플리케이션입니다. AI 기술을 활용하여 자세 분석, 답변 평가, 실시간 피드백을 제공합니다.

### ✨ 주요 기능

- **📝 이력서 작성**: 체계적인 이력서 입력 및 관리
- **🎥 면접 연습**: 실시간 영상 녹화 및 면접 진행
- **🤖 AI 자세 분석**: MediaPipe를 활용한 실시간 포즈 디텍션
- **💡 답변 평가**: OpenAI GPT를 통한 면접 답변 분석
- **📊 상세 보고서**: 점수, 피드백, 개선점 제시

## 🛠️ 기술 스택

### **프론트엔드**

- **Flutter Web**: 크로스 플랫폼 웹 개발
- **Firebase Authentication**: 구글 로그인
- **Firebase Firestore**: 실시간 데이터베이스
- **Firebase Storage**: 영상 파일 저장
- **Camera Web**: 웹 카메라 녹화
- **Video Player**: 영상 재생
- **FL Chart**: 데이터 시각화

### **백엔드**

- **Python FastAPI**: REST API 서버
- **MediaPipe**: AI 포즈 분석
- **OpenCV**: 영상 처리
- **OpenAI API**: GPT 기반 답변 평가

## 🚀 설치 및 실행

### **1. 사전 요구사항**

```bash
# Flutter 설치 확인
flutter doctor

# Python 3.8+ 설치 확인
python --version
```

### **2. 프론트엔드 설정**

```bash
# 프로젝트 클론
git clone <repository-url>
cd ai-interview-web

# Flutter 패키지 설치
flutter pub get

# Firebase 설정 (firebase_options.dart 파일 필요)
# Firebase Console에서 프로젝트 생성 후 설정 파일 다운로드

# 웹 앱 실행
flutter run -d chrome
```

### **3. 백엔드 설정**

```bash
# Python 가상환경 생성
cd lib/server
python -m venv venv

# 가상환경 활성화 (Windows)
venv\Scripts\activate
# 가상환경 활성화 (Mac/Linux)
source venv/bin/activate

# 패키지 설치
pip install -r requirements.txt

# 환경변수 설정 (.env 파일 생성)
# OPENAI_API_KEY=your_openai_api_key

# 서버 실행
python unified_api.py
```

## 📁 프로젝트 구조

```
ai-interview-web/
├── 📱 lib/ (Flutter 앱)
│   ├── views/              # 화면 UI
│   │   ├── landing_view.dart
│   │   ├── login_view.dart
│   │   ├── home_view.dart
│   │   ├── resume_view.dart
│   │   ├── interview_view.dart
│   │   └── report_list_view.dart
│   ├── widgets/            # 재사용 컴포넌트
│   │   ├── common/
│   │   ├── dashboard/
│   │   ├── interview/
│   │   ├── login/
│   │   ├── report/
│   │   └── resume/
│   ├── services/           # API 통신 서비스
│   │   ├── auth/
│   │   ├── interview/
│   │   ├── report/
│   │   └── resume/
│   ├── controllers/        # 상태 관리
│   ├── models/            # 데이터 모델
│   ├── repositories/      # 데이터 레포지토리
│   └── core/              # 공통 설정
├── 🐍 lib/server/ (Python 백엔드)
│   ├── unified_api.py          # 메인 API 서버
│   ├── pose_detection.py       # AI 포즈 분석
│   ├── requirements.txt        # Python 패키지
│   ├── uploads/               # 업로드 파일 저장
│   └── logs/                  # 분석 로그
├── 🔥 Firebase 설정
│   ├── firebase.json
│   └── firebase_options.dart
└── 📱 플랫폼별 설정
    ├── android/
    ├── ios/
    ├── web/
    └── windows/
```

## 🎯 화면별 기능

### **🏠 메인 화면**

- 대시보드 및 주요 기능 접근
- 최근 면접 기록 확인

### **📝 이력서 화면**

- 개인정보, 학력, 경력 입력
- 실시간 저장 및 유효성 검사

### **🎥 면접 화면**

- 실시간 영상 녹화
- 가상의 AI 면접관
- Firebase Storage 업로드

### **📊 보고서 화면**

### **포즈 분석 (MediaPipe)**

- ✅ 몸 흔들림 감지
- ✅ 자세 교정 (허리, 어깨)
- ✅ 시선 방향 추적
- ✅ 다리 위치 체크

### **답변 평가 (OpenAI GPT)**

- ✅ 답변 관련성 분석
- ✅ 완성도 평가
- ✅ 명확성 체크
- ✅ 전문성 판단
- ✅ 개선 방안 제시
