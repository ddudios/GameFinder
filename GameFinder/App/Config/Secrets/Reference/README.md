# Game Finder 🎮

## 📱 앱 소개
**한줄소개**
전 세계 게임 정보를 검색하고, 출시 예정 게임을 추적하며, 게임 플레이 다이어리를 기록할 수 있는 게임 정보 플랫폼

**앱스토어 링크**
🔗 [앱스토어 링크](https://apps.apple.com/app/game-finder) _(심사 대기 중)_

---

## ✨ 핵심 기능

- **게임 검색 및 상세 정보 조회** - RAWG API를 통한 50만개 이상의 게임 정보 제공
- **출시 예정 게임 추적** - 관심 게임의 출시일 하루 전 푸시 알림 전송
- **게임 다이어리 작성** - 게임별로 플레이 기록, 감상평, 사진/동영상 저장
- **즐겨찾기 기능** - 마음에 드는 게임을 북마크하여 빠른 접근
- **플랫폼별 게임 필터링** - PlayStation, Xbox, Nintendo, PC 등 플랫폼별 게임 조회
- **다국어 지원** - 한국어, 영어, 일본어 지원으로 글로벌 사용자 대응

---

## 🛠 기술스택

### Architecture & Design Pattern
- **MVVM** - ViewModel을 통한 비즈니스 로직 분리
- **Repository Pattern** - 데이터 레이어 추상화 및 단일 책임 원칙 구현
- **Singleton Pattern** - Manager 클래스를 통한 전역 상태 관리

### Framework & Library
- **RxSwift / RxCocoa** - 반응형 프로그래밍 및 비동기 처리
- **SnapKit** - Auto Layout 코드 작성 간소화
- **RealmSwift** - 로컬 데이터베이스 관리 (즐겨찾기, 다이어리, 알림)
- **Alamofire** - REST API 네트워크 통신
- **Kingfisher** - 이미지 다운로드 및 캐싱
- **Firebase Analytics & Crashlytics** - 사용자 행동 분석 및 크래시 추적
- **OSLog** - 구조화된 로깅 시스템

### UI
- **UICollectionView DiffableDataSource** - 선언적 UI 업데이트
- **UICollectionView CompositionalLayout** - 복잡한 레이아웃 구현
- **Custom Fonts** - 87MMILSANG, NanumBarunGothic

### Others
- **Localization (L10n)** - 다국어 지원 시스템
- **UserNotifications** - 로컬 및 원격 푸시 알림
- **AVFoundation** - 다이어리 사진 촬영 및 편집

---

## 🔥 기술 포인트

### 1. **OSLog + Firebase Analytics 통합 로깅 시스템**
```swift
final class LogManager {
    static let network = Logger(subsystem: "GameFinder", category: "Network")
    static let userAction = Logger(subsystem: "GameFinder", category: "UserAction")

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        network.debug("📊 Analytics Event: \(name)")
        #endif
        Analytics.logEvent(name, parameters: parameters)
    }
}
```
- **OSLog**를 활용한 카테고리별 구조화된 로깅 (Network, Database, UserAction, UI, Error)
- **Firebase Analytics**와 통합하여 개발 환경에서는 디버그 로그, 프로덕션에서는 분석 데이터 전송
- 사용자 행동 패턴 분석 및 크래시 추적을 통한 앱 안정성 향상

### 2. **Repository Pattern + RxSwift를 활용한 반응형 데이터 레이어**
```swift
protocol GameRepository {
    func observeFavorites() -> Observable<[Game]>
    func saveOrUpdateGame(_ game: Game) -> Bool
}

final class RealmGameRepository: GameRepository {
    func observeFavorites() -> Observable<[Game]> {
        return Observable.create { observer in
            let results = self.realm.objects(RealmGame.self)
                .where { $0.isFavorite == true }
            let token = results.observe { changes in
                observer.onNext(Array(results.map { $0.toDomain() }))
            }
            return Disposables.create { token.invalidate() }
        }
    }
}
```
- **Repository Pattern**으로 데이터 레이어를 추상화하여 Realm 의존성 분리
- **RxSwift Observable**을 통해 Realm 데이터 변경사항을 실시간으로 UI에 반영
- **즐겨찾기, 알림, 다이어리** 등 모든 로컬 데이터를 단일 인터페이스로 관리

### 3. **UNCalendarNotificationTrigger를 활용한 날짜 기반 로컬 알림 스케줄링**
```swift
func scheduleLocalNotification(for game: Game) {
    // 출시일 하루 전 오후 6시 계산
    var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: releaseDate)
    dateComponents.hour = 18
    dateComponents.minute = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
    let request = UNNotificationRequest(identifier: "game_\(game.id)", content: content, trigger: trigger)
    notificationCenter.add(request)
}
```
- **UNCalendarNotificationTrigger**를 사용하여 특정 날짜/시간에 알림 전송
- 게임 출시일 하루 전 **오후 6시**에 자동으로 알림 발송
- 전역 알림 설정에 따라 모든 알림을 **일괄 재스케줄링** 또는 취소

---

## 📅 한달 내 업데이트 예정 기능

- **Widget 지원** - 홈 화면에서 출시 예정 게임 확인
- **iPad 대응** - Split View 및 태블릿 최적화 UI
- **다크모드 최적화** - 커스텀 색상 팔레트 개선
- **게임 추천 알고리즘** - 사용자 취향 기반 게임 추천

---

## 📂 프로젝트 구조

```
GameFinder/
├── App/
│   ├── Application/          # AppDelegate, SceneDelegate
│   ├── Features/             # Feature별 MVVM 구조
│   │   ├── Find/            # 게임 검색 및 탐색
│   │   ├── Detail/          # 게임 상세 정보
│   │   ├── Library/         # 즐겨찾기 및 알림 관리
│   │   ├── Diary/           # 게임 다이어리
│   │   └── Settings/        # 설정
│   └── Support/             # Info.plist, Launch Screen
├── Data/
│   ├── Network/             # Alamofire Router, NetworkManager
│   └── Model/               # API Response Models
├── Shared/
│   ├── Utils/
│   │   ├── Managers/        # NotificationManager, LogManager
│   │   ├── Repository/      # RealmGameRepository
│   │   └── Localization/    # L10n, Localizable.strings
│   └── UIComponents/        # CustomButton, BaseViewController
└── Resources/               # Assets, Fonts
```

---

## 🔑 설치 및 실행

### 1. 프로젝트 클론
```bash
git clone https://github.com/yourusername/GameFinder.git
cd GameFinder
```

### 2. API Key 설정
`Config.xcconfig` 파일에 RAWG API Key 추가:
```
RAWG_Base_URL = https://api.rawg.io/api
RAWG_Client_Key = YOUR_API_KEY_HERE
```

### 3. Firebase 설정
1. Firebase Console에서 프로젝트 생성
2. `GoogleService-Info.plist` 다운로드 후 프로젝트에 추가
3. Analytics 및 Crashlytics 활성화

### 4. 빌드 및 실행
```bash
open GameFinder.xcodeproj
# Xcode에서 Command + R로 실행
```

---

## 📸 스크린샷

<img src="GameFinder/App/Config/Secrets/Referance/SearchView.jpeg" width="200"> <img src="GameFinder/App/Config/Secrets/Referance/SettingView.jpeg" width="200"> <img src="GameFinder/App/Config/Secrets/Referance/HeaderDetail.jpeg" width="200">

---

## 👤 개발자

**Suji Jang**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 있습니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

## 🙏 감사의 말

- [RAWG API](https://rawg.io/apidocs) - 게임 데이터 제공
- [Firebase](https://firebase.google.com/) - Analytics 및 Crashlytics 제공
