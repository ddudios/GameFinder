<img width="100" height="132" alt="GameFinder" src="YOUR_LOGO_IMAGE_URL" />

# GameFinder

게임 탐색, 일정 관리, 다이어리 기록, 알림, 위젯 연동을 하나의 흐름으로 연결한 앱입니다.

|<img width="200" alt="SCREEN_1" src="YOUR_SCREENSHOT_URL_1" />|<img width="200" alt="SCREEN_2" src="YOUR_SCREENSHOT_URL_2" />|<img width="200" alt="SCREEN_3" src="YOUR_SCREENSHOT_URL_3" />|<img width="200" alt="SCREEN_4" src="YOUR_SCREENSHOT_URL_4" />|
|:-:|:-:|:-:|:-:|

|구분|내용|
|:--:|:--|
|**팀 인원**|iOS 개발 1명|
|**기획 및 개발 기간**|2025.09.27 - 2025.11.01|
|**최소 지원 버전**|iOS 16.0+|

## 핵심 기능

- RAWG/CheapShark API 기반 게임 탐색(인기/무료/출시예정/할인)
- 검색 및 플랫폼별 결과 탐색
- 게임 상세 정보, 스크린샷, 태그/평점/출시일 조회
- Realm 기반 다이어리/즐겨찾기/알림 로컬 관리
- 출시일 기반 캘린더 탐색 및 게임별 일정 확인
- 로컬 알림 + Firebase Messaging 원격 푸시
- WidgetKit + App Group 기반 위젯 데이터 동기화
- `gamefinder://game/{id}` 딥링크를 통한 상세 화면 이동
- 한국어/영어/일본어 다국어 지원

## 기술 스택

|분류|기술 스택|
|:--:|:--|
|**Language**|![Swift](https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white)|
|**UI Framework**|![UIKit](https://img.shields.io/badge/UIKit-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**Architecture**|![MVVM](https://img.shields.io/badge/MVVM-0A66C2?style=flat-square) ![Repository](https://img.shields.io/badge/Repository-111111?style=flat-square) ![RxSwift](https://img.shields.io/badge/RxSwift-B7178C?style=flat-square&logo=reactivex&logoColor=white)|
|**Database**|![RealmSwift](https://img.shields.io/badge/RealmSwift-39477F?style=flat-square&logo=realm&logoColor=white)|
|**Networking**|![Alamofire](https://img.shields.io/badge/Alamofire-D92C2C?style=flat-square&logo=alamofire&logoColor=white)|
|**Image/Media**|![Kingfisher](https://img.shields.io/badge/Kingfisher-1F8B4C?style=flat-square) ![AVFoundation](https://img.shields.io/badge/AVFoundation-007AFF?style=flat-square&logo=apple&logoColor=white) ![AVKit](https://img.shields.io/badge/AVKit-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**Layout**|![SnapKit](https://img.shields.io/badge/SnapKit-4F46E5?style=flat-square)|
|**Calendar**|![FSCalendar](https://img.shields.io/badge/FSCalendar-0F766E?style=flat-square)|
|**Push/Infra**|![Firebase_Messaging](https://img.shields.io/badge/Firebase_Messaging-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Firebase_Analytics](https://img.shields.io/badge/Firebase_Analytics-FFCA28?style=flat-square&logo=firebase&logoColor=black) ![Crashlytics](https://img.shields.io/badge/Crashlytics-FFCA28?style=flat-square&logo=firebase&logoColor=black)|
|**Widget**|![WidgetKit](https://img.shields.io/badge/WidgetKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![App_Groups](https://img.shields.io/badge/App%20Groups-111111?style=flat-square&logo=apple&logoColor=white)|
|**Localization**|![ko](https://img.shields.io/badge/ko-111111?style=flat-square) ![en](https://img.shields.io/badge/en-111111?style=flat-square) ![ja](https://img.shields.io/badge/ja-111111?style=flat-square)|

## 전체 구조

### 아키텍처

<img width="719" height="435" alt="ARCHITECTURE_DIAGRAM" src="YOUR_ARCHITECTURE_IMAGE_URL" />

- 화면 로직은 `ViewController + ViewModel(MVVM)`로 분리
- 비동기 이벤트/상태 바인딩은 `RxSwift/RxCocoa`로 처리
- 네트워크 통신은 `Router + NetworkManager(Alamofire)`로 캡슐화
- 로컬 영속성은 `Realm Repository` 계층에서 관리
- 공통 UI/유틸/테마는 `Shared` 모듈로 분리

### 주요 데이터 흐름

- 홈/탐색: `RAWG/CheapShark API 조회 -> Realm 캐시 저장 -> 화면 반영`
- 다이어리/즐겨찾기/알림: `사용자 액션 -> Realm 저장/관찰 -> UI 자동 갱신`
- 로컬 알림: `알림 등록 -> 출시 하루 전 스케줄링 -> 배지 재계산`
- 푸시: `Firebase Messaging 토큰 등록 -> 원격 푸시 수신 -> 상세 화면 이동`
- 위젯: `앱 데이터 수집 -> App Group 저장 -> Widget Timeline 갱신`
- 딥링크: `gamefinder://game/{id} -> SceneDelegate/AppDelegate 라우팅 -> 상세 화면 Push`

## 주요 기능

### 홈/탐색 (Finder)

|<img width="200" alt="FINDER_1" src="YOUR_FINDER_SCREENSHOT_URL_1" />|<img width="200" alt="FINDER_2" src="YOUR_FINDER_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 인기 게임, 무료 게임, 출시 예정 게임, 할인 딜 섹션 제공
- 섹션별 네트워크 실패 시 캐시 기반 fallback 처리
- 게임 카드 탭으로 상세 화면 이동
- 스켈레톤 UI/이미지 로딩으로 초기 체감 성능 보완

### 검색 (Search)

|<img width="200" alt="SEARCH_1" src="YOUR_SEARCH_SCREENSHOT_URL_1" />|<img width="200" alt="SEARCH_2" src="YOUR_SEARCH_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 키워드 기반 게임 검색 지원
- 플랫폼 필터(PC/콘솔/모바일) 기반 결과 탐색
- 검색 결과 카드에서 상세 화면으로 연계

### 게임 상세 (Detail)

|<img width="200" alt="DETAIL_1" src="YOUR_DETAIL_SCREENSHOT_URL_1" />|<img width="200" alt="DETAIL_2" src="YOUR_DETAIL_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 게임 기본 정보(제목/출시일/평점/장르/태그) 조회
- 스크린샷/플랫폼/개발사/퍼블리셔/공식 사이트 정보 제공
- 즐겨찾기/다이어리/알림 액션 버튼 제공

### 다이어리 (Diary)

|<img width="200" alt="DIARY_1" src="YOUR_DIARY_SCREENSHOT_URL_1" />|<img width="200" alt="DIARY_2" src="YOUR_DIARY_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 게임별 플레이 다이어리 작성/수정/삭제 지원
- 텍스트와 이미지/영상 첨부 기록 관리
- AVPlayer 기반 영상 미리보기/재생 지원
- Realm observe 기반 변경사항 즉시 반영

### 라이브러리 (Library)

|<img width="200" alt="LIBRARY_1" src="YOUR_LIBRARY_SCREENSHOT_URL_1" />|<img width="200" alt="LIBRARY_2" src="YOUR_LIBRARY_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 다이어리/즐겨찾기/알림을 카테고리별로 통합 조회
- PageView 기반 카테고리 전환 UI 구성
- 저장된 게임 데이터 재사용으로 탐색 흐름 단축

### 캘린더 (Calendar)

|<img width="200" alt="CALENDAR_1" src="YOUR_CALENDAR_SCREENSHOT_URL_1" />|<img width="200" alt="CALENDAR_2" src="YOUR_CALENDAR_SCREENSHOT_URL_2" />|
|:-:|:-:|

- FSCalendar 기반 월간 출시일 탐색
- 날짜 선택 시 해당 일자의 출시 게임 목록 표시
- 빈 상태 UI와 diffable data source 기반 목록 업데이트

### 알림/푸시

|<img width="200" alt="NOTI_1" src="YOUR_NOTIFICATION_SCREENSHOT_URL_1" />|<img width="200" alt="NOTI_2" src="YOUR_NOTIFICATION_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 출시 하루 전 로컬 알림 스케줄링
- 게임별 알림 on/off 및 전역 알림 토글 지원
- Firebase Messaging 기반 원격 푸시 수신
- 포그라운드/백그라운드 진입 시 배지 동기화 처리

### 위젯/딥링크

|<img width="200" alt="WIDGET_1" src="YOUR_WIDGET_SCREENSHOT_URL_1" />|<img width="200" alt="WIDGET_2" src="YOUR_WIDGET_SCREENSHOT_URL_2" />|
|:-:|:-:|

- WidgetKit Extension으로 출시 예정 게임 정보 노출
- App Group(UserDefaults/Shared Container)로 앱-위젯 데이터 공유
- 위젯 탭 시 `gamefinder://game/{id}` 딥링크로 상세 진입

### 설정

|<img width="200" alt="SETTINGS_1" src="YOUR_SETTINGS_SCREENSHOT_URL_1" />|<img width="200" alt="SETTINGS_2" src="YOUR_SETTINGS_SCREENSHOT_URL_2" />|
|:-:|:-:|

- 알림 권한 확인 및 설정 화면 연동
- 앱 내 언어 전환(ko/en/ja) 지원
- 문의 메일 작성 및 디바이스/버전 정보 자동 첨부
