# Log:B - 스마트 인맥 관리 & AI 미팅 리포트 앱

**Log:B**는 Flutter로 개발된 차세대 B2B 영업 인맥 관리 및 AI 기반 미팅 리포트 앱입니다.

## 🎯 주요 기능

### 📇 인맥 디렉토리 (Master Directory)
- 거래처 및 인맥을 한눈에 관리
- 태그 기반 분류 시스템 (#VIP, #가망, #신규 등)
- 빠른 검색 기능

### 📅 통합 일정
- 미팅 및 일정 통합 관리
- 거래처별 일정 추적

### 🤖 AI 미팅 리포트
- Gemini AI가 생성하는 미팅 요약
- 영업 동료 스타일의 친근한 인사이트
- 거래처별 히스토리 추적

### ⚙️ 설정
- 프로필 관리
- 알림 설정
- 보안 설정
- 도움말 및 FAQ

## 🎨 디자인 특징

- **모던한 UI/UX**: Material 3 기반의 세련된 인터페이스
- **커스텀 로고**: Canvas로 그려진 독창적인 Log:B 로고
- **부드러운 애니메이션**: 네비게이션 및 인터랙션 애니메이션
- **브랜드 컬러**: 
  - Primary Blue (#2563EB)
  - Indigo (#4F46E5)
  - Neon Lime Accent (#CCFF00)

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK 3.38.5 이상
- Dart 3.10.4 이상

### 설치 방법

1. **패키지 설치**
```bash
flutter pub get
```

2. **앱 실행**
```bash
# iOS 시뮬레이터
flutter run

# Android 에뮬레이터
flutter run

# 특정 디바이스
flutter devices  # 디바이스 목록 확인
flutter run -d <device-id>
```

## 🔑 Firebase 및 Gemini AI 설정

### Firebase 설정 (선택사항)

1. **FlutterFire CLI 설치**
```bash
dart pub global activate flutterfire_cli
```

2. **Firebase 프로젝트 연동**
```bash
flutterfire configure
```

3. **코드에서 Firebase 활성화**
`lib/main.dart`에서 다음 주석을 해제:
```dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Gemini AI 설정

`lib/main.dart`의 `AIService` 클래스에서 API 키 설정:
```dart
class AIService {
  static const String _apiKey = "YOUR_GEMINI_API_KEY"; // 여기에 API 키 입력
  ...
}
```

Gemini API 키는 [Google AI Studio](https://makersuite.google.com/app/apikey)에서 발급받을 수 있습니다.

## 📦 사용된 패키지

- `firebase_core: ^3.8.1` - Firebase 핵심 기능
- `cloud_firestore: ^5.6.0` - Firestore 데이터베이스
- `http: ^1.2.2` - HTTP 요청 (Gemini API 호출)
- `cupertino_icons: ^1.0.8` - iOS 스타일 아이콘

## 🏗️ 프로젝트 구조

```
lib/
├── main.dart           # 메인 앱 진입점
│   ├── LogBColors      # 브랜드 컬러 정의
│   ├── LogBLogo        # 커스텀 로고 위젯
│   ├── LogoPainter     # 로고 Canvas 페인터
│   ├── MainNavigationScreen  # 메인 네비게이션
│   ├── DirectoryScreen       # 인맥 디렉토리
│   ├── ScheduleScreen        # 일정 관리
│   ├── ReportsScreen         # AI 리포트
│   ├── SettingsScreen        # 설정
│   └── AIService             # Gemini AI 서비스
```

## 🧪 테스트

```bash
# 위젯 테스트 실행
flutter test

# 코드 분석
flutter analyze
```

## 📱 지원 플랫폼

- ✅ iOS
- ✅ Android
- 🚧 Web (준비 중)
- 🚧 Desktop (준비 중)

## 🎯 다음 단계

- [ ] Firebase Authentication 통합
- [ ] Firestore 데이터 동기화
- [ ] 연락처 추가/수정/삭제 기능
- [ ] 미팅 일정 추가 기능
- [ ] AI 리포트 생성 및 저장
- [ ] 푸시 알림 기능
- [ ] 오프라인 모드 지원

## 📄 라이선스

이 프로젝트는 개인 프로젝트입니다.

## 👥 기여

기여를 환영합니다! Issue나 Pull Request를 자유롭게 제출해주세요.

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해주세요.

---

**Made with ❤️ by Log:B Team**
# log-b
