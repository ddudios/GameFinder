# GameFinder 기능 분석 포트폴리오

> 분석 범위: `개발 환경 분리`, `위젯`, `로컬라이제이션`, `크래시틱스`, `애널리틱스`, `로컬 노티`, `문의(이메일 자동)`  
> 참고: 요청하신 “크리시틱스”는 코드 기준으로 `Firebase Crashlytics`로 해석해 분석했습니다.

### 📱 구현 기능 요약
- GameFinder는 게임 탐색 앱의 핵심 흐름(탐색/상세/보관함/설정) 위에 운영 안정성 기능(환경 분리, 로깅·분석, 장애 추적, 알림, 위젯, 다국어, 문의 자동화)을 얹은 구조입니다.
- 사용자 관점에서는 “게임 발견 → 관심 등록 → 출시 알림/위젯 확인 → 문제 발생 시 문의”까지 한 사이클이 끊기지 않게 설계되어 있습니다.
- 개발 관점에서는 MVVM + Rx 중심의 화면 계층과, Repository + Realm 중심의 데이터 계층을 분리해 기능 확장을 빠르게 할 수 있게 구성했습니다.

- 핵심 기능 목록
- Debug/Release 번들/앱아이콘/스킴 기반 개발 환경 분리
- App Group 기반 앱-위젯 데이터 공유 및 위젯 딥링크
- String Catalog(`.xcstrings`) + `L10n` + InfoPlist 다국어 처리
- Firebase Crashlytics 연동(dSYM 업로드 스크립트 포함)
- Firebase Analytics 이벤트 래핑 및 사용자 액션 추적
- 출시일 기준 로컬 알림 스케줄링/재스케줄링/뱃지 재정렬
- 문의 메일 자동 작성(앱/디바이스 정보 자동 첨부 + 실패 시 클립보드 fallback)

### 🛠 기술 스택 및 적용 이유
- 사용 기술 목록
- UI: `UIKit`, `SnapKit`, `DiffableDataSource`, `CompositionalLayout`
- 아키텍처: `MVVM`, `RxViewModelProtocol`, `Repository Pattern`, Manager Singleton
- 상태/비동기: `RxSwift/RxCocoa` + 일부 `async/await`(WidgetDataService)
- 네트워크: `Alamofire`, `RawgRouter`, `NetworkObservable`
- 데이터: `RealmSwift`(즐겨찾기/알림/읽기/다이어리)
- 이미지: `Kingfisher`(앱), App Group 파일 저장(위젯)
- 캘린더: `FSCalendar`
- 분석/장애: `Firebase Analytics`, `Firebase Crashlytics`, `OSLog`
- 알림/문의: `UserNotifications`, `MessageUI`

- 각 기술 선택 이유 (신입 개발자 관점)
- `RxSwift/RxCocoa`: 사용자 입력/페이지네이션/필터 변경 같은 UI 이벤트를 선언형으로 연결해 화면 복잡도를 낮추기 좋았습니다.
- `Repository + Realm`: 로컬 상태(좋아요/알림/기록)를 기능별로 빠르게 붙이면서도 DB 접근 코드를 한곳으로 모아 유지보수성을 확보했습니다.
- `Alamofire Router`: API 엔드포인트/쿼리 조합을 타입으로 통제해 실수(파라미터 누락, 경로 오타)를 줄였습니다.
- `Firebase Analytics/Crashlytics`: 출시 후 사용자 행동/장애 데이터를 즉시 확보해 빠른 이터레이션이 가능했습니다.
- `WidgetKit + App Group`: 재방문 유도(홈화면 노출)와 앱 진입률 개선을 동시에 노린 선택입니다.

- 아키텍처 구조 설명
- `ViewController`는 UI 이벤트를 Relay로 발행하고, `ViewModel.transform(input:)`이 이를 처리해 `Output(BehaviorRelay/Driver)`을 제공합니다.
- 네트워크 응답(`DTO`)은 도메인 모델(`Game`, `GameDetail`)로 변환 후 UI/저장 계층으로 전달됩니다.
- 로컬 데이터는 `RealmGameRepository`가 CRUD/관찰(`Observable`)을 담당하고, 상위 `Favorite/Notification/Reading/DiaryManager`가 유스케이스를 조합합니다.

### 💡 주요 구현 내용
- **[개발 환경 분리]**
- 구현 방식 설명
- `Base.xcconfig`에서 `Secrets.xcconfig`를 include해 민감 설정을 분리하고, `Info.plist`에는 빌드 변수(`$(RAWG_*)`)를 주입했습니다.
- Debug/Release에서 `BUNDLE_ID_SUFFIX`, `BUNDLE_NAME`, `AppIcon`을 분리해 DEV 앱과 운영 앱을 동시에 설치 가능한 구조입니다.
- 핵심 코드 스니펫
```swift
// GameFinder/App/Config/Base.xcconfig
#include? "Secrets/Secrets.xcconfig"

// GameFinder/App/Support/Info.plist
<key>RAWGBaseUrl</key>
<string>$(RAWG_Base_URL)</string>
<key>RAWGClientKey</key>
<string>$(RAWG_Client_Key)</string>

// GameFinder/Data/Network/Router/RawgRouter.swift
private var baseURL: URL { URL(string: Bundle.getAPIKey(for: .rawgBaseUrl))! }
private var apiKey: String { Bundle.getAPIKey(for: .rawgClientKey) }
```
- 기술적 의사결정 과정
- API 상수 하드코딩 대신 빌드 설정을 통해 교체 가능하게 만들어 배포 환경 전환 비용을 낮췄습니다.

- **[위젯(App Group + Timeline + 딥링크)]**
- 구현 방식 설명
- 앱은 `WidgetDataService`에서 RAWG API를 비동기로 호출해 `SharedWidgetData`를 App Group에 저장하고 `WidgetCenter.reloadAllTimelines()`를 요청합니다.
- 위젯은 네트워크 호출 없이 App Group 데이터만 읽어 Timeline을 구성하고, 항목 탭 시 `gamefinder://game/{id}` 딥링크로 상세 화면 진입합니다.
- 핵심 코드 스니펫
```swift
// GameFinder/Services/WidgetDataService.swift
func updateWidgetData() async {
    let upcomingGames = try await fetchUpcomingGamesFromAPI()
    var sharedGames: [SharedWidgetGame] = []
    for game in upcomingGames.prefix(10) {
        let sharedGame = SharedWidgetGame.from(dto: game)
        sharedGames.append(sharedGame)
    }
    let widgetData = SharedWidgetData(games: sharedGames, lastUpdated: Date())
    AppGroupManager.shared.saveWidgetData(widgetData)
    WidgetCenter.shared.reloadAllTimelines()
}

// GameFinderWidget/GameFinderWidget.swift
if let sharedData = AppGroupManager.shared.loadWidgetData(),
   let randomGame = sharedData.games.randomElement() {
    entries.append(DailyShuffleEntry(date: startOfDay, game: randomGame, languageCode: languageCode, isPlaceholder: false))
}
```
- 기술적 의사결정 과정
- WidgetKit 제한(위젯 내 네트워크 지양)에 맞춰 “앱에서 수집/가공 → 위젯은 렌더링 전용”으로 책임을 분리했습니다.

- **[로컬라이제이션(앱 + 위젯 동기화)]**
- 구현 방식 설명
- 앱 문자열은 `Localizable.xcstrings` + `L10n` 래퍼로 접근하고, 언어 변경 시 `AppleLanguages`와 App Group에 언어 코드를 함께 저장해 위젯까지 동일 언어를 적용합니다.
- 앱 이름도 `InfoPlist.strings`(ko/en/ja)로 분기합니다.
- 핵심 코드 스니펫
```swift
// GameFinder/App/Features/Settings/SettingViewController.swift
private func changeLanguage(to languageCode: String) {
    UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
    AppGroupManager.shared.saveLanguage(languageCode) // 위젯 동기화
}

// GameFinderWidget/GameFinderWidget.swift
func localizedString(_ key: String, languageCode: String?) -> String {
    guard let languageCode,
          let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
          let bundle = Bundle(path: bundlePath) else {
        return NSLocalizedString(key, comment: "")
    }
    return NSLocalizedString(key, bundle: bundle, comment: "")
}
```
- 기술적 의사결정 과정
- 앱과 위젯이 서로 다른 프로세스라는 제약 때문에 “공유 저장소(App Group)로 언어 상태 전달” 방식을 선택했습니다.

- **[크래시틱스 + 애널리틱스]**
- 구현 방식 설명
- `FirebaseApp.configure()`로 Firebase를 초기화하고, Crashlytics run script로 dSYM 업로드 경로를 빌드 단계에 포함해 심볼화 기반 크래시 분석이 가능하도록 구성했습니다.
- Analytics는 `LogManager`에서 래핑해 이벤트 명/파라미터 규칙을 중앙집중화했습니다.
- 핵심 코드 스니펫
```swift
// GameFinder/App/Application/AppDelegate.swift
FirebaseApp.configure()

// GameFinder/Shared/Utils/LogManager.swift
static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
    #if DEBUG
    network.debug("Analytics Event: \(name), parameters: \(String(describing: parameters))")
    #endif
    Analytics.logEvent(name, parameters: parameters)
}

// GameFinder.xcodeproj/project.pbxproj (Run Script)
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```
- 기술적 의사결정 과정
- 화면/행동 로깅 코드를 흩뿌리지 않고 단일 레이어로 모아 이벤트 네이밍 일관성과 운영 가시성을 확보했습니다.

- **[로컬 노티(출시일 기반)]**
- 구현 방식 설명
- 출시일 문자열을 `Date`로 변환해 “출시 하루 전 18:00”을 계산, `UNCalendarNotificationTrigger`로 예약합니다.
- 전역 토글 ON/OFF, 권한 상태 확인, 과거 날짜 방어, pending badge 재정렬까지 구현되어 있습니다.
- 핵심 코드 스니펫
```swift
// GameFinder/Shared/Utils/Managers/NotificationManager.swift
private func scheduleLocalNotification(for game: Game, badgeNumber: Int? = nil) {
    guard let releaseDateString = game.released,
          let releaseDate = parseReleaseDate(releaseDateString) else { return }

    var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: releaseDate)
    dateComponents.hour = 18
    dateComponents.minute = 0
    guard let notificationDate = Calendar.current.date(from: dateComponents),
          let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: notificationDate),
          oneDayBefore >= Date() else { return }

    scheduleNotificationRequest(for: game, at: oneDayBefore, badgeValue: badgeNumber ?? 1)
}
```
- 기술적 의사결정 과정
- 알림 “등록”과 “발송 품질(뱃지/권한/토글 일관성)”을 분리해 운영 중 사용자 혼란을 줄이는 방향으로 설계했습니다.

- **[문의 - 이메일 자동 작성]**
- 구현 방식 설명
- `MFMailComposeViewController` 가능 시 수신자/제목/본문을 자동 채우고, 본문에 앱 버전·빌드·디바이스·iOS 버전을 첨부합니다.
- 메일 앱 미설정 환경에서는 문의 메일 주소를 클립보드로 복사해 fallback UX를 제공합니다.
- 핵심 코드 스니펫
```swift
// GameFinder/App/Features/Settings/SettingViewController.swift
private func sendEmail() {
    guard MFMailComposeViewController.canSendMail() else {
        UIPasteboard.general.string = "jddudios@gmail.com"
        return
    }

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let iOSVersion = UIDevice.current.systemVersion
    let deviceModel = getDeviceModelName()

    let messageBody = """
    ---
    App Version: \(appVersion) (\(buildNumber))
    Device: \(deviceModel)
    iOS Version: \(iOSVersion)
    """
}
```
- 기술적 의사결정 과정
- 사용자에게 로그 수집을 강요하지 않고, 문의 시점에 최소 진단 정보를 자동 포함해 CS-개발 간 왕복 비용을 줄였습니다.

### 🎓 학습 포인트 (신입 개발자 강조)
- `공식 문서 패턴 체득`
- WidgetKit(`AppIntentTimelineProvider`, timeline policy), UserNotifications(`UNCalendarNotificationTrigger`), MessageUI(`MFMailComposeViewControllerDelegate`) 사용 패턴을 실전 기능으로 연결했습니다.
- `동시성 혼합 운용`
- 화면 계층은 Rx, 위젯 데이터 업데이트는 async/await로 분리해 기존 구조를 유지하면서 신규 기능을 점진 도입했습니다.
- `운영 관점의 기능 설계`
- 기능 구현 자체보다 “권한 거부/과거 출시일/메일 미설정/위젯 데이터 없음” 같은 실패 경로를 먼저 처리하는 습관을 학습했습니다.
- `데이터 흐름 설계`
- DTO → Domain → Realm/WidgetModel 분리를 통해 API 변경 충격을 완화하는 구조를 경험했습니다.

### ⚠️ 개선 포인트 및 한계점
- `민감정보 관리`
- 한계: `Secrets.xcconfig`에 실제 RAWG 키가 커밋되어 있고(`GameFinder/App/Config/Secrets/Secrets.xcconfig`), `.gitignore` 정책과 실제 추적 상태가 일치하지 않습니다.
- 개선 방법: `Secrets.xcconfig.template`만 추적 + 실제 키는 로컬/CI 환경변수 주입, 이미 노출된 키는 즉시 재발급/폐기.

- `테스트 가능성`
- 한계: `NotificationManager`, `FavoriteManager` 등이 `RealmGameRepository` 구체 타입과 Singleton에 직접 의존합니다.
- 개선 방법: 생성자 주입(`init(repository: GameRepositoryProtocol = RealmGameRepository())`)으로 교체, Mock Repository로 Unit Test 작성.

- `중복 소스 관리`
- 한계: `SharedWidgetGame/AppGroupManager` 정의가 App/Widget/Shared에 중복되어 스키마 드리프트 위험이 큽니다.
- 개선 방법: 공유 모듈(`Shared` 타깃) 단일 정의로 통합 후 App/Widget 모두 링크.

- `위젯 업데이트 중복 호출`
- 한계: 앱 활성화 시점과 탭바 초기화에서 위젯 업데이트를 중복 호출해 API 호출량이 불필요하게 증가할 수 있습니다.
- 개선 방법: 디바운스(마지막 업데이트 시간 체크) + 단일 오케스트레이터로 호출 경로 통합.

- `Crashlytics 활용도`
- 한계: Crashlytics는 연동되어 있으나 커스텀 키/로그/사용자 컨텍스트 설정이 없습니다.
- 개선 방법: 주요 유스케이스에서 `setCustomValue`, non-fatal 리포팅, 사용자 플로우 태깅 도입.

- `로컬라이제이션 누락 가능성`
- 한계: 일부 UI 텍스트(예: 일부 셀 타이틀)가 하드코딩되어 다국어 일관성이 깨질 여지가 있습니다.
- 개선 방법: 문자열 스캔 규칙(코드리뷰 체크리스트 + SwiftLint custom rule)로 `.localized` 미사용 텍스트 차단.

### 🚀 추후 확장 가능성
- 위젯 개인화
- 랜덤 1개 추천 대신 “관심 장르 기반 추천 + 최근 조회 기반 우선순위”로 CTR 개선.
- 운영 자동화
- Remote Config로 알림 시간/위젯 갱신 주기/이벤트 샘플링 비율을 동적 제어.
- 품질 확장
- Test Target 추가 후 `ViewModel`, `Repository`, `Notification date calculator` 우선 단위 테스트 도입.
- 프로덕션 레벨
- 환경 분리를 `dev/staging/prod` 3단계로 확장하고 Firebase 프로젝트/GoogleService plist도 환경별로 분리.

### 📊 포트폴리오 강조 포인트 (스타트업 어필)
- 빠른 개발 속도와 품질의 균형
- 사용자 체감 기능(위젯/알림/문의)을 빠르게 붙이면서도 권한/실패 경로를 함께 처리했습니다.
- 확장 가능한 구조 설계
- ViewModel-Repository 분리, DTO-Domain 분리, 로깅 중앙화로 기능 추가 시 수정 범위를 줄였습니다.
- 실무 적용 가능성
- 장애 추적(Crashlytics), 행동 분석(Analytics), CS 대응(자동 메일 템플릿), 재방문 장치(위젯/알림)가 모두 포함되어 바로 운영 가능한 형태입니다.

---

## 분석에 사용한 주요 파일
- `GameFinder/App/Application/AppDelegate.swift`
- `GameFinder/App/Application/SceneDelegate.swift`
- `GameFinder/App/Features/Settings/SettingViewController.swift`
- `GameFinder/Services/WidgetDataService.swift`
- `GameFinderWidget/GameFinderWidget.swift`
- `GameFinder/Shared/Utils/Localization/L10n.swift`
- `GameFinder/Shared/Utils/Localization/Localizable.xcstrings`
- `GameFinder/Shared/Utils/Managers/NotificationManager.swift`
- `GameFinder/Shared/Utils/LogManager.swift`
- `GameFinder/Data/Network/Router/RawgRouter.swift`
- `GameFinder/Shared/Utils/Extensions/Bundle+Extension.swift`
- `GameFinder/App/Support/Info.plist`
- `GameFinder/App/Config/Base.xcconfig`
- `GameFinder/App/Config/Secrets/Secrets.xcconfig`
- `GameFinder.xcodeproj/project.pbxproj`
